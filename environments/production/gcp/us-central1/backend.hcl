###############################################################################
# Production Environment – GCP – us-central1 – backend.hcl
# Usage: terraform init -backend-config=backend.hcl
###############################################################################

bucket = "one-deploy-dash-tfstate-CHANGEME"  # replace CHANGEME with your real GCP project ID
prefix = "environments/production/gcp/us-central1"
