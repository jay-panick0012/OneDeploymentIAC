###############################################################################
# Staging Environment – AWS – eu-west-1 – terraform.tfvars
# Concrete values for the staging/aws/eu-west-1 stack.
# SENSITIVE values (account IDs) should be injected via environment variables
# or a secrets manager, not committed to source control.
###############################################################################

project_name       = "one-deploy-dash"
owner              = "platform-team"
aws_account_id     = "123456789012"  # replace with real account ID
kubernetes_version = "1.30"
