###############################################################################
# Dev Environment – terraform.tfvars
# Concrete values for the dev environment.
# SENSITIVE values (account IDs, subscription IDs) should be injected via
# environment variables or a secrets manager, not committed to source control.
###############################################################################

project_name = "one-deploy-dash"
owner        = "platform-team"

# ── AWS ───────────────────────────────────────────────────────────────────────
aws_region         = "us-east-1"
aws_account_id     = "123456789012"   # replace with real account ID
kubernetes_version = "1.30"

# ── Azure ─────────────────────────────────────────────────────────────────────
azure_subscription_id = "00000000-0000-0000-0000-000000000000"  # replace
azure_location        = "eastus"

# ── GCP ───────────────────────────────────────────────────────────────────────
gcp_project = "my-gcp-project-dev"   # replace with real project ID
gcp_region  = "us-central1"
