###############################################################################
# Production Environment – Azure – eastus – terraform.tfvars
# Concrete values for the production/azure/eastus stack.
# SENSITIVE values (subscription IDs) should be injected via environment
# variables or a secrets manager, not committed to source control.
###############################################################################

project_name          = "one-deploy-dash"
owner                 = "platform-team"
azure_subscription_id = "00000000-0000-0000-0000-000000000000"  # replace
location              = "eastus"
kubernetes_version    = "1.30"
alert_email           = "platform-team@example.com"
