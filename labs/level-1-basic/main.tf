# ==============================================================================
# ATLAS Project - Automated IaC Deployment (Azure Blueprint)
# Domain: olympus.local | Author: savi0r
# ==============================================================================

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

# 1. Группа ресурсов
resource "azurerm_resource_group" "atlas_rg" {
  name     = "rg-atlas-prod-lab1"
  location = "South Africa North"
}

# 2. Сетевая инфраструктура
resource "azurerm_virtual_network" "atlas_vnet" {
  name                = "ATLAS-DC01-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name
}

resource "azurerm_subnet" "atlas_subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.atlas_rg.name
  virtual_network_name = azurerm_virtual_network.atlas_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

# 3. Публичный IP-адрес
resource "azurerm_public_ip" "atlas_ip" {
  name                = "ATLAS-DC01-ip"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

# 4. Группа безопасности (Открываем порты для векторов атак)
resource "azurerm_network_security_group" "atlas_nsg" {
  name                = "ATLAS-DC01-nsg"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name

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

  security_rule {
    name                       = "Allow-Kerberos"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-LDAP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SMB"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 5. Привязка сети
resource "azurerm_network_interface" "atlas_nic" {
  name                = "ATLAS-DC01-nic"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.atlas_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.4"
    public_ip_address_id          = azurerm_public_ip.atlas_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "atlas_nic_nsg" {
  network_interface_id      = azurerm_network_interface.atlas_nic.id
  network_security_group_id = azurerm_network_security_group.atlas_nsg.id
}

# 6. Базовая Виртуальная Машина Windows Server 2022 Core
resource "azurerm_windows_virtual_machine" "atlas_dc" {
  name                = "ATLAS-DC01"
  resource_group_name = azurerm_resource_group.atlas_rg.name
  location            = azurerm_resource_group.atlas_rg.location
  size                = "Standard_B2as_v2"
  admin_username      = "atlas_admin"
  admin_password      = "HoldUpTheSky2026!"

  network_interface_ids = [
    azurerm_network_interface.atlas_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition-core" # Используем стабильную версию 2022
    version   = "latest"
  }
}

# 7. Надежное развертывание AD через внутреннюю Base64 сборку
resource "azurerm_virtual_machine_extension" "ad_bootstrap" {
  name                 = "ad-bootstrap-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.atlas_dc.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  # Мы берем чистый PS-скрипт, Терраформ кодирует его в Base64, а Azure просто создает файл C:\setup.ps1 внутри VM
  protected_settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -ExecutionPolicy Bypass -Command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(<<-EOF
          Set-MpPreference -DisableRealtimeMonitoring $true
          Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

          $ScriptPath = 'C:\\atlas_setup.ps1'
          $Code = @'
          $ADInstalled = (Get-WindowsFeature -Name AD-Domain-Services).Installed
          if ($ADInstalled -ne $true) {
              Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
              $pass = ConvertTo-SecureString "HoldUpTheSky2026!" -AsPlainText -Force
              Install-ADDSForest -DomainName "olympus.local" -SafeModeAdministratorPassword $pass -Force:$true
          } else {
              Start-Sleep -Seconds 45
              Import-Module ActiveDirectory
              $p_pass = ConvertTo-SecureString "StealTheFire2026!" -AsPlainText -Force
              New-ADUser -Name "Prometheus Titan" -SamAccountName "prometheus" -UserPrincipalName "prometheus@olympus.local" -AccountPassword $p_pass -Enabled:$true
              Set-ADUser -Identity "prometheus" -Replace @{useraccountcontrol=4194304}
              
              $h_pass = ConvertTo-SecureString "MessengerOfGods123!" -AsPlainText -Force
              New-ADUser -Name "Hermes Service" -SamAccountName "hermes.svc" -UserPrincipalName "hermes.svc@olympus.local" -AccountPassword $h_pass -Enabled:$true
              setspn -A MSSQLSvc/kronos.olympus.local:1433 hermes.svc
              
              Unregister-ScheduledTask -TaskName "ATLAS_AD_Setup" -Confirm:$false -ErrorAction SilentlyContinue
              Remove-Item -Path "C:\\atlas_setup.ps1" -Force
          }
'@
          Set-Content -Path $ScriptPath -Value $Code

          $Action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-ExecutionPolicy Bypass -File C:\\atlas_setup.ps1'
          $Trigger = New-ScheduledTaskTrigger -AtStartup
          $Principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\\SYSTEM' -LogonType ServiceAccount -RunLevel Highest
          $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal
          Register-ScheduledTask -TaskName 'ATLAS_AD_Setup' -InputObject $Task -Force
          Start-ScheduledTask -TaskName 'ATLAS_AD_Setup'
        EOF
        )}')) | Set-Content -Path C:\\setup.ps1; powershell.exe -ExecutionPolicy Bypass -File C:\\setup.ps1\""
    }
SETTINGS

  depends_on = [azurerm_windows_virtual_machine.atlas_dc]
}

# 8. Вывод IP для проведения атак
output "public_ip_address" {
  value       = azurerm_public_ip.atlas_ip.ip_address
}
