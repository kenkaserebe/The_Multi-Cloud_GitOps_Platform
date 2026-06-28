# The_Multi-Cloud_GitOps_Platform/1-of-5_bootstrap/azure/main.tf

terraform {
  # Use local state for bootstrap
  # No backend block → Terraform defaults to local state
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "state_rg" {
  name      = var.resource_group_name
  location  = var.location
}

resource "azurerm_storage_account" "state_sa" {
  name                              = var.storage_account_name
  resource_group_name               = azurerm_resource_group.state_rg.name
  location                          = azurerm_resource_group.state_rg.location
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
}

resource "azurerm_storage_container" "state_container" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.state_sa.id
  container_access_type = "private"
}