###############################################################################
# Staging Environment – AWS – eu-west-1 – backend.hcl
# Usage: terraform init -backend-config=backend.hcl
###############################################################################

bucket         = "one-deploy-dash-tfstate"
key            = "environments/staging/aws/eu-west-1/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "one-deploy-dash-tflock"
encrypt        = true
