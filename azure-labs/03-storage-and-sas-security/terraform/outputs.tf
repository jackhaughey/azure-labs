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