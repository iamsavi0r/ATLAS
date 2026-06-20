# ==============================================================================
# ATLAS Project - Automated IaC Deployment (Azure Blueprint)
# Level 2: Smart Recon & Password Spraying
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
  features {
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = true
    }
  }
}

# 1. Группа ресурсов
resource "azurerm_resource_group" "atlas_rg" {
  name     = "rg-atlas-prod-lab2"
  location = "South Africa North"
}

# 2. Сетевая инфраструктура
resource "azurerm_virtual_network" "atlas_vnet" {
  name                = "ATLAS-Lvl2-vnet"
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

# 3. Публичные IP-адреса
resource "azurerm_public_ip" "dc_ip" {
  name                = "ATLAS-DC01-ip"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "client_ip" {
  name                = "ATLAS-PC01-ip"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

# 4. Группа безопасности (Открываем порты для векторов атак)
resource "azurerm_network_security_group" "atlas_nsg" {
  name                = "ATLAS-Lvl2-nsg"
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

# 5. Сетевые интерфейсы
# интерфейс DC01 (10.0.0.4)
resource "azurerm_network_interface" "dc_nic" {
  name                = "ATLAS-DC01-nic"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.atlas_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.4"
    public_ip_address_id          = azurerm_public_ip.dc_ip.id
  }
}

# интерфейс PC01 (10.0.0.5)
resource "azurerm_network_interface" "client_nic" {
  name                = "ATLAS-PC01-nic"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.atlas_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.5"
    public_ip_address_id          = azurerm_public_ip.client_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "dc_nic_nsg" {
  network_interface_id      = azurerm_network_interface.dc_nic.id
  network_security_group_id = azurerm_network_security_group.atlas_nsg.id
}

resource "azurerm_network_interface_security_group_association" "client_nic_nsg" {
  network_interface_id      = azurerm_network_interface.client_nic.id
  network_security_group_id = azurerm_network_security_group.atlas_nsg.id
}

# 6. Виртуалка 1: Контроллер Домена (Windows Server 2022 Core)
resource "azurerm_windows_virtual_machine" "atlas_dc" {
  name                = "ATLAS-DC01"
  resource_group_name = azurerm_resource_group.atlas_rg.name
  location            = azurerm_resource_group.atlas_rg.location
  size                = "Standard_B2as_v2" # Зафиксировали рабочий размер
  admin_username      = "atlas_admin"
  admin_password      = "HoldUpTheSky2026!"

  # ЖЕСТКИЙ ФИКС ДЛЯ HOTPATCH ОБРАЗА
  patch_mode          = "AutomaticByPlatform"
  hotpatching_enabled = true

  secure_boot_enabled = true
  vtpm_enabled        = true

  network_interface_ids = [
    azurerm_network_interface.dc_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition-core"
    version   = "latest"
  }
}

# 7. Виртуалка 2: Рабочая Станция (Windows 11 Pro 25H2 - x64 Gen2)
resource "azurerm_windows_virtual_machine" "atlas_client" {
  name                = "ATLAS-PC01"
  resource_group_name = azurerm_resource_group.atlas_rg.name
  location            = azurerm_resource_group.atlas_rg.location
  size                = "Standard_B2as_v2" # Железно рабочий размер, 8GB RAM
  admin_username      = "local_user"
  admin_password      = "HoldUpTheSky2026!"

  # Обязательно для Windows 11 Gen2
  secure_boot_enabled = true
  vtpm_enabled        = true

  network_interface_ids = [
    azurerm_network_interface.client_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-25h2-pro" # Твоя Windows 11 Pro
    version   = "latest"
  }
}

# 8. Развертывание AD и генерация 100+ пользователей через запись в C:\setup.ps1
resource "azurerm_virtual_machine_extension" "ad_bootstrap" {
  name                 = "ad-bootstrap-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.atlas_dc.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  protected_settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -ExecutionPolicy Bypass -Command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(<<-EOF
          Set-MpPreference -DisableRealtimeMonitoring $true
          Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

          $Path = 'C:\setup.ps1'
          New-Item -ItemType File -Path $Path -Force
          Add-Content -Path $Path -Value '$ADInstalled = (Get-WindowsFeature -Name AD-Domain-Services).Installed'
          Add-Content -Path $Path -Value 'if ($ADInstalled -ne $true) {'
          Add-Content -Path $Path -Value '    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools'
          Add-Content -Path $Path -Value '    $pass = ConvertTo-SecureString "HoldUpTheSky2026!" -AsPlainText -Force'
          Add-Content -Path $Path -Value '    Install-ADDSForest -DomainName "olympus.local" -SafeModeAdministratorPassword $pass -Force:$true'
          Add-Content -Path $Path -Value '} else {'
          Add-Content -Path $Path -Value '    Start-Sleep -Seconds 45'
          Add-Content -Path $Path -Value '    Import-Module ActiveDirectory'
          Add-Content -Path $Path -Value '    for ($i = 1; $i -le 100; $i++) {'
          Add-Content -Path $Path -Value '        $username = "user$i"'
          Add-Content -Path $Path -Value '        $randomPassStr = [Guid]::NewGuid().ToString().Substring(0,12) + "A1!"'
          Add-Content -Path $Path -Value '        if ($i -eq 25 -or $i -eq 77) { $randomPassStr = "Autumn2026!" }'
          Add-Content -Path $Path -Value '        $securePass = ConvertTo-SecureString $randomPassStr -AsPlainText -Force'
          Add-Content -Path $Path -Value '        New-ADUser -Name "Lab User $i" -SamAccountName $username -UserPrincipalName "$username@olympus.local" -AccountPassword $securePass -Enabled:$true'
          Add-Content -Path $Path -Value '    }'
          Add-Content -Path $Path -Value '    Unregister-ScheduledTask -TaskName "ATLAS_AD_Setup" -Confirm:$false -ErrorAction SilentlyContinue'
          Add-Content -Path $Path -Value '    Remove-Item -Path "C:\setup.ps1" -Force'
          Add-Content -Path $Path -Value '}'

          # Привязываем таску по SID S-1-5-18 (SYSTEM), обходя баги локализации строк
          $Action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-ExecutionPolicy Bypass -File C:\setup.ps1'
          $Trigger = New-ScheduledTaskTrigger -AtStartup
          $Principal = New-ScheduledTaskPrincipal -GroupId 'S-1-5-18' -RunLevel Highest
          $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal
          Register-ScheduledTask -TaskName 'ATLAS_AD_Setup' -InputObject $Task -Force
          Start-ScheduledTask -TaskName 'ATLAS_AD_Setup'
        EOF
        )}')) | powershell.exe -ExecutionPolicy Bypass -"
    }
SETTINGS

  depends_on = [azurerm_windows_virtual_machine.atlas_dc]
}

# 9. Вывод IP-адресов
output "DC_Public_IP" {
  value       = azurerm_public_ip.dc_ip.ip_address
}

output "Client_PC_Public_IP" {
  value       = azurerm_public_ip.client_ip.ip_address
}
