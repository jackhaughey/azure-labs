# ------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# ------------------------------------------------------------
# Virtual Network + Subnet
# ------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-vmss"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "vmss_subnet" {
  name                 = "vmss-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.1.0/24"]
}

# ------------------------------------------------------------
# Public IP for Load Balancer
# ------------------------------------------------------------
resource "azurerm_public_ip" "pip_lb" {
  name                = "pip-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ------------------------------------------------------------
# Load Balancer
# ------------------------------------------------------------
resource "azurerm_lb" "lb" {
  name                = "lb-web"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "feip"
    public_ip_address_id = azurerm_public_ip.pip_lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "bepool" {
  name            = "bepool"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "probe" {
  name            = "tcp-probe"
  loadbalancer_id = azurerm_lb.lb.id
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_lb_rule" "rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "feip"
  backend_address_pool_ids       = [azurerm_lb.lb]
  probe_id                       = azurerm_lb_probe.probe.id
}

# ------------------------------------------------------------
# VM Scale Set (Ubuntu 22.04)
# ------------------------------------------------------------
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss-web"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_B2s"
  instances           = 2
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  upgrade_mode        = "Automatic"

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "nicconfig"
    primary = true

    ip_configuration {
      name                                   = "ipconfig"
      subnet_id                              = azurerm_subnet.vmss_subnet.id
      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.bepool.id
      ]
    }
  }
}

# ------------------------------------------------------------
# Autoscale Settings
# ------------------------------------------------------------
resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "autoscale-vmss"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "cpu-autoscale"

    capacity {
      minimum = "1"
      maximum = "5"
      default = "2"
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_namespace   = "microsoft.compute/virtualmachines"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_namespace   = "microsoft.compute/virtualmachines"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}