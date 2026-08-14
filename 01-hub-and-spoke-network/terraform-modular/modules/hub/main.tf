resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "shared" {
  name                 = "shared-services-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/24"]
}

output "vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "firewall_subnet_id" {
  value = azurerm_subnet.firewall.id
}