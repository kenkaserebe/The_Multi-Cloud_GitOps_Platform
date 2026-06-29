# The_Multi-Cloud_GitOps_Platform/2-of-5_env/modules/aks/outputs.tf

output "cluster_id" {
  description   = "ID of the AKS cluster"
  value         = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description   = "Name of the AKS cluster"
  value         = azurerm_kubernetes_cluster.this.name
}

output "kube_config" {
  description   = "Raw kubeconfig for the cluster"
  value         = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive     = true
}

output "cluster_endpoint" {
  description   = "Kubernetes API server endpoint"
  value         = azurerm_kubernetes_cluster.this.kube_config[0].host
}

output "cluster_ca_certificate" {
  description   = "Base64 encoded CA certificate for the cluster"
  value         = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive     = true
}

output "managed_identity_principal_id" {
  description   = "Principal ID of the system-assigned managed identity"
  value         = azurerm_kubernetes_cluster.this.identity[0].principal_id
}