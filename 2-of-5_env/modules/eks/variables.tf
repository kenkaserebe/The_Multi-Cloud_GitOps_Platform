# The_Multi-Cloud_GitOps_Platform/2-of-5_env/modules/eks/variables.tf

variable "aws_region" {
  description   = "AWS region"
  type          = string
}

variable "vpc_cidr" {
  description   = "CIDR block for the VPC"
  type          = string
}

variable "cluster_name" {
  description   = "EKS cluster name"
  type          = string
}

variable "kubernetes_version" {
  description   = "Kubernetes version"
  type          = string
}

variable "node_instance_type" {
  description   = "EC2 instance type for worker nodes"
  type          = string
}

variable "desired_node_count" {
  description   = "Desired number of worker nodes"
  type          = string
}

variable "min_node_count" {
  description   = "Minimum number of worker nodes"
  type          = string
}

variable "max_node_count" {
  description   = "Maximum number of worker nodes"
  type          = string
}

variable "tags" {
  description   = "Tags to apply to resources"
  type          = map(string)
  default       = {}
}