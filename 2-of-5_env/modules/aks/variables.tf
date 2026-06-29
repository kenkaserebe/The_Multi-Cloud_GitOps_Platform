# The_Multi-Cloud_GitOps_Platform/2-of-5_env/modules/aks/variables.tf

variable "az_location" {
  description   = "Azure region"
  type          = string
}

variable "az_resource_group_name" {
  description   = "Resource group name"
  type          = string
}

variable "az_cluster_name" {
  description   = "AKS cluster name"
  type          = string
}

variable "az_vnet_address_space" {
  description   = "Address space for the virtual network"
  type          = list(string)
}

variable "az_subnet_address_prefixes" {
  description   = "Address prefixes for the AKS subnet"
  type          = list(string)
}

variable "az_kubernetes_version" {
  description   = "Kubernetes version"
  type          = string
}

variable "az_enable_auto_scaling" {
  description   = "Enable auto-scaling for the default node pool"
  type          = bool
  default       = false
}

variable "az_node_count" {
  description   = "Number of worker nodes"
  type          = number
}

variable "az_min_node_count" {
  description   = "Minimum node count when auto-scaling enabled"
  type          = number
}

variable "az_max_node_count" {
  description   = "Maximum node count when auto-scaling enabled"
  type          = number
}

variable "az_node_vm_size" {
  description   = "VM size for worker nodes"
  type          = string
  default       = "standard_b2s_v2"
}

variable "az_dns_prefix" {
  description   = "DNS prefix for the cluster (if empty, uses cluster name)"
  type          = string
  default       = ""
}

variable "az_tags" {
  description   = "Tags to apply to resources"
  type          = map(string)
  default       = {}
}