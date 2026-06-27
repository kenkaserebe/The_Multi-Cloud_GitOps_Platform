# The_Multi-Cloud_GitOps_Platform/1-of-5_bootstrap/aws/variables.tf

variable "region" {
  description   = "AWS region"
  type          = string
}

variable "bucket_name" {
  description   = "Globally unique S3 bucket name"
  type          = string
}