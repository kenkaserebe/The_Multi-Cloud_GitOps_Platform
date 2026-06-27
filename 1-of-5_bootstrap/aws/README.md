# Bootstrap AWS - Terraform State Backend

This 1-of-5_bootstrap folder contains Terraform configuration to bootstrap an AWS S3 bucket for storing Terraform state files. It creates a secure, versioned, and encrypted S3 bucket with all public access blocked.

## Purpose

When managing infrastructure with Terraform, a remote backend (like S3) is recommended to store state files. This bootstrap step creates the S3 bucket that will be used as the backend for your actual infrastructure deployments.

## Features

- Creates an S3 bucket with a globally unique name (provided by you)
- Enables ```bucket versioning``` - recover from accidental deletions or corruption
- Enforces ```server-side encryption``` (AES-256) - protects sensitive data
- Blocks ```all public access``` - ensures bucket is private
- Uses local Terraform state for the bootstrap itself (no backend configuration)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) (v1.0+)
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials (or IAM role/permissions)
- Appropriate AWS permissions to create S3 buckets and modify their settings

## Usage


#### 1. Configure variables

Create a terraform.tfvars file (or use environment variables) with the required inputs:

```hcl
region      = "us-east-1"

bucket_name = "your-unique-state-bucket-name"
```
Important: The bucket_name must be globally unique across all of AWS


### 2. Initialize and apply

```bash
terraform init

terraform plan      # review what will be created

terraform apply     # create the bucket
```

### 3. Outputs

After apply, Terraform will output:
```
bucket_name - name of the created bucket

bucket_arn - <ARN-of-the-bucket>
```
Use these values when configuring your other Terraform projects' backend:

```hcl
terraform {

    backend "s3" {

        bucket          = "your-unique-state-bucket-name"

        key             = "path/to/your/terraform.tfstate"

        region          = "us-east-1"

        encrypt         = true

        use_lockfile    = true         # Enables s3 native locking (Terraform 1.11+)
    }
}


#### Variables

|Name        |Description                                  |Type    |Required |

|region      |AWS region where the bucket will be created  |string  |yes      |
                    
|bucket_name |Globally unique S3 bucket name               |string  |yes      |


#### Outputs

Name                        Description

bucket_name                 Name of the created S3 bucket

bucket_arn                  ARN of the created S3 bucket


### Cleanup

If you no longer need the bucket (e.g. during development/testing), you can destroy it:

```bash
terraform destroy
```

Note: force_destroy = true is set on the bucket, so it will delete even if it contains objects. For production, you should remove this flag and manage deletion carefully.


### Security

- Bucket encryption is enabled with AES-256
- Public access is fully blocked.
- Versioning protects against accidental state loss.



