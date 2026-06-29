# multi-cloud-gitops-platform/environments/azure/providers.tf


terraform {
  required_version = ">= 1.14"
  required_providers {
    azurerm = {
        source  = "hashicorp/azurerm"
        version = "~> 4.64.0"
    }
    kubernetes = {
        source  = "hashicorp/kubernetes"
        version = "~> 2.23"
    }
    helm = {
        source  = "hashicorp/helm"
        version = "~> 2.1.1"
    }
  }
}

provider "azurerm" {
  features {}

  # Authentication is handled via Azure CLI, environment variables, or managed identity.
}