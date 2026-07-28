resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-web"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "web" {
  name                 = "web-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.0.0/24"]
}

output "vnet_id" {
  value = azurerm_virtual_network.spoke.id
}

output "spoke_subnet_id" {
  value = azurerm_subnet.web.id
}