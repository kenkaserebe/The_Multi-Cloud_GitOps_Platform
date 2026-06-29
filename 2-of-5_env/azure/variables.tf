# multi-cloud-gitops-platform/environments/azure/variables.tf


variable "az_location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "francecentral" 
}

variable "az_resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "ken-aks-rg"
}

variable "az_container_name" {
  description   = "Name of the blob container"
  type          = string
  default       = "tfstate"
}

variable "az_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "ken-aks-cluster"
}

variable "az_kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.33.0"
}

variable "az_node_vm_size" {
  description = "VM size for worker nodes"
  type        = string
  default     = "Standard_B4s_v2"   # To get all vm sizes az vm list-skus --location francecentral --size Standard_B --output table
}

variable "az_vnet_address_space" {
  description   = "Address space for the virtual network"
  type          = list(string)
  default       = ["10.1.0.0/16"]
}

variable "az_subnet_address_prefixes" {
  description   = "Address prefixes for the AKS subnet"
  type          = list(string)
  default       = ["10.1.0.0/24"]
}

variable "az_dns_prefix" {
  description   = "DNS prefix for the cluster (if empty, uses cluster name)"
  type          = string
  default       = ""
}

variable "az_enable_auto_scaling" {
  description   = "Enable auto-scaling for the default node pool"
  type          = bool
  default       = false
}

variable "az_node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "az_min_node_count" {
  description   = "Minimum node count when auto-scaling enabled"
  type          = number
  default       = 1
}

variable "az_max_node_count" {
  description   = "Maximum node count when auto-scaling enabled"
  type          = number
  default       = 6
}

variable "az_acr_name" {
  description   = "Name for the Azure Container Registry (if empty, generated from cluster name)"
  type          = string
  default       = ""
}

variable "az_tags" {
  description   = "Tags to apply to resources"
  type          = map(string)
  default       = {}
}

