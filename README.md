# Infrastructure as Code – One Deployment Dashboard

Multi-cloud Terraform modules and environment configurations for the One Deployment Dashboard.
Targets AWS, Azure, and GCP from a single, well-structured IaC root.

---

## Directory Structure

```
iac/
├── README.md                        ← this file
├── modules/
│   ├── aws/
│   │   ├── eks/                     AWS EKS cluster + managed node group + OIDC
│   │   ├── ecr/                     Elastic Container Registry + lifecycle policy
│   │   ├── s3/                      S3 bucket (versioning, SSE, lifecycle)
│   │   ├── iam-role/                Generic IAM role with managed policy attachments
│   │   ├── kms/                     Customer-managed KMS key + alias
│   │   ├── rds/                     RDS PostgreSQL instance + subnet group
│   │   └── vpc/                     VPC, public/private subnets, IGW, NAT, routes
│   ├── azure/
│   │   ├── aks/                     AKS cluster + Log Analytics
│   │   ├── acr/                     Azure Container Registry (with geo-replication)
│   │   ├── keyvault/                Azure Key Vault + access policy
│   │   ├── service-principal/       AAD App + SP + rotating password + role assignment
│   │   └── vnet/                    Virtual Network + subnets + NSGs
│   └── gcp/
│       ├── gke/                     GKE cluster (autopilot or standard) + node pool
│       ├── artifact-registry/       Artifact Registry repository (Docker/Maven/NPM)
│       ├── cloudsql/                Cloud SQL instance (Postgres) + database
│       ├── kms/                     KMS key ring + crypto key with rotation
│       └── gcs/                     GCS bucket (versioning, lifecycle, uniform access)
├── environments/
│   ├── dev/                         Cost-optimised: single NAT, small instances
│   ├── staging/                     Mid-tier: multi-AZ NAT, autoscaling, HA databases
│   └── production/                  Full HA: private endpoints, HSM keys, geo-replication
└── state-backends/
    ├── aws.tf                       S3 + DynamoDB backend (bootstrap + config template)
    ├── azure.tf                     Azure Blob Storage backend (bootstrap + config template)
    └── gcp.tf                       GCS backend (bootstrap + config template)
```

---

## Prerequisites

| Tool | Minimum version | Notes |
|------|-----------------|-------|
| Terraform | 1.9.0 | `terraform version` |
| AWS CLI | 2.x | Required for AWS provider auth |
| Azure CLI | 2.x | Required for AzureRM/AzureAD providers |
| gcloud CLI | 470+ | Required for Google provider auth |
| kubectl | 1.29+ | Optional, for post-deploy cluster access |

### Provider versions (pinned in each environment `main.tf`)

| Provider | Version constraint |
|----------|--------------------|
| `hashicorp/aws` | `>= 5.0` |
| `hashicorp/azurerm` | `>= 3.100` |
| `hashicorp/azuread` | `>= 2.47` |
| `hashicorp/google` | `>= 5.0` |
| `hashicorp/tls` | `>= 4.0` |
| `hashicorp/time` | `>= 0.11` |
| `hashicorp/random` | `>= 3.5` |

---

## Authentication

### AWS

```bash
# Option A – named profile
export AWS_PROFILE=my-profile

# Option B – environment variables (CI recommended)
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...        # if using assumed roles

# Option C – OIDC (GitHub Actions, GitLab CI)
# Configure aws-actions/configure-aws-credentials and use OIDC role ARNs.
```

### Azure

```bash
# Interactive login (local dev)
az login
az account set --subscription "00000000-0000-0000-0000-000000000000"

# Service Principal (CI)
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."

# Workload Identity / OIDC (recommended for GitHub Actions)
export ARM_USE_OIDC=true
export ARM_CLIENT_ID="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."
```

### GCP

```bash
# Interactive login (local dev)
gcloud auth application-default login
gcloud config set project MY_PROJECT_ID

# Service Account key (not recommended for production)
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa-key.json

# Workload Identity Federation (recommended for CI)
# Configure gcloud to use the WIF provider and impersonate a service account.
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=terraform@my-project.iam.gserviceaccount.com
```

---

## Remote State Bootstrap

Before using any environment, bootstrap the remote state backend **once** per cloud:

### AWS (S3 + DynamoDB)

```bash
cd iac/state-backends
terraform init        # uses local state for bootstrap
terraform apply \
  -var="state_bucket_name=one-deploy-dash-tfstate" \
  -var="state_lock_table_name=one-deploy-dash-tflock" \
  -var="state_aws_region=us-east-1"
```

Then uncomment the `backend "s3" {}` block in each environment's `main.tf` and re-run `terraform init -migrate-state`.

### Azure Blob

```bash
cd iac/state-backends
terraform init
terraform apply \
  -var="azure_subscription_id=00000000-..." \
  -var="state_storage_account_name=onedeploydashtfstate"
```

Then uncomment the `backend "azurerm" {}` block and re-run `terraform init -migrate-state`.

### GCP (GCS)

```bash
cd iac/state-backends
terraform init
terraform apply \
  -var="gcp_project=my-gcp-project" \
  -var="terraform_sa_email=terraform@my-gcp-project.iam.gserviceaccount.com"
```

Then uncomment the `backend "gcs" {}` block and re-run `terraform init -migrate-state`.

---

## Working with Environments

### Standard workflow

```bash
# 1. Change into the target environment directory
cd iac/environments/dev     # or staging / production

# 2. Initialise (downloads providers, configures backend)
terraform init

# 3. Review what will be created/changed
terraform plan -var-file=terraform.tfvars

# 4. Apply (requires explicit approval)
terraform apply -var-file=terraform.tfvars

# 5. Destroy (use with caution in production)
terraform destroy -var-file=terraform.tfvars
```

### Workspace-per-environment (alternative)

If you prefer a single directory with Terraform workspaces instead of
separate directories, create workspaces that map to environments:

```bash
terraform workspace new dev
terraform workspace select dev
terraform apply -var-file=environments/dev/terraform.tfvars
```

The state-backend key paths include `${terraform.workspace}` to keep state isolated.

### Targeting a subset of resources

```bash
# Apply only the EKS module
terraform apply -target=module.aws_eks

# Destroy only the dev RDS instance
terraform destroy -target=module.aws_rds
```

---

## Module Calling Convention

Each module is called with the `source` path relative to the environment directory:

```hcl
module "aws_eks" {
  source = "../../../modules/aws/eks"

  cluster_name        = "my-cluster-dev"
  kubernetes_version  = "1.30"
  region              = "us-east-1"
  vpc_id              = module.aws_vpc.vpc_id
  subnet_ids          = module.aws_vpc.private_subnet_ids
  node_instance_types = ["t3.medium"]
  desired_size        = 2
  min_size            = 1
  max_size            = 4
  disk_size_gb        = 50
  environment         = "dev"
  enable_oidc         = true
  tags                = { Environment = "dev" }
}
```

All modules expose consistent `tags` (AWS/Azure) or `labels` (GCP) variables.

---

## How the Dashboard Backend Uses These Modules

The One Deployment Dashboard API runner integrates with this IaC layer in two ways:

1. **Terraform CLI wrapper** – The backend spawns `terraform` subprocesses with
   appropriate `-var` flags and environment credentials injected from the
   dashboard's secrets store. Stdout/stderr are streamed back to the UI in
   real time via Server-Sent Events.

2. **State introspection** – After `apply`, the backend calls
   `terraform output -json` to extract module outputs (cluster endpoints, ARNs,
   connection strings) and stores them in the dashboard database, making them
   available to the deployment UI without requiring direct cloud API access.

### Expected environment variables for the API runner

| Variable | Purpose |
|----------|---------|
| `TF_VAR_aws_account_id` | Injected as Terraform variable |
| `TF_VAR_azure_subscription_id` | Injected as Terraform variable |
| `TF_VAR_gcp_project` | Injected as Terraform variable |
| `AWS_PROFILE` or `AWS_ACCESS_KEY_ID` etc. | AWS provider authentication |
| `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID` | Azure provider authentication |
| `GOOGLE_APPLICATION_CREDENTIALS` or WIF config | GCP provider authentication |
| `TF_WORKSPACE` | Selects the Terraform workspace (maps to environment) |
| `TF_CLI_ARGS_init` | Optional: pass `-backend-config` overrides |

---

## Security Notes

- **Never commit secrets** to `terraform.tfvars`. Use environment variables
  (`TF_VAR_*`) or a secrets manager (AWS SSM Parameter Store / Secrets Manager,
  Azure Key Vault, GCP Secret Manager) to inject sensitive values at plan/apply time.
- RDS master passwords are managed by AWS Secrets Manager via
  `manage_master_user_password = true` – no plaintext password in state.
- GKE and EKS cluster CA certificates are marked `sensitive = true` in outputs.
- Azure Key Vault has `purge_protection_enabled = true` in staging/production.
- Production S3 state bucket enforces KMS encryption and public access block.
- IAM roles follow least-privilege; extend by attaching additional managed or
  inline policies via the `iam-role` module.

---

## Contributing

1. Add new modules under `iac/modules/<cloud>/<service>/`.
2. Every module must have `main.tf`, `variables.tf`, and `outputs.tf`.
3. Use `terraform fmt -recursive` before committing.
4. Run `terraform validate` in each changed module directory.
5. Update this README if new prerequisites or bootstrap steps are needed.
