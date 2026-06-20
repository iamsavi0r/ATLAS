# ==============================================================================
# ATLAS Project - Level 3: GPO & Share Misconfigurations
# Infrastructure-as-Code Configuration (Azure)
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

# 1. Resource Group
resource "azurerm_resource_group" "atlas_rg" {
  name     = "ATLAS-Olympus-GPO-Lab"
  location = "East US"
}

# 2. Virtual Network & Subnet
resource "azurerm_virtual_network" "atlas_vnet" {
  name                = "atlas-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name
}

resource "azurerm_subnet" "atlas_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.atlas_rg.name
  virtual_network_name = azurerm_virtual_network.atlas_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

# 3. Public IPs for Remote Management
resource "azurerm_public_ip" "dc_pip" {
  name                = "dc-public-ip"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "client_pip" {
  name                = "client-public-ip"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 4. Network Security Group (Firewall)
resource "azurerm_network_security_group" "atlas_nsg" {
  name                = "atlas-nsg"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name

  security_rule {
    name                       = "Allow-RDP-Win11"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-WinRM-DC"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 5. Network Interfaces (NIC) with Static Internal IPs
resource "azurerm_network_interface" "dc_nic" {
  name                = "dc-nic"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.atlas_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.4"
    public_ip_address_id          = azurerm_public_ip.dc_pip.id
  }
}

resource "azurerm_network_interface" "client_nic" {
  name                = "client-nic"
  location            = azurerm_resource_group.atlas_rg.location
  resource_group_name = azurerm_resource_group.atlas_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.atlas_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.5"
    public_ip_address_id          = azurerm_public_ip.client_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "dc_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.dc_nic.id
  network_security_group_id = azurerm_network_security_group.atlas_nsg.id
}

resource "azurerm_network_interface_security_group_association" "client_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.client_nic.id
  network_security_group_id = azurerm_network_security_group.atlas_nsg.id
}

# 6. Domain Controller (Windows Server Core - Ultra Lightweight)
resource "azurerm_windows_virtual_machine" "atlas_dc" {
  name                = "ATLAS-DC01"
  resource_group_name = azurerm_resource_group.atlas_rg.name
  location            = azurerm_resource_group.atlas_rg.location
  size                = "Standard_B2as_v2"
  admin_username      = "atlas_admin"
  admin_password      = "HoldUpTheSky2026!"
  network_interface_ids = [
    azurerm_network_interface.dc_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # Non-SSD to keep it cheap/free
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition-core"
    version   = "latest"
  }
}

# 7. Student Auditing Workstation (Windows 11)
resource "azurerm_windows_virtual_machine" "atlas_client" {
  name                = "ATLAS-PC01"
  resource_group_name = azurerm_resource_group.atlas_rg.name
  location            = azurerm_resource_group.atlas_rg.location
  size                = "Standard_B2as_v2"
  admin_username      = "atlas_local"
  admin_password      = "HoldUpTheSky2026!"
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
    sku       = "win11-25h2-pro"
    version   = "latest"
  }
}

# 8. Outputs for the Orchestrator Script
output "dc_public_ip" {
  value       = azurerm_public_ip.dc_pip.ip_address
  description = "Public IP for WinRM/Management of Domain Controller"
}

output "client_public_ip" {
  value       = azurerm_public_ip.client_pip.ip_address
  description = "Public IP for RDP Access to Student Workstation"
}
