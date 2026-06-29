# The_Multi-Cloud_GitOps_Platform/2-of-5_env/modules/eks/main.tf


# Data sources to get information about the current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Fetch available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC module
module "vpc" {
  source                = "terraform-aws-modules/vpc/aws"
  version               = "~> 5.0"

  name                  = "${var.cluster_name}-vpc"
  cidr                  = var.vpc_cidr

  azs                   = slice(data.aws_availability_zones.available.names, 0, 3) # Use the first 3 AZs
  private_subnets       = [for i, az in slice(data.aws_availability_zones.available.names, 0, 3) : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets        = [for i, az in slice(data.aws_availability_zones.available.names, 0, 3) : cidrsubnet(var.vpc_cidr, 4, i + 3)]

  enable_nat_gateway    = true
  single_nat_gateway    = true
  enable_dns_hostnames  = true

  public_subnet_tags    = {
    "kubernetes.io/role/internal-elb" = 1   # tags required for AWS Load Balancer integration
  }

  private_subnet_tags   = {
    "kubernetes.io/role/internal-elb" = 1  # EKS cluster will use these tags to auto-discover subnets for load balancers
  }

  tags                  = var.tags
}



# IAM role for EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name                  = "${var.cluster_name}-cluster-role"
  assume_role_policy    = jsonencode({
    Version     = "2012-10-17"
    Statement   = [
        {
            Effect      = "Allow"
            Principal   = {
                Service = "eks.amazonaws.com"
            }
            Action      = "sts:AssumeRole"
        }
    ]
  })

  tags                  = var.tags
}


resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn    = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role          = aws_iam_role.eks_cluster_role.name
}


# IAM role for EKS node group
resource "aws_iam_role" "eks_node_role" {
  name                  = "${var.cluster_name}-node-role"
  assume_role_policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect      = "Allow"
            Principal   = {
                Service = "ec2.amazonaws.com"
            }
            Action      = "sts:AssumeRole"
        }
    ]
  })

  tags                  = var.tags
}


resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn    = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role          = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn    = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role          = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn    = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role          = aws_iam_role.eks_node_role.name
}



# EKS cluster
resource "aws_eks_cluster" "this" {
  name      = var.cluster_name
  role_arn  = aws_iam_role.eks_cluster_role.arn
  version   = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(module.vpc.public_subnets, module.vpc.private_subnets) # We include both public and private subnets. For production, you might want to restrict to private only.
    endpoint_private_access = false             # Set to true if you want API private
    endpoint_public_access  = true              # For PoC, public access is easier
    public_access_cidrs     = ["0.0.0.0/0"]     # Restrict in production
  }

  # Ensure the IAM is created before the cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = var.tags
}


# EKS managed node group
resource "aws_eks_node_group" "this" {
  cluster_name      = aws_eks_cluster.this.name
  node_group_name   = "${var.cluster_name}-node-group"
  node_role_arn     = aws_iam_role.eks_node_role.arn

  subnet_ids        = module.vpc.private_subnets

  scaling_config {
    desired_size    = var.desired_node_count
    max_size        = var.max_node_count
    min_size        = var.min_node_count
  }

  instance_types = [var.node_instance_type]

  # Ensure the cluster is fully created and IAM role is attached
  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy
  ]

  tags = var.tags
}