# The_Multi-Cloud_GitOps_Platform/build_infra.sh

#!/bin/bash

# Create the AWS bucket to house the state file for AWS infrastructure
AWS_MODULE_PATH="1-of-5_bootstrap/aws"

terraform -chdir="$AWS_MODULE_PATH" init
terraform -chdir="$AWS_MODULE_PATH" apply --auto-approve

# Create the Azure bucket to house the state file for Azure infrastructure
# Remember to run "az login" in shell to log into Azure before running the below
AZURE_MODULE_PATH="1-of-5_bootstrap/azure"

terraform -chdir="$AZURE_MODULE_PATH" init
terraform -chdir="$AZURE_MODULE_PATH" apply --auto-approve