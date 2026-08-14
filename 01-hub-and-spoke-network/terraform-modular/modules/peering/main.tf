resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-spoke"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = basename(var.hub_vnet_id)
  remote_virtual_network_id = var.spoke_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = basename(var.spoke_vnet_id)
  remote_virtual_network_id = var.hub_vnet_id

  allow_virtual_network_access = true
}
