# The_Multi-Cloud_GitOps_Platform/2-of-5_env/azure/main.tf

resource "azurerm_resource_group" "this" {
  name      = var.az_resource_group_name
  location  = var.az_location
  tags      = var.az_tags
}

module "aks_cluster" {
  source                  = "../modules/aks"

  az_location                = azurerm_resource_group.this.location
  az_resource_group_name     = azurerm_resource_group.this.name
  az_cluster_name            = var.az_cluster_name
  az_kubernetes_version      = var.az_kubernetes_version
  az_node_count              = var.az_node_count
  az_node_vm_size            = var.az_node_vm_size
  az_vnet_address_space      = var.az_vnet_address_space
  az_subnet_address_prefixes = var.az_subnet_address_prefixes
  az_dns_prefix              = var.az_dns_prefix
  az_enable_auto_scaling     = var.az_enable_auto_scaling
  az_min_node_count          = var.az_min_node_count
  az_max_node_count          = var.az_max_node_count

  az_tags = {
    Environment           = "dev"
    ManagedBy             = "Terraform"
  }
}


# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.az_acr_name != "" ? var.az_acr_name : replace("${var.az_cluster_name}acr", "-", "")
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Basic"
  admin_enabled       = false    # Use managed identity instead
  tags                = var.az_tags
}


# Grant AKS managed identity AcrPull role on the ACR
resource "azurerm_role_assignment" "aks_to_acr" {
  principal_id          = module.aks_cluster.managed_identity_principal_id
  role_definition_name  = "AcrPull"
  scope                 = azurerm_container_registry.acr.id
}

output "acr_login_server" {
  value                 = azurerm_container_registry.acr.login_server
}