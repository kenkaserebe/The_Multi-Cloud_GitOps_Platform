# The_Multi-Cloud_GitOps_Platform/2-of-5_env/aws/outputs.tf

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = var.cluster_name
}

output "region" {
  description = "The AWS region of the EKS cluster"
  value       = var.aws_region  # or data.aws_region.current.name
}