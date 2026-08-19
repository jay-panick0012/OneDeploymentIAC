###############################################################################
# Staging Environment – Azure – westeurope – backend.hcl
# Usage: terraform init -backend-config=backend.hcl
###############################################################################

resource_group_name  = "one-deploy-dash-tfstate-rg"
storage_account_name = "onedeploydashtfstate"
container_name       = "tfstate"
key                  = "environments/staging/azure/westeurope/terraform.tfstate"
