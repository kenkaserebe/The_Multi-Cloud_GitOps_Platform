# multi-cloud-gitops-platform/environments/azure/README.md

# Azure Environment - AKS Cluster & Infrastructure

This Terraform configuration deploys a complete Azure Kubernetes Service (AKS) cluster on Azure, including a virtual network, subnet, system-assigned managed identity, and an Azure Container Registry (ACR). The AKS logic is encapsulated in a reusable module (`modules/aks`), and the environment state is stored remotely in an Azure Storage blob container.


## Purpose

Provision a production-ready Kubernetes environment on Azure, following best practices for networking, security, and state management. This serves as the foundation for deploying ArgoCD and other GitOps workloads.


## Repository Structure

environment/azure/
|---backend.hcl  # Example backend config file (contains hardcoded values - edit before use)
|---backend.tf   # Terraform backend (azurerm) - parameters supplied via -backend-config
|---main.tf      # Root module: calls the AKS module, creates resource group and ACR
|---providers.tf # Required providers (azurerm, kubernetes, helm)
|---variables.tf # Input variables for the environment
|---modules
    |---aks/
        |---main.tf     # Virtual network, subnet, AKS cluster with default node pool
        |---outputs.tf  # Cluster ID, name, kubeconfig, managed identity principal ID, etc.
        |---variables.tf


## Features

- **Resource Group** - Created for all environment resources.
- **Virtual Network** - Custom VNet with a dedicated subnet for AKS nodes.
- **AKS Cluster** - Managed Kubernetes control plane with configurable version.
- **Default Node Pool** - VM size, node count, and optional auto-scaling (min/max).
- **Network Configuration** - Uses `kubenet` plugin with Calico network policy.
- **Managed Identity** - System-assigned identity for the AKS cluster (no manual credentials).
- **Azure Container Registry** - Basic SKU ACR, integrated with AKS via `AcrPull` role assignment.
- **Remote State** - Terraform state stored in an Azure Storage blob container (account created by the bootstrap module).
- **Kubernetes Provider** - Configured automatically after cluster creation (if used later).


## Prerequisites

- **Terraform** (v1.14+)
- **Azure CLI** - logged in (`az login`) with sufficient permissions to create:
    - Resource groups, virtual networks, subnets
    - AKS clusters, node pools, managed identities
    - Azure Container Registry, role assignments
- **An Azure Storage Account and Container** for remote state - must exist **before** initializing the environment. See the [bootstrap/azure](../bootstrap/azure) module to create them.


## Usage

### 1. Clone the repository

bash
git clone https://github.com/kenkaserebe/multi-cloud-gitops-platform.git
cd environments/azure


### 2. Retrieve the storage access key
The bootstrap module created a storage account and container. Get the primary access key:

bash
cd ../../bootstrap/azure
terraform output -raw primary_access_key


Copy the key string. For security, set it as an environment variable (used by the Azure provider):

bash
export ARM_ACCESS_KEY="your-copied-access-key"


Alternative: You can pass the access key directly via -backend-config="access_key=..." during terraform init. Using an environment variable is cleaner.


### 3. Configure the remote backend

The **backend.tf** file sets the key (aks-cluster/terraform.tfstate) but leaves the storage account details empty. You must provide them during **terraform init**.

Option A - Command line flags

bash
terraform init \
    -backend-config="resource_group_name=ken-terraform-state-rg" \
    -backend-config="storage_account_name=kenmulticloudtfstate" \
    -backend-config="container_name=tfstate"

Replace the names with the actual ones you used in the bootstrap module


Option B - Backend config file

Edit the provided backend.hcl file (currently has example values):

hcl
resource_group_name     = "ken-terraform-state-rg"
storage_account_name    = "kenmulticloudtfstate"
container_name          = "tfstate"

Then run:

bash
terraform init -backend-config=backend.hcl

The access key is already exported as ARM_ACCESS_KEY, so you don't need to include it in the config file.


### 4. Customize variables

Create a terraform.tfvars file (or use environment variables). Example:

hcl
az_location             = "francecentral"
az_resource_group_name  = "my-aks-rg"
az_cluster_name         = "my-aks-cluster"
az_kubernetes_version   = "1.33.0"
az_node_vm_size         = "Standard_B2s_v2"
az_node_count           = 2
az_enable_auto_scaling  = true
az_min_node_count       = 1
az_max_node_count       = 5
az_acr_name             = "myuniqueacr"     # if empty, generated from cluster name


All variables have defaults - override only what you need.



### 5. Apply the configuration

bash
terraform plan
terraform apply

After apply, Terraform outputs:
- acr_login_server - URL of the created ACR
- Module outputs from modules/aks (cluster name, endpoint, managed identity principal ID, etc.)


#### Input Variables

Environment root (environment/azure/variables.tf)

Name                        Description                     Type            Default
az_location                 Azure region                    string          "francecentral"
az_resource_group_name      Name of the resource group      string          "ken-aks-rg"
container_name              Blob container name (for
                            backend reference)              string          "tfstate"
az_cluster_name             Name of the AKS cluster         string          "ken-aks-cluster"
az_kubernetes_version       Kubernetes version              string          "1.33.0"
az_node_vm_size             VM size for worker nodes        string          "Standard_B2s_v2"
az_vnet_address_space       VNet address space              list(string)    ["10.1.0.0/16"]
az_subnet_address_prefixes  Subnet address prefixes         list(string)    ["10.1.0.0/24"]
az_dns_prefix               DNS prefix (if empty, uses      string          ""
                            cluster name)
az_node_count               Number of worker nodes          number          2
az_enable_auto_scaling      Enable node pool auto-scaling   bool            true
az_min_node_count           Minimum nodes                   number          1
                            (when auto-scaling)
az_max_node_count           Maximum nodes                   number          5
                            (when auto-scaling)
az_acr_name                 ACR name (if empty, uses        string          ""
                            cluster name)
az_tags                     Tags to apply to resources      map(string)     {}


#### AKS module (modules/aks/variables.tf)

The module accepts similar variables (without the az_ prefix) plus the resource group name, location, and tags.

#### Outputs

Name                            Description
acr_login_server                Login server URL of the Azure Container Registry (root output)
cluster_id                      AKS cluster ID (module)
cluster_name                    Cluster name (module)
kube_config                     Raw kubeconfig (sensitive) (module)
cluster_endpoint                Kubernetes API server endpoint (module)
cluster_ca_certificate          Base64 encoded CA certificate (sensitive) (module)
managed_identity_principal_id   Principal ID of the system-assigned managed identity (module)


#### Module Details (modules/aks)

The reusable module creates:

- Virtual Network - With a single subnet for the AKS cluster.
- AKS Cluster - System-assigned managed identity, RBAC enabled.
- Default Node Pool - Configurable VM size, node count, and optional auto-scaling.
- Netowork Profile - kubenet plugin, Calico network policy, service CIDR 10.0.0.0/16.
- Upgrade settings - Max surge of 10% for rolling upgrades.


##### Connecting to the Cluster

After deployment, update your kubeconfig using the Azure CLI:

bash
az aks get-credentials --resource-group <resource_group_name> --name <cluster_name>

Then verify:

bash
kubectl get nodes

Alternatively, you can use the kube_config output from the module (sensitive) to configure the Kubernetes provider or a local kubeconfig file.


##### Cleanup

To destroy all resources created by this environment:

bash
terraform destroy

Warning: This will delete the AKS cluster, node pool, virtual network, resource group, and ACR (including all container images). The remote Terraform state file in the storage account will remain - delete it manually if no longer needed.


##### Security Notes

- The AKS cluster uses system-assigned managed identity - no static credentials.
- RBAC is enabled.
- Calicon network policy provides network segmentation.
- ACR admin account is disabled - AKS pulls images via managed identity (AcrPull role).
- The cluster API server endpoint is public by default. For production, restrict access using api_server_authorized_ip_ranges.
- The remote state is encrypted at rest in Azure Storage.


##### License

[Specify your license, e.g., MIT]