# Infrastructure as Code – One Deployment Dashboard

Centralized multi-cloud Terraform repository for AWS, Azure, and GCP. Any
number of **environment instances** (`dev1`, `dev2`, `uat1`, `uat2`,
`staging`, `rc`, `production`, ...) can exist side by side, each sized from a
small set of reusable **tiers** and deployed as one or more **independent
regional stacks** with isolated state. A self-service GitHub Actions workflow
lets a DevOps engineer spin up (or tear down) a new environment instance on
demand — see **Creating a New Environment** below — and every instance is
wired into the same plan-on-PR / approval-gated apply-on-merge pipelines.

---

## Directory Structure

```
├── README.md
├── modules/
│   ├── aws/
│   │   ├── vpc/, eks/, ecr/, s3/, iam-role/, kms/, rds/     ← leaf modules
│   │   ├── sns-sqs/, cloudwatch/, route53/                  ← messaging / monitoring / DNS
│   │   └── region-stack/                                    ← composes all of the above for ONE region
│   ├── azure/
│   │   ├── vnet/, aks/, acr/, keyvault/, service-principal/
│   │   ├── servicebus/, monitor/, dns/
│   │   └── region-stack/
│   └── gcp/
│       ├── gke/, artifact-registry/, cloudsql/, kms/, gcs/
│       ├── pubsub/, monitoring/, cloud-dns/
│       └── region-stack/
├── environments/
│   └── <instance>/{aws,azure,gcp}/<region>/   ← one instance per entry in .github/environments.json
│       (e.g. dev/, staging/, production/ ship out of the box; dev1/, uat1/,
│        uat2/, rc/, ... get created the same way, by anyone, on demand)
├── state-backends/            ← one-time bootstrap of the shared remote state backends
├── scripts/
│   ├── generate-environment.cjs  ← scaffold a brand-new environment instance from a tier
│   ├── new-region.sh             ← add one more region to an EXISTING instance (bash)
│   └── new-region.ps1            ← same, PowerShell
└── .github/
    ├── environments.json      ← single source of truth: which environment INSTANCES exist
    ├── tiers.json              ← reusable sizing profiles (dev/uat/staging/rc/production)
    ├── workflows/
    │   ├── terraform-plan.yml       (PR: fmt/validate/tflint/tfsec/plan, posts plan as PR comment)
    │   ├── terraform-apply.yml      (push to main: apply, gated by GitHub Environment approval)
    │   ├── terraform-drift.yml      (nightly: plan-only, opens an issue on drift)
    │   ├── create-environment.yml   (self-service: scaffold a new instance, opens a PR)
    │   └── destroy-environment.yml  (self-service: tear an instance down, then remove it)
    └── PULL_REQUEST_TEMPLATE.md
```

### Why region is a directory, not a variable

Terraform's AWS provider is region-bound at the provider block, and `for_each`
cannot select a different provider alias per iteration — so one root module
can't cleanly fan a single region *list* out across providers. Instead, each
region gets its **own root directory** with its own (single, non-aliased)
provider and its own state file, composing a shared `region-stack` module.
Adding a region is adding a directory, not fighting Terraform's provider
model. See `scripts/new-region.sh` / `.ps1` below.

---

## Prerequisites

| Tool | Minimum version | Notes |
|------|-----------------|-------|
| Terraform | 1.9.0 | `terraform version` |
| AWS CLI | 2.x | Required for AWS provider auth |
| Azure CLI | 2.x | Required for AzureRM/AzureAD providers |
| gcloud CLI | 470+ | Required for Google provider auth |
| kubectl | 1.29+ | Optional, for post-deploy cluster access |
| tflint | 0.53+ | Optional locally; runs in CI |
| tfsec | latest | Optional locally; runs in CI |

### Provider versions (pinned in every region root's `main.tf`)

| Provider | Version constraint |
|----------|--------------------|
| `hashicorp/aws` | `>= 5.0` |
| `hashicorp/azurerm` | `~> 4.0` |
| `hashicorp/azuread` | `>= 2.47` |
| `hashicorp/google` | `~> 6.0` |
| `hashicorp/tls` | `>= 4.0` |
| `hashicorp/time` | `>= 0.11` |
| `hashicorp/random` | `>= 3.5` |

---

## Authentication (local CLI use)

### AWS
```bash
export AWS_PROFILE=my-profile
# or
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...        # if using assumed roles
```

### Azure
```bash
az login
az account set --subscription "00000000-0000-0000-0000-000000000000"
```

### GCP
```bash
gcloud auth application-default login
gcloud config set project MY_PROJECT_ID
```

CI uses OIDC federation instead of any of the above — see **CI/CD Pipelines** below.

---

## Remote State Bootstrap

All regions of all environments share the **same** three backends (one per
cloud); only the state `key`/`prefix` differs per region. Bootstrap each
backend once:

### AWS (S3 + DynamoDB)
```bash
cd state-backends
terraform init
terraform apply \
  -var="state_bucket_name=one-deploy-dash-tfstate" \
  -var="state_lock_table_name=one-deploy-dash-tflock" \
  -var="state_aws_region=us-east-1"
```

### Azure Blob
```bash
cd state-backends
terraform init
terraform apply \
  -var="azure_subscription_id=00000000-..." \
  -var="state_storage_account_name=onedeploydashtfstate"
```

### GCP (GCS)
```bash
cd state-backends
terraform init
terraform apply \
  -var="gcp_project=my-gcp-project" \
  -var="terraform_sa_email=terraform@my-gcp-project.iam.gserviceaccount.com"
```

The default GCS bucket name is `one-deploy-dash-tfstate-${gcp_project}` — if
you bootstrap against your own GCP project, update the `bucket` value in
every `environments/*/gcp/*/backend.hcl` (they ship with a `CHANGEME`
placeholder) to match.

---

## Working with a Region

Every region directory (`environments/<env>/<cloud>/<region>/`) is a
self-contained Terraform root. Its `terraform { backend "<cloud>" {} }` block
is intentionally empty — concrete backend values live in that directory's
`backend.hcl` and are supplied at init time (backend blocks can't reference
variables, and the GCS bucket name is project-specific):

```bash
cd environments/dev/aws/us-east-1

terraform init -backend-config=backend.hcl
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
terraform destroy -var-file=terraform.tfvars   # use with caution
```

Fill in the placeholder values in each region's `terraform.tfvars` first
(`aws_account_id`, `azure_subscription_id`, `gcp_project` — marked `# replace`
in every file) — never commit real account/subscription IDs beyond these
placeholders; inject real values via `TF_VAR_*` environment variables or your
secrets manager instead.

### Targeting a subset of resources
```bash
terraform apply -target=module.stack.module.eks     # AWS example
terraform destroy -target=module.stack.module.rds
```

---

## Environments & Tiers

Two config files, both under `.github/`, split "which environments exist"
from "how big each one is":

- **`environments.json`** — keyed by environment *instance* name (`dev1`,
  `uat2`, `production`, ...). Each entry: `{ tier, aws: [...], azure: [...],
  gcp: [...] }`, where each region entry is `{ region, region_index }`.
- **`tiers.json`** — one reusable sizing profile per tier:

  | Tier | Regions/cloud (typical) | HA | Notes |
  |------|--------------------------|----|-------|
  | `dev` | 1, cost-optimized | No | day-to-day development |
  | `uat` | 1–2 | No | real but cheap user-acceptance testing |
  | `staging` | 2, mid-tier | Yes | pre-prod validation |
  | `rc` | 2, near-prod | Yes | release-candidate soak testing, `SOFTWARE`-protected KMS |
  | `production` | 2, full HA | Yes | private endpoints, `HSM`-protected KMS, geo-replication |

  Any number of instances can share one tier — `dev1` and `dev2` both use
  the `dev` profile but are fully isolated deployments (separate state,
  separate cloud resources). Sizing knobs map 1:1 onto
  `modules/<cloud>/region-stack/variables.tf`.

`region_index` is a **globally unique** integer (across the whole
`environments.json` file, not per cloud or per environment) used to derive a
non-overlapping CIDR block for that region's VPC/VNet via
`cidrsubnet(supernet, 8, region_index)` (GCP's GKE master range uses the same
trick against a `/12`). `scripts/generate-environment.cjs` allocates the next
free index automatically — never hand-assign one.

### Creating a new environment (self-service)

Run the **Create Environment** workflow from the Actions tab (`workflow_dispatch`):

| Input | Example |
|-------|---------|
| `environment_name` | `uat2` |
| `tier` | `uat` |
| `aws_regions` | `us-east-1` |
| `azure_regions` | *(blank to skip Azure)* |
| `gcp_regions` | `us-central1` |

It scaffolds `environments/uat2/{aws,gcp}/<region>/`, registers the instance
in `environments.json`, and opens a PR — which immediately triggers
`terraform-plan` against the new cells so the reviewer sees a real plan
before merging. Merging doesn't apply anything by itself; the next push to
`main` does, gated by the `uat` tier's normal approval rules (see
**CI/CD Pipelines** below).

The same scaffolding also runs locally for a dry run:
```bash
node scripts/generate-environment.cjs uat2 uat --aws=us-east-1 --gcp=us-central1 --dry-run
```

### Destroying an environment (self-service)

Run the **Destroy Environment** workflow, typing the environment name twice
(`environment_name` and `confirm_name` must match — this destroys real cloud
resources and cannot be undone). It runs `terraform destroy` across every
region the instance has, then removes `environments/<name>/` and its
`environments.json` entry, committed directly to `main`. Gated by the same
tier-based GitHub Environment as apply — see the comment at the top of
`destroy-environment.yml` for why a universal cross-tier approval gate
wasn't used (a GitHub Actions job can only bind to one Environment, and that
Environment is also where the cloud credentials come from).

### Adding a region to an existing environment

For adding one more region to an environment that already exists (rather
than creating a whole new instance):

1. Run the scaffold script, picking the next unused `region_index` from
   `.github/environments.json`:
   ```bash
   scripts/new-region.sh production aws ap-south-1 5
   # or on Windows:
   scripts/new-region.ps1 -Environment production -Cloud aws -NewRegion ap-south-1 -RegionIndex 5
   ```
2. Add the new region to `.github/environments.json` under the matching
   instance's `aws`/`azure`/`gcp` array, with the **same** `region_index`.
3. Review the generated `terraform.tfvars`/`backend.hcl` (region names
   sometimes appear inside other strings the script's find/replace won't
   catch), then `terraform init -backend-config=backend.hcl && terraform plan`.
4. Open a PR — the `terraform-plan` pipeline picks up the new cell
   automatically from `environments.json`.

### Adding a new tier

Add an entry to `.github/tiers.json` (sizing values for `aws`/`azure`/`gcp`,
matching `modules/*/region-stack/variables.tf`), then add it to the `tier`
`options` list in `.github/workflows/create-environment.yml` (a
`workflow_dispatch` choice input can't read a dynamic list, so this one spot
needs a manual edit alongside the JSON).

### Adding a new service module

1. Create `modules/<cloud>/<service>/{main,variables,outputs}.tf` following
   the conventions of an existing module in that cloud (banner comment,
   `tags`/`labels` variable, `description` on every variable, resources named
   `this`).
2. Wire it into `modules/<cloud>/region-stack/{main,variables,outputs}.tf`
   (gate it behind an `enable_<service>` bool + `count` if it shouldn't exist
   in every tier, following the pattern already used for messaging/
   monitoring/DNS).
3. Every environment/region that calls that region-stack picks up the new
   service on its next `terraform apply` — no environment file changes
   needed unless you want to override a non-default value.

---

## CI/CD Pipelines

Driven entirely by `.github/environments.json` — a `generate-matrix` job in
each workflow flattens it into one `{environment, tier, cloud, region, path}`
cell per job. Every gate (`environment:` in the workflow YAML) keys off
**`tier`**, not the instance name — `dev1` and `dev2` both authenticate and
get approval-gated through the shared `dev` GitHub Environment, so creating
a new instance never needs new secrets provisioned. Adding a region to an
existing instance is a one-line JSON edit; creating a whole new instance is
the **Create Environment** workflow (see above) — neither needs a workflow
change.

- **`terraform-plan.yml`** — on every PR touching `modules/**`,
  `environments/**`, or the config files: repo-wide `fmt`/one cell each of
  `validate`/`tflint`/`tfsec`, then `terraform plan`, posted as a PR comment
  (one comment per cell, updated in place on subsequent pushes).
- **`terraform-apply.yml`** — on push to `main`: re-plans and applies each
  cell **sequentially** (not in parallel — a simultaneous full-matrix apply
  is too large a blast radius for one push). `dev`-tier cells run straight
  through; every other tier pauses for a required reviewer.
- **`terraform-drift.yml`** — nightly, plan-only against every cell; opens or
  updates a `terraform-drift`-labeled GitHub issue when a plan shows
  unapplied changes.
- **`create-environment.yml`** / **`destroy-environment.yml`** — self-service
  instance lifecycle, see **Environments & Tiers** above.

### One-time GitHub setup (manual — not something this repo can configure for itself)

1. **GitHub Environments** (Settings → Environments), one pair per **tier**
   (not per instance — this is what makes self-service creation practical):
   `dev`, `uat`, `uat-plan`, `staging`, `staging-plan`, `rc`, `rc-plan`,
   `production`, `production-plan`. Add required reviewers to every tier
   except `dev` — the `*-plan` variants exist so PR-triggered plans and the
   nightly drift check aren't blocked on the same approval that gates a real
   apply (ideally scope the `*-plan` environments to a **read-only** cloud
   credential).
2. **Secrets**, per GitHub Environment above:
   - AWS: `AWS_ROLE_ARN` — an IAM role trusting GitHub's OIDC provider.
   - Azure: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` — a
     federated-credential App Registration.
   - GCP: `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT` — Workload
     Identity Federation, no service account keys.
   
   None of these are secrets a Terraform-in-this-repo run can create for
   itself — each requires real cloud console/CLI access to set up the OIDC
   trust relationship first. Since every instance of a tier shares that
   tier's credentials, most setups only ever provision these once per tier,
   not once per environment instance.
3. Branch protection on `main`: require the `terraform-plan` check before
   merge.

---

## Security Notes

- **Never commit real secrets.** `terraform.tfvars` files in this repo ship
  with clearly marked placeholder account/subscription/project IDs — replace
  them locally or inject real values via `TF_VAR_*` / a secrets manager, and
  keep the replacement out of version control.
- RDS master passwords are managed by AWS Secrets Manager
  (`manage_master_user_password = true`) — no plaintext password in state.
- GKE and EKS cluster CA certificates and endpoints are `sensitive = true` outputs.
- Azure Key Vault has `purge_protection_enabled = true` in staging/production.
- Production S3 state bucket enforces KMS encryption and a public access block.
- CI never uses long-lived cloud credentials — every workflow authenticates
  via OIDC (`aws-actions/configure-aws-credentials`, `azure/login`,
  `google-github-actions/auth`).
- IAM roles/service accounts follow least-privilege; extend by attaching
  additional policies via the `iam-role` (AWS) or `service-principal` (Azure)
  modules rather than widening an existing role.

---

## Contributing

1. Add new leaf modules under `modules/<cloud>/<service>/`; wire them into
   the corresponding `region-stack` module (see "Adding a new service module"
   above).
2. Every module must have `main.tf`, `variables.tf`, and `outputs.tf`, with a
   `description` on every variable and output.
3. Run `terraform fmt -recursive` and `terraform validate` (per changed root)
   before committing — the `terraform-plan` pipeline enforces both.
4. New environment instances go through the **Create Environment** workflow;
   new regions on an existing instance go through `scripts/new-region.sh`/
   `.ps1` plus an `environments.json` update — see **Environments & Tiers**
   above.
5. Update this README when prerequisites, bootstrap steps, or the pipeline
   setup change.
