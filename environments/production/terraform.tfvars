###############################################################################
# Production Environment – terraform.tfvars
# IMPORTANT: Never commit real credentials or account IDs to source control.
# Use environment variables or a secrets manager (Vault, AWS SSM, Azure KV).
###############################################################################

project_name = "one-deploy-dash"
owner        = "platform-team"

aws_region         = "us-east-1"
aws_account_id     = "123456789012"
kubernetes_version = "1.30"

azure_subscription_id = "00000000-0000-0000-0000-000000000000"
azure_location        = "eastus"

gcp_project = "my-gcp-project-prod"
gcp_region  = "us-central1"
