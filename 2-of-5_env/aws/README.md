# AWS Environment - EKS Cluster & Infrastructure

This Terraform configuration deploys a complete Amazon EKS cluster on AWS, including a VPC, managed node groups, IAM roles, and an ECR repository for container images. The EKS logic is encapsulated in a reusable module (`modules/eks`), and the environment state is stored remotely in an S3 bucket.

## Purpose

Provision a production-ready Kubernetes environment on AWS, following best practices for networking, security, and state management. This serves as the foundation for deploying ArgoCD and other GitOps workloads.


## Repository Structure

2-of-5_env/aws/
|---main.tf         # Root module: calls the EKS module and creates an ECR repo
|---providers.tf    # Required providers (AWS, Kubernetes, Helm)
|---variables.tf    # Input variables for the environment
|---modules/eks
    |---main.tf         # VPC, IAM roles, EKS cluster, node group
    |---outputs.tf      # Cluster endpoint, VPC ID, subnet IDs, etc
    |---variables.tf    


## Features

- `VPC` - Created with public and private subnets across 3 availability zones, Nat Gateway, DNS hostnames.
- `EKS Cluster` - Managed Kubernetes control plane with configurable version.
- `Managed Node Group` - Auto-scaling worker nodes (configurable instance type, min/max/desired count).
- `IAM Roles` - Minimal required policies for cluster and worker nodes.
- `ECR Repository` - One repository per cluster (image scanning enabled).
- `Remote State` - Terraform state stored in an S3 bucket (versioned, encrypted, locked).
- `Kubernetes Provider` - Configured automatically to communicate with the created EKS cluster.


## Prerequisites

- `Terraform` (v1.14+)
- `AWS CLI` - configured with credentials (or IAM role) having permissions to:
    - Create VPC, subnets, NAT gateways, IAM roles, EKS clusters, node groups, ECR repositories.
    - `An S3 bucket` for remote state - must exist `before` initializing the environment. See the [bootstrap/aws](../bootstrap/aws) module to create it.


## Usage

### 1. Clone the repository

bash
git clone https://github.com/kenkaserebe/multi-cloud-gitops-platform.git
cd multi-cloud-gitops-platform/environments/aws


### 2. Configure the remote backend

The backend.tf file sets the S3 backend key and region, but the bucket name is intentionally omitted. You must provide it during *terraform init* using one of these methods:

Option A - Command line flag

bash
terraform init -backend-config="bucket=your-unique-bucket-name"


Option B - Backend config file

Create a backend.hcl file (example is already present with *bucket = "ken-aws-multi-cloud-tfstate-unique-bucket"*). Edit it to use your actual bucket name:

hcl
bucket = "ken-aws-multi-cloud-tfstate-unique-bucket"

Then run:

bash
terraform init -backend-config=backend.hcl


Important: The S3 bucket must already exist and should have versioning and encryption enabled (as created by the bootstrap module).


### 3. Customize variables

Create a terraform.tfvars file (or use environment variables). Example:

```hcl
aws_region          = "<AWS_region>"
vpc_cidr            = "10.0.0.0/16"
cluster_name        = "<cluster_name>"
kubernetes_version  = "1.35"
node_instance_type  = "t3.medium"
desired_node_count  = 3
min_node_count      = 2
max_node_count      = 6
```
All variables have defaults - override only what you need.


### 4. Apply configuration

bash
terraform plan
terraform apply


After apply, Terraform outputs:
- ecr_repository_url - URL of the created ECR repository
- Module outputs form *modules/eks* (cluster endpoint, VPC ID, subnet IDs, etc.)


#### Input Variables

Environment root (environments/aws/variables.tf)

Name                Description                         Type        Default
aws_region          AWS region                          string      "eu-west-2"
vpc_cidr            CIDR block for the VPC              string      "10.0.0.0/16"
cluster_name        Name of the EKS cluster             string      "ken-eks-cluster"
kubernetes_version  Kubernetes version                  string      "1.35"
node_instance_type  EC2 instance type for worker nodes  string      "t3.medium"
desired_node_count  Desired number of worker nodes      number      3
min_node_count      Minimum worker nodes                number      2
max_node_count      Maximum worker nodes                number      6


#### EKS module ( modules/eks/variables.tf )

The module accepts the same variables plus a *tags* map. It uses the VPC module internally.


#### Outputs

Name                            Description
ecr_repository_url              URL of the ECR repository (root output)
cluster_id                      EKS cluster ID (module)
cluster_endpoint                Kubernetes API endpoint (module)
cluster_name                    Cluster name (module)
vpc_id                          VPC ID (module)
private_subnet_ids              List of private subnet IDs (module)
public_subnet_ids               List of public subnet IDs (module)
node_group_arn                  ARN of the managed node group (module)


##### Module Details ( modules/eks )

The reusable module creates:

- VPC - Using the official AWS VPC module:
    - 3 public subnets, 3 private subnets
    - Single NAT Gateway (to save costs)
    - DNS hostnames enabled
    - Required subnet tags for Kubernetes load balancer integration
- IAM Roles:
    - Cluster role with *AmazonEKSClusterPolicy*
    - Node role with *AmazonEKSClusterPolicy*, *AmazonEKS_CNI_Policy*, *AmazonEC2ContainerRegistryReadOnly*
- EKS Cluster - Public endpoint enabled (restrict CIDR in production).
- Managed Node Group - Uses private subnets, auto-scaling based on min/max/desired.


##### Connecting to the Cluster

After deployment, the root module configures the Kubernetes Provider automatically. To interact with the cluster using kubectl, update your kubeconfig:

bash
aws eks update-kubeconfig --region <region> --name <cluster_name>

Then verify:

bash
kubectl get nodes


##### Cleanup

To destroy all resources created by this environment:

bash
terraform destroy


Warning: This will delete the EKS cluster, node group, VPC, and ECR repository (including any images). The remote Terraform state file in S3 will remain - delete it manually if no longer needed.


##### Security Notes

- The EKS cluster endpoint is public (endpoint_public_access = true) with 0.0.0.0/0 allowed. For production, restrict this to specific CIDR blocks.
- Worker nodes are placed in private subnets - no direct internet access.
- The ECR repository scans images on push.
- State is encrypted in S3 and locked (Terraform 1.11+ lockfile).


##### License

[Specify your license, e.g., MIT]

