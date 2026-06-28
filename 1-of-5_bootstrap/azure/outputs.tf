# The_Multi-Cloud_GitOps_Platform/1-of-5_bootstrap/azure/outputs.tf

output "resource_group_name" {
  value = azurerm_resource_group.state_rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.state_sa.name
}

output "container_name" {
  value = azurerm_storage_container.state_container.name
}

output "access_key" {
  value     = azurerm_storage_account.state_sa.primary_access_key
  sensitive = true
}