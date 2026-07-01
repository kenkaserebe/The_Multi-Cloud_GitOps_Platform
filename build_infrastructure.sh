#!/bin/bash
set -euo pipefail

# ------------------------------------------------------------------------------------------
# 1. BOOTSTRAP - AWS
# ------------------------------------------------------------------------------------------
echo "=== Bootstrapping AWS (S3 bucket) ==="
AWS_MODULE_PATH="1-of-5_bootstrap/aws"
terraform -chdir="$AWS_MODULE_PATH" init
terraform -chdir="$AWS_MODULE_PATH" apply  --auto-approve

# Extract values using -raw
BUCKET_NAME=$(terraform -chdir="$AWS_MODULE_PATH" output -raw bucket_name)
BUCKET_REGION=$(terraform -chdir="$AWS_MODULE_PATH" output -raw region)

echo "AWS bootstrap complete. Bucket: $BUCKET_NAME, Region: $BUCKET_REGION"


# ------------------------------------------------------------------------------------------
# 2. BOOTSTRAP - AZURE
# ------------------------------------------------------------------------------------------
echo "=== Bootstrapping Azure (storage account) ==="
AZURE_MODULE_PATH="1-of-5_bootstrap/azure"
terraform -chdir="$AZURE_MODULE_PATH" init
terraform -chdir="$AZURE_MODULE_PATH" apply  --auto-approve

RESOURCE_GROUP=$(terraform -chdir="$AZURE_MODULE_PATH" output -raw resource_group_name)
STORAGE_ACCOUNT=$(terraform -chdir="$AZURE_MODULE_PATH" output -raw storage_account_name)
CONTAINER_NAME=$(terraform -chdir="$AZURE_MODULE_PATH" output -raw container_name)
ACCESS_KEY=$(terraform -chdir="$AZURE_MODULE_PATH" output -raw access_key 2>/dev/null)

echo "Azure bootstrap complete. Resource Group: $RESOURCE_GROUP, Storage: $STORAGE_ACCOUNT"


# ------------------------------------------------------------------------------------------
# 3. WAIT + CONFIRM FOR ENVIRONMENT CREATION
# ------------------------------------------------------------------------------------------
echo "Waiting 120 seconds for storage resources to fully propagate..."
sleep 120

read -p "Do you want to continue with environment (EKS/AKS) creation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted by user."
    exit 0
fi


# ------------------------------------------------------------------------------------------
# 4. CREATE EKS CLUSTER (AWS)
# ------------------------------------------------------------------------------------------
echo "=== Creating EKS cluster ==="
(
    cd 2-of-5_env/aws
    cat > backend.tfvars <<EOF
bucket          = "$BUCKET_NAME"
key             = "aws-env/terraform.tfstate"
region          = "$BUCKET_REGION"
encrypt         = true
use_lockfile    = true
EOF
    terraform init -backend-config=backend.tfvars
    terraform apply --auto-approve
)

# Capture EKS outputs and write them to a file for ArgoCD
EKS_CLUSTER_NAME=$(terraform -chdir=2-of-5_env/aws output -raw cluster_name)
EKS_REGION=$(terraform -chdir=2-of-5_env/aws output -raw region 2>/dev/null || echo "$BUCKET_REGION")


cat > 3-of-5_argocd/aws/cluster.tfvars <<EOF
cluster_name    = "$EKS_CLUSTER_NAME"
region          = "$EKS_REGION"
EOF
echo "EKS cluster created. Name: $EKS_CLUSTER_NAME, Region: $EKS_REGION"
echo "Outputs written to 3-of-5_argocd/aws/cluster.tfvars"


# ------------------------------------------------------------------------------------------------
# 5. CREATE AKS CLUSTER (AZURE)
# ------------------------------------------------------------------------------------------------
echo "=== Creating AKS cluster ==="
(
    cd 2-of-5_env/azure
    cat > backend.tfvars <<EOF
resource_group_name     = "$RESOURCE_GROUP"
storage_account_name    = "$STORAGE_ACCOUNT"
container_name          = "$CONTAINER_NAME"
key                     = "aks-cluster/terraform.tfstate"
EOF
    export ARM_ACCESS_KEY="$ACCESS_KEY"
    terraform init -backend-config=backend.tfvars
    terraform apply --auto-approve
)

# Capture AKS outputs and write them to a file for ArgoCD
AKS_CLUSTER_NAME=$(terraform -chdir=2-of-5_env/azure output -raw cluster_name)
AKS_RESOURCE_GROUP=$(terraform -chdir=2-of-5_env/azure output -raw resource_group_name)

cat > 3-of-5_argocd/azure/cluster.tfvars << EOF
cluster_name            = "$AKS_CLUSTER_NAME"
resource_group_name     = "$AKS_RESOURCE_GROUP"
EOF
echo "AKS cluster created. Name: $AKS_CLUSTER_NAME, Resource Group: $AKS_RESOURCE_GROUP"
echo "Outputs written to 3-of-5_argocd/azure/cluster.tfvars"


# ---------------------------------------------------------------------------------------
# 6. CONFIRM ARGOCD DEPLOYMENT
# ---------------------------------------------------------------------------------------
read -p "Do you want to deploy ArgoCD on the newly created clusters? (y/n)" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping ArgoCD deployment. Exiting."
    exit 0
fi


# ----------------------------------------------------------------------------------------
# 7. DEPLOY ARGOCD ON EKS
# ----------------------------------------------------------------------------------------
echo "=== Deploying ArgoCD on EKS ==="
(
    cd 3-of-5_argocd/aws
    cat > backend.tfvars <<EOF
bucket          = "$BUCKET_NAME"
key             = "argocd-aws/terraform.tfstate"
region          = "$EKS_REGION"
encrypt         = true
use_lockfile    = true
EOF
    terraform init -backend-config=backend.tfvars
    terraform apply --auto-approve -var-file=cluster.tfvars
)

echo "ArgoCD deployed on EKS"


# -----------------------------------------------------------------------------------------
# 8. DEPLOY ARGOCD ON AKS
# -----------------------------------------------------------------------------------------
echo "=== Deploying ArgoCD on AKS ==="
(
    cd 3-of-5_argocd/azure
    cat > backend.tfvars <<EOF
resource_group_name     = "$AKS_RESOURCE_GROUP"
storage_account_name    = "$STORAGE_ACCOUNT"
container_name          = "$CONTAINER_NAME"
key                     = "argocd-azure/terraform.tfstate"
EOF

    export ARM_ACCESS_KEY="$ACCESS_KEY"
    terraform init -backend-config=backend.tfvars
    terraform apply --auto-approve -var-file=cluster.tfvars
)

echo "ArgoCD deployed on AKS"


# -------------------------------------------------------------------------------------------
# 9. WRITE SUMMARY FILE
# -------------------------------------------------------------------------------------------
cat > environment_outputs.txt <<EOF

============================================================
            INFRASTRUCTURE DEPLOYMENT SUMMARY
============================================================
[EKS]
    Cluster Name    : $EKS_CLUSTER_NAME
    Region          : $EKS_REGION

[AKS]
    Cluster Name    : $AKS_CLUSTER_NAME
    Resource Group  : $AKS_RESOURCE_GROUP

[Bootstrap]
    AWS S3 Bucket   : $BUCKET_NAME (region: $BUCKET_REGION)
    Azure Storage   : $STORAGE_ACCOUNT (RG: $RESOURCE_GROUP)
    Azure Container : $CONTAINER_NAME
=============================================================
EOF

echo "All deployments complete! ArgoCD is installed on both clusters."
echo "Summary written to environment_outputs.txt"