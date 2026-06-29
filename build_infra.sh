#!/bin/bash
set -euo pipefail  # strict error handling

# ------------------------------------------------------------
# 1. Bootstrap AWS
# ------------------------------------------------------------
AWS_MODULE_PATH="1-of-5_bootstrap/aws"
echo "=== Bootstrapping AWS ==="
terraform -chdir="$AWS_MODULE_PATH" init
terraform -chdir="$AWS_MODULE_PATH" apply -auto-approve

# Capture AWS outputs as JSON
AWS_OUTPUTS=$(terraform -chdir="$AWS_MODULE_PATH" output -json)

# Extract values (using jq, which must be installed)
BUCKET_NAME=$(echo "$AWS_OUTPUTS" | jq -r '.bucket_name.value')
BUCKET_REGION=$(echo "$AWS_OUTPUTS" | jq -r '.region.value')

# ------------------------------------------------------------
# 2. Bootstrap Azure
# ------------------------------------------------------------
AZURE_MODULE_PATH="1-of-5_bootstrap/azure"
echo "=== Bootstrapping Azure ==="
terraform -chdir="$AZURE_MODULE_PATH" init
terraform -chdir="$AZURE_MODULE_PATH" apply -auto-approve

AZURE_OUTPUTS=$(terraform -chdir="$AZURE_MODULE_PATH" output -json)

RESOURCE_GROUP=$(echo "$AZURE_OUTPUTS" | jq -r '.resource_group_name.value')
STORAGE_ACCOUNT=$(echo "$AZURE_OUTPUTS" | jq -r '.storage_account_name.value')
CONTAINER_NAME=$(echo "$AZURE_OUTPUTS" | jq -r '.container_name.value')
ACCESS_KEY=$(echo "$AZURE_OUTPUTS" | jq -r '.access_key.value')   # sensitive

# ------------------------------------------------------------
# 3. Wait 180 seconds and ask to continue
# ------------------------------------------------------------
echo "Waiting 180 seconds for storage resources to fully propagate..."
sleep 180

read -p "Do you want to continue with environment creation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted by user."
    exit 0
fi

# ------------------------------------------------------------
# 4. Generate backend configuration files for the next stage
# ------------------------------------------------------------
# Assume your environment modules are in:
#   2-of-5_env/aws   and   2-of-5_env/azure
# We'll write a backend.tfvars file in each module directory.

# AWS backend config
cat > 2-of-5_env/aws/backend.tfvars <<EOF
bucket = "$BUCKET_NAME"
key    = "aws-env/terraform.tfstate"
region = "$BUCKET_REGION"
encrypt = true
use_lockfile = true
EOF

# Azure backend config (using partial configuration)
cat > 2-of-5_env/azure/backend.tfvars <<EOF
resource_group_name  = "$RESOURCE_GROUP"
storage_account_name = "$STORAGE_ACCOUNT"
container_name       = "$CONTAINER_NAME"
key                  = "aks-cluster/terraform.tfstate"
# Do NOT put access_key here – use -backend-config or environment variable
EOF

# ------------------------------------------------------------
# 5. Run Terraform for the environment modules
# ------------------------------------------------------------
echo "=== Creating AWS environment ==="
cd 2-of-5_env/aws
terraform init -backend-config=backend.tfvars
terraform apply -auto-approve
cd - > /dev/null

echo "=== Creating Azure environment ==="
# For Azure, you can either:
# - Use the access_key via environment variable: ARM_ACCESS_KEY
# - Or pass it via -backend-config on the init command
export ARM_ACCESS_KEY="$ACCESS_KEY"
cd 2-of-5_env/azure
terraform init -backend-config=backend.tfvars
terraform apply -auto-approve
cd - > /dev/null

echo "All environments created successfully!"