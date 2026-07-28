resource "azurerm_resource_group" "rg" {
  name     = "rg-hubspoke-lab"
  location = var.location
}

module "hub" {
  source              = "./modules/hub"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

module "spoke" {
  source              = "./modules/spoke"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

module "firewall" {
  source              = "./modules/firewall"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  firewall_subnet_id  = module.hub.firewall_subnet_id
}

module "network_shared" {
  source                     = "./modules/network_shared"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  spoke_subnet_id            = module.spoke.spoke_subnet_id
  firewall_private_ip        = module.firewall.private_ip
}

module "peering" {
  source              = "./modules/peering"
  resource_group_name = azurerm_resource_group.rg.name
  hub_vnet_id         = module.hub.vnet_id
  spoke_vnet_id       = module.spoke.vnet_id
}