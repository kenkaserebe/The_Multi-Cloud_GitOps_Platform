# The_Multi-Cloud_GitOps_Platform/2-of-5_env/aws/main.tf

module "eks_cluster" {
  source = "../modules/eks"
  
}