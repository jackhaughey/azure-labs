resource "azurerm_route_table" "rt" {
  name                = "rt-web-spoke"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "rt_assoc" {
  subnet_id      = var.spoke_subnet_id
  route_table_id = azurerm_route_table.rt.id
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-web-subnet"
  location            = var.location
  resource_group_name = var.resource_group_name

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

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = var.spoke_subnet_id
  network_security_group_id = azurerm_network_security_group.nsg.id
}