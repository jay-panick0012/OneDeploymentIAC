###############################################################################
# Dev Environment – Azure – eastus – backend.hcl
# Usage: terraform init -backend-config=backend.hcl
###############################################################################

resource_group_name  = "one-deploy-dash-tfstate-rg"
storage_account_name = "onedeploydashtfstate"
container_name       = "tfstate"
key                  = "environments/dev/azure/eastus/terraform.tfstate"
