# The_Multi-Cloud_GitOps_Platform/3-of-5_argocd/aws/variables.tf

variable "cluster_name" {
  description   = "Name of the EKS cluster"
  type          = string
}