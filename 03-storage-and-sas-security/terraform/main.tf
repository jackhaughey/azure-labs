# ------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# ------------------------------------------------------------
# Storage Account (secure defaults, azurerm v4.x)
# ------------------------------------------------------------
resource "azurerm_storage_account" "stg" {
  name                     = "st${substr(md5(var.resource_group_name), 0, 10)}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

# ------------------------------------------------------------
# Blob Container (private)
# ------------------------------------------------------------
resource "azurerm_storage_container" "container" {
  name                  = "appdata"
  storage_account_name  = azurerm_storage_account.stg.name
  container_access_type = "private"
}

# ------------------------------------------------------------
# Private Endpoint for Blob
# ------------------------------------------------------------
data "azurerm_virtual_network" "hub" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "shared" {
  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.hub.name
  resource_group_name  = var.resource_group_name
}

resource "azurerm_private_endpoint" "pe_blob" {
  name                = "pe-blob-${azurerm_storage_account.stg.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.shared.id

  private_service_connection {
    name                           = "blob-connection"
    private_connection_resource_id = azurerm_storage_account.stg.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

# ------------------------------------------------------------
# SAS Token Generation (Service SAS)
# ------------------------------------------------------------
data "azurerm_storage_account_sas" "sas" {
  connection_string = azurerm_storage_account.stg.primary_connection_string

  https_only = true
  start      = timestamp()
  expiry     = timeadd(timestamp(), "24h")

  resource_types {
    service   = false
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
  }
}

# ------------------------------------------------------------
# Outputs
# ------------------------------------------------------------
output "storage_account_id" {
  value = azurerm_storage_account.stg.id
}

output "blob_endpoint" {
  value = azurerm_storage_account.stg.primary_blob_endpoint
}

output "container_name" {
  value = azurerm_storage_container.container.name
}

output "sas_token" {
  value     = data.azurerm_storage_account_sas.sas.sas
  sensitive = true
}