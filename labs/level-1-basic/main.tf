# ==============================================================================
# ATLAS Project - Automated IaC Deployment (Azure Blueprint)
# Domain: olympus.local | Author: savi0r
# ==============================================================================

# 1. Настройки провайдера Azure
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 2. Создаем Группу Ресурсов (rg-atlas-prod)
resource "azurerm_resource_group" "atlas_rg" {
  name     = "rg-atlas-prod"
  location = "South Africa North" # Твой регион из конфига
}

# 3. Создаем Виртуальную Сеть (ATLAS-DC01-vnet)
resource "azurerm_virtual_network" "atlas_vnet" {
  name                = "ATLAS-DC01-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name
}

# 4. Создаем Подсеть (default: 10.0.0.0/24)
resource "azurerm_subnet" "atlas_subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.atlas_rg.name
  virtual_network_name = azurerm_virtual_network.atlas_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

# 5. Выделяем Общедоступный IP-адрес (ATLAS-DC01-ip)
resource "azurerm_public_ip" "atlas_ip" {
  name                = "ATLAS-DC01-ip"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name
  allocation_method   = "Dynamic"
}

# 6. Настраиваем Файрвол (Группу безопасности) — открываем порты для управления и атак
resource "azurerm_network_security_group" "atlas_nsg" {
  name                = "ATLAS-DC01-nsg"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name

  # Правило 1: Доступ по RDP, чтобы админить или смотреть логи изнутри
  security_rule {
    name                       = "Allow-RDP-All"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Правило 2: Открываем порты для Impacket (88=Kerberos, 389=LDAP, 445=SMB, 3268=Global Catalog)
  security_rule {
    name                       = "Allow-AD-Pentest-Ports"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "88,389,445,3268"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 7. Создаем Сетевой интерфейс (Сетевую карту) тачки
resource "azurerm_network_interface" "atlas_nic" {
  name                = "ATLAS-DC01-nic"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.atlas_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.4" # Фиксированный IP для Контроллера Домена
    public_ip_address_id          = azurerm_public_ip.atlas_ip.id
  }
}

# Связываем сетевую карту с правилами файрвола
resource "azurerm_network_interface_security_group_association" "atlas_nic_nsg" {
  network_interface_id      = azurerm_network_interface.atlas_nic.id
  network_security_group_id = azurerm_network_security_group.atlas_nsg.id
}

# 8. СБОРКА СЕРВЕРА (ATLAS-DC01)
resource "azurerm_windows_virtual_machine" "atlas_dc" {
  name                = "ATLAS-DC01"
  resource_group_name = azurerm_resource_group.atlas_rg.name
  location            = azurerm_resource_group.atlas_rg.location
  size                = "Standard_B2as_v2" # Твой размер 2 vCPU / 8 GiB
  admin_username      = "atlas_admin"
  admin_password      = "HoldUpTheSky2026!" # Пароль должен быть сложным

  network_interface_ids = [
    azurerm_network_interface.atlas_nic.id,
  ]

  # Настройки жесткого диска
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Выбираем образ
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-core-g2"
    version   = "latest"
  }

  # Код кодируется в Base64, облако Azure само расшифрует и запустит его при старте.
  user_data = base64encode(<<-EOF
    <powershell>
    Set-MpPreference -DisableRealtimeMonitoring $true
    $ScriptPath = "C:\atlas_core_bootstrap.ps1"

    $BootstrapperCode = @"
    # Проверяем домен
    `$DomainCheck = Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty PartOfDomain
    if (`$DomainCheck -ne "olympus.local") {
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
        `$Action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-ExecutionPolicy Bypass -File C:\atlas_core_bootstrap.ps1"
        `$Trigger = New-ScheduledTaskTrigger -AtStartup
        `$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        `$Task = New-ScheduledTask -Action `$Action -Trigger `$Trigger -Principal `$Principal
        Register-ScheduledTask -TaskName "ATLAS_PostReboot_Config" -InputObject `$Task -Force

        `$ADPassword = ConvertTo-SecureString "HoldUpTheSky2026!" -AsPlainText -Force
        Install-ADDSForest -DomainName "olympus.local" -SafeModeAdministratorPassword `$ADPassword -Force:`$true
    } else {
        Start-Sleep -Seconds 45
        Import-Module ActiveDirectory

        # Создаем Прометея (AS-REP Roasting)
        `$PrometheusPass = ConvertTo-SecureString "StealTheFire2026!" -AsPlainText -Force
        New-ADUser -Name "Prometheus Titan" -SamAccountName "prometheus" -UserPrincipalName "prometheus@olympus.local" -AccountPassword `$PrometheusPass -Enabled `$true
        Set-ADUser -Identity "prometheus" -Replace @{useraccountcontrol=4194304}

        # Создаем Гермеса (Kerberoasting)
        `$HermesPass = ConvertTo-SecureString "MessengerOfGods123!" -AsPlainText -Force
        New-ADUser -Name "Hermes Service" -SamAccountName "hermes.svc" -UserPrincipalName "hermes.svc@olympus.local" -AccountPassword `$HermesPass -Enabled `$true
        setspn -A MSSQLSvc/kronos.olympus.local:1433 hermes.svc

        Unregister-ScheduledTask -TaskName "ATLAS_PostReboot_Config" -Confirm:`$false
        Remove-Item -Path "C:\atlas_core_bootstrap.ps1" -Force
    }
    "@

    Set-Content -Path $ScriptPath -Value $BootstrapperCode
    powershell -ExecutionPolicy Bypass -File $ScriptPath
    </powershell>
  EOF
  )
}

# Выводим публичный IP-адрес на экран после сборки, чтобы сразу подключаться
output "public_ip_address" {
  value       = azurerm_public_ip.atlas_ip.ip_address
  description = "Public IP address of the ATLAS Domain Controller"
}
