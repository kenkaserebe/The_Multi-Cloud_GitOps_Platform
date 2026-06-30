# The_Multi-Cloud_GitOps_Platform/2-of-5_env/azure/outputs.tf

output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "resource_group_name" {
  description = "The resource group name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.resource_group_name
}