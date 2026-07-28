# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-hubspoke-lab"
  location = var.location
}

# Hub vnet
resource "azurerm_virtual_network" "vnet_hub" {
  name                = "vnet-hub"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "hub_firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "hub_shared" {
  name                 = "shared-services-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.0.2.0/24"]
}


# Spoke VNet
resource "azurerm_virtual_network" "vnet_spoke" {
  name                = "vnet-spoke-web"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "spoke_web" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_spoke.name
  address_prefixes     = ["10.1.0.0/24"]
}

# Firewall and pub IP
resource "azurerm_public_ip" "pip_firewall" {
  name                = "pip-azfw-hub"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "firewall" {
  name                = "azfw-hub"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.hub_firewall.id
    public_ip_address_id = azurerm_public_ip.pip_firewall.id
  }
}

# Route Table
resource "azurerm_route_table" "rt_spoke" {
  name                = "rt-web-spoke"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}
# RT association
resource "azurerm_subnet_route_table_association" "rt_assoc" {
  subnet_id      = azurerm_subnet.spoke_web.id
  route_table_id = azurerm_route_table.rt_spoke.id
}

# Network Security Group
resource "azurerm_network_security_group" "nsg_spoke" {
  name                = "nsg-web-subnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
# NSG association
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.spoke_web.id
  network_security_group_id = azurerm_network_security_group.nsg_spoke.id
}

# VNet Peering - Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-spoke"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_hub.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_spoke.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-to-hub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_spoke.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_hub.id

  allow_virtual_network_access = true
}

