# The_Multi-Cloud_GitOps_Platform/build_infra.sh

#!/bin/bash

# Create the AWS bucket to house the state file for AWS infrastructure
MODULE_PATH="1-of-5_bootstrap/aws"
#ls $MODULE_PATH
terraform -chdir="$MODULE_PATH" apply --auto-approve