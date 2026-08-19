###############################################################################
# Staging Environment – GCP – europe-west1 – backend.hcl
# Usage: terraform init -backend-config=backend.hcl
###############################################################################

bucket = "one-deploy-dash-tfstate-CHANGEME"  # replace CHANGEME with your real GCP project ID
prefix = "environments/staging/gcp/europe-west1"
