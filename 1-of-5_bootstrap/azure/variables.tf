# The_Multi-Cloud_GitOps_Platform/1-of-5_bootstrap/azure/variables.tf

variable "location" {
  description   = "Azure region"
  type          = string
}

variable "resource_group_name" {
  description   = "Name of the resource group"
  type          = string
}

variable "storage_account_name" {
  description   = "Globally unique storage account name (lowercase letters and numbers)"
  type          = string
}

variable "container_name" {
  description   = "Name of the blob container"
  type          = string
  default       = "tfstate"
}