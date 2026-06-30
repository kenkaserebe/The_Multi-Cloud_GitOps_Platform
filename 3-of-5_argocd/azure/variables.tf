# The_Multi-Cloud_GitOps_Platform/3-of-5_argocd/azure/variables.tf

variable "cluster_name" {
  description   = "Name of the AKS cluster"
  type          = string
}

variable "resource_group_name" {
  description   = "Resource group name of the AKS cluster"
  type          = string
}