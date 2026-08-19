###############################################################################
# Production Environment – AWS – us-east-1 – backend.hcl
# Usage: terraform init -backend-config=backend.hcl
###############################################################################

bucket         = "one-deploy-dash-tfstate"
key            = "environments/production/aws/us-east-1/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "one-deploy-dash-tflock"
encrypt        = true
