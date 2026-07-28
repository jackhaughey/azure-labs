resource "azurerm_public_ip" "pip" {
  name                = "pip-azfw-hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "fw" {
  name                = "azfw-hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

output "private_ip" {
  value = azurerm_firewall.fw.ip_configuration[0].private_ip_address
}