# multi-cloud-gitops-platform/environments/aws/providers.tf


terraform {
  required_version = ">= 1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # We may also need kubernetes and helm providers later for ArgoCD installation

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # Authentication is handled via AWS CLI environment variables, ~/.aws/credentials, or IAM role.
  # No explicit keys needed here.
}
