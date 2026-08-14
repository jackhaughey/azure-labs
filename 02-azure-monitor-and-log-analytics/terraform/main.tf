###############################################################################
# SECTION 1: Log Analytics Workspace
###############################################################################

resource "azurerm_log_analytics_workspace" "law" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days

}


###############################################################################
# SECTION 2: Monitoring
###############################################################################

resource "azurerm_log_analytics_solution" "solutions" {
  for_each = toset(var.solutions)

  solution_name         = each.key
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.law.id
  workspace_name        = azurerm_log_analytics_workspace.law.name

  plan {
    publisher = "Microsoft"
    product   = each.key
  }
}


###############################################################################
# SECTION 3: Data Collection Rule (VM Insights)
###############################################################################

resource "azurerm_monitor_data_collection_rule" "vm_dcr" {
  count               = var.deploy_vm_dcr ? 1 : 0
  name                = "${var.workspace_name}-vm-dcr"
  location            = var.location
  resource_group_name = var.resource_group_name

  data_flow {
    streams      = ["Microsoft-Perf"]
    destinations = ["law-destination"]
  }

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
      name                  = "law-destination"
    }
  }

  data_sources {
    performance_counter {
      name                          = "vm-default-counters"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60

      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\LogicalDisk(_Total)\\% Free Space"
      ]
    }
  }
}


###############################################################################
# SECTION 4: Outputs
###############################################################################

output "workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}

output "workspace_name" {
  value = azurerm_log_analytics_workspace.law.name
}

output "workspace_customer_id" {
  value = azurerm_log_analytics_workspace.law.workspace_id
}