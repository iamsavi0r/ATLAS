# ==============================================================================
# ATLAS Project - Level 2 (Network Configuration)
# Domain: olympus.local | Author: savi0r
# ==============================================================================

# 1. Виртуальная Сеть (VNet)
resource "azurerm_virtual_network" "atlas_vnet" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = "${var.project_name}-rg" # Будет создаваться скриптом управления
}

# 2. Подсеть с указанием DNS на сам Контроллер Домена (10.0.0.4)
# Это критично, иначе Windows 11 не сможет найти и войти в домен olympus.local
resource "azurerm_subnet" "atlas_subnet" {
  name                 = "default"
  resource_group_name  = "${var.project_name}-rg"
  virtual_network_name = azurerm_virtual_network.atlas_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

# 3. Публичный IP для Домен Контроллера (DC)
resource "azurerm_public_ip" "dc_pip" {
  name                = "${var.project_name}-dc-pip"
  location            = var.location
  resource_group_name = "${var.project_name}-rg"
  allocation_method   = "Dynamic"
}

# 4. Публичный IP для Клиентской тачки (PC)
resource "azurerm_public_ip" "client_pip" {
  name                = "${var.project_name}-client-pip"
  location            = var.location
  resource_group_name = "${var.project_name}-rg"
  allocation_method   = "Dynamic"
}

# 5. Файрвол (NSG) — Открываем порты для атак и RDP
resource "azurerm_network_security_group" "atlas_nsg" {
  name                = "${var.project_name}-nsg"
  location            = var.location
  resource_group_name = "${var.project_name}-rg"

  # RDP Доступ для обеих машин
  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.allowed_ip
    destination_address_prefix = "*"
  }

  # Порты для Impacket / Брутфорса / Разведки
  # (88=Kerberos, 389=LDAP, 445=SMB, 135=RPC, 5985=WinRM)
  security_rule {
    name                       = "Allow-AD-Pentest-Ports"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "88,135,389,445,5985,3268"
    source_address_prefix      = var.allowed_ip
    destination_address_prefix = "*"
  }
}

# 6. Сетевой интерфейс Контроллера Домена (Статический IP: 10.0.0.4)
resource "azurerm_network_interface" "dc_nic" {
  name                = "${var.project_name}-dc-nic"
  location            = var.location
  resource_group_name = "${var.project_name}-rg"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.atlas_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.4"
    public_ip_address_id          = azurerm_public_ip.dc_pip.id
  }
}

# 7. Сетевой интерфейс Клиентской машины (Статический IP: 10.0.0.5)
resource "azurerm_network_interface" "client_nic" {
  name                = "${var.project_name}-client-nic"
  location            = var.location
  resource_group_name = "${var.project_name}-rg"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.atlas_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.5"
    public_ip_address_id          = azurerm_public_ip.client_pip.id
  }
}

# Привязываем правила файрвола к обеим сетевым картам
resource "azurerm_network_interface_security_group_association" "dc_nic_nsg" {
  network_interface_id      = azurerm_network_interface.dc_nic.id
  network_security_group_id = azurerm_network_security_group.atlas_nsg.id
}

resource "azurerm_network_interface_security_group_association" "client_nic_nsg" {
  network_interface_id      = azurerm_network_interface.client_nic.id
  network_security_group_id = azurerm_network_security_group.atlas_nsg.id
}
