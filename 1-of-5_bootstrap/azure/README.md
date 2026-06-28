# Bootstrap Azure - Terraform State Backend

This folder contains Terraform configuration to bootstrap an Azure Storage Account and Blob Container for storing Terraform state files. It creates a secure, private, and encrypted backend with a dedicated resource group.

## Purpose

When managing infrastructure with Terraform, a remote backend (like Azure Storage) is recommended to store state files. This bootstrap step creates the storage account and container that will be used as the backend for your actual infrastructure deployments.

## Features

- Creates a dedicated ```resource group``` for state management
- Creates a ```storage account``` with:
    - Standard tier, LRS replication
    - HTTPS traffic only enforced
    - Minimum TLS version 1.2
    - Public access to nested items blocked
- Creates a ```private blob container``` for storing `.tfstate` files
- Uses local Terraform state for the bootstrap itself (no backend configuration)
- Outputs the primary access key (marked sensitive)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) (v1.0+)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) installed and logged in (`az login`)
- Appropriate Azure permissions to create resource groups, storage accounts, and containers

## Usage

### 1. Configure variables

Create a terraform.tfvars file (or use environment variables) with the required inputs:

```hcl
location                = "East Us"
resource_group_name     = "terraform-state-rg"
storage_account_name    = "tfstateuniquesa123"      # must be globally unique, lowercase & numbers only
container_name          = "tfstate"                 # optional, defaults to "tfstate"
```
Important: The storage_account_name must be globally unique across all of Azure and can only contain lowercase letters and numbers (3-24 characters).


### 2. Initialize and apply

```bash
terraform init
terraform plan  # review what will be created
terraform apply # create the resources
```

### 3. Outputs

After apply, Terraform will output:
```
resource_group_name - name of the created resource group
storage_account_name - name of the storage account
container_name - name of the blob container
primary_access_key - (sensitive) the access key for the storage account
```

Use these values when configuring your other Terraform projects' backend:

```hcl
terraform {

    backend "azurerm" {
        resource_group_name     = "terraform-state-rg"
        storage_account_name    = "tfstateuniquesa123"
        container_name          = "tfstate"
        key                     = "path/to/your/terraform.tfstate"
    }
}
```
If you need to use the access key (for legacy or non-Terraform tools), retrieve it with:

```bash
terraform output -json primary_access_key
```

##### Variables
```
Name                    Description                         Type        Default
location                Azure region (e.g. "East US")       string      none
resource_group_name     Name of the resource group          string      none
storage_account_name    Globally unique storage account     string      none
                        name (lowercase letters/numbers,
                        3-24 characters)
container_name          Name of the blob container          string      "tfstate"
```

##### Outputs
```
Name                    Description                                     Sensitive
resource_group_name     Name of the created resource group              no
storage_account_name    Name of the storage account                     no
container_name          Name of the blob container                      no
primary_access_key      Primary access key for the storage account      yes
```

##### Cleanup

If you no longer need the backend (e.g., during development/testing), destroy the resources:

```bash
terraform destroy
```
This will delete the resource group and all its contents (storage account, container, and any state files stored inside). Use with caution.

##### Security

HTTPS is enforced - all traffic must be encrypted.
Minimum TLS version is set to 1.2.
Nested items (blobs) cannot be made public.
The blob container is set to private access.
The access key is marked as sensitive and not displayed in plain text by default.
