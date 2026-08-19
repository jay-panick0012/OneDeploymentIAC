#!/usr/bin/env node
/**
 * scripts/generate-environment.cjs
 *
 * Scaffolds a brand-new environment instance (e.g. "uat2") from a reusable
 * sizing tier (.github/tiers.json), across whichever cloud(s)/region(s) are
 * requested, and registers it in .github/environments.json. Used by
 * .github/workflows/create-environment.yml, and runnable locally the same
 * way for a dry run.
 *
 * .cjs extension is deliberate: this repo may sit under a parent directory
 * whose package.json sets "type": "module", which would otherwise force
 * Node to interpret a plain .js file as an ES module.
 *
 * Usage:
 *   node scripts/generate-environment.cjs <name> <tier> \
 *     [--aws=region1,region2] [--azure=region1,region2] [--gcp=region1,region2] \
 *     [--dry-run]
 *
 * Example:
 *   node scripts/generate-environment.cjs uat2 uat --aws=us-east-1 --gcp=us-central1
 */

"use strict";

const fs = require("fs");
const path = require("path");

const REPO_ROOT = path.resolve(__dirname, "..");
const ENVIRONMENTS_PATH = path.join(REPO_ROOT, ".github", "environments.json");
const TIERS_PATH = path.join(REPO_ROOT, ".github", "tiers.json");

function fail(message) {
  console.error(`error: ${message}`);
  process.exit(1);
}

function loadJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

// Serializes environments.json keeping each region entry on one line (the
// hand-authored style) instead of letting JSON.stringify explode every
// {region, region_index} object across three lines -- keeps future PR diffs
// to the single line that actually changed.
function serializeEnvironments(environments) {
  const keys = Object.keys(environments);
  const lines = ["{"];
  keys.forEach((key, i) => {
    const trailingComma = i === keys.length - 1 ? "" : ",";
    if (key === "$comment") {
      lines.push(`  "$comment": ${JSON.stringify(environments[key])}${trailingComma}`);
      return;
    }
    const env = environments[key];
    const clouds = ["aws", "azure", "gcp"].filter((c) => env[c] && env[c].length);
    lines.push(`  ${JSON.stringify(key)}: {`);
    lines.push(`    "tier": ${JSON.stringify(env.tier)}${clouds.length ? "," : ""}`);
    clouds.forEach((cloud, ci) => {
      const cloudTrailingComma = ci === clouds.length - 1 ? "" : ",";
      lines.push(`    ${JSON.stringify(cloud)}: [`);
      env[cloud].forEach((entry, ei) => {
        const entryTrailingComma = ei === env[cloud].length - 1 ? "" : ",";
        lines.push(
          `      { "region": ${JSON.stringify(entry.region)}, "region_index": ${entry.region_index} }${entryTrailingComma}`
        );
      });
      lines.push(`    ]${cloudTrailingComma}`);
    });
    lines.push(`  }${trailingComma}`);
  });
  lines.push("}");
  return lines.join("\n") + "\n";
}

function parseArgs(argv) {
  const positional = [];
  const flags = {};
  for (const arg of argv) {
    if (arg.startsWith("--")) {
      const [key, value] = arg.slice(2).split(/=(.*)/s);
      flags[key] = value === undefined ? true : value;
    } else {
      positional.push(arg);
    }
  }
  return { positional, flags };
}

function splitRegions(value) {
  if (!value || value === true) return [];
  return value
    .split(",")
    .map((r) => r.trim())
    .filter(Boolean);
}

// ---------------------------------------------------------------------------
// Terraform literal formatting
// ---------------------------------------------------------------------------

function raw(expr) {
  return { __raw: true, value: expr };
}

function tfLiteral(value) {
  if (value && value.__raw) return value.value;
  if (typeof value === "string") return JSON.stringify(value);
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  if (Array.isArray(value)) {
    return "[" + value.map((v) => (typeof v === "string" ? JSON.stringify(v) : String(v))).join(", ") + "]";
  }
  throw new Error(`unsupported terraform literal: ${JSON.stringify(value)}`);
}

// Renders one alignment group: array of [key, value] pairs, `=` aligned to
// the longest key, matching this repo's terraform fmt style.
function block(pairs, indent = "  ") {
  const width = Math.max(...pairs.map(([k]) => k.length));
  return pairs.map(([k, v]) => `${indent}${k.padEnd(width)} = ${tfLiteral(v)}`).join("\n");
}

function banner(lines) {
  const rule = "#".repeat(79);
  return [rule, ...lines.map((l) => `# ${l}`), rule].join("\n");
}

// ---------------------------------------------------------------------------
// Per-cloud file generators
// ---------------------------------------------------------------------------

function writeFile(filePath, content) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, content.endsWith("\n") ? content : content + "\n", "utf8");
}

function genAws(dir, name, tierName, tier, region, regionIndex) {
  const t = tier.aws;
  const mainTf =
    banner([
      `${name} Environment – AWS – ${region} – main.tf`,
      `Tier: ${tierName} — ${tier.description}`,
    ]) +
    `

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  environment = "${name}"
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = var.owner
    Region      = var.region
  }
}

###############################################################################
# AWS – Region Stack
###############################################################################

module "stack" {
  source = "../../../../modules/aws/region-stack"

${block([
  ["project_name", raw("var.project_name")],
  ["environment", raw("local.environment")],
  ["region", raw("var.region")],
  ["region_index", raw("var.region_index")],
  ["aws_account_id", raw("var.aws_account_id")],
])}

${block([
  ["availability_zone_suffixes", t.availability_zone_suffixes],
  ["single_nat_gateway", t.single_nat_gateway],
  ["kms_deletion_window_days", t.kms_deletion_window_days],
  ["s3_glacier_transition_days", t.s3_glacier_transition_days],
  ["ecr_immutable_tags", t.ecr_immutable_tags],
  ["ecr_retain_image_count", t.ecr_retain_image_count],
])}

${block([
  ["kubernetes_version", raw("var.kubernetes_version")],
  ["eks_node_instance_types", t.eks_node_instance_types],
  ["eks_desired_size", t.eks_desired_size],
  ["eks_min_size", t.eks_min_size],
  ["eks_max_size", t.eks_max_size],
  ["eks_disk_size_gb", t.eks_disk_size_gb],
  ["eks_private_endpoint", t.eks_private_endpoint],
])}

${block([
  ["rds_instance_class", t.rds_instance_class],
  ["rds_allocated_storage", t.rds_allocated_storage],
  ["rds_multi_az", t.rds_multi_az],
  ["rds_backup_retention_period", t.rds_backup_retention_period],
])}

${block([["tags", raw("local.common_tags")]])}
}
`;

  const variablesTf =
    banner([`${name} Environment – AWS – ${region} – variables.tf`]) +
    `

variable "project_name" {
  description = "Short name of the project (used as prefix for resource names)."
  type        = string
}

variable "owner" {
  description = "Team or individual responsible for this environment."
  type        = string
  default     = "platform-team"
}

variable "region" {
  description = "AWS region for this stack."
  type        = string
  default     = "${region}"
}

variable "region_index" {
  description = "Zero-based index of this region within the global CIDR allocation sequence recorded in .github/environments.json. Must be unique across that entire file."
  type        = number
  default     = ${regionIndex}
}

variable "aws_account_id" {
  description = "AWS account ID (used to build a globally-unique S3 bucket name)."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.30"
}
`;

  const tfvars =
    banner([
      `${name} Environment – AWS – ${region} – terraform.tfvars`,
      `Concrete values for the ${name}/aws/${region} stack.`,
    ]) +
    `

${block(
      [
        ["project_name", "one-deploy-dash"],
        ["owner", "platform-team"],
        ["aws_account_id", raw('"123456789012"  # replace with real account ID')],
        ["kubernetes_version", "1.30"],
      ],
      ""
    )}
`;

  const backendHcl =
    banner([
      `${name} Environment – AWS – ${region} – backend.hcl`,
      "Usage: terraform init -backend-config=backend.hcl",
    ]) +
    `

bucket         = "one-deploy-dash-tfstate"
key            = "environments/${name}/aws/${region}/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "one-deploy-dash-tflock"
encrypt        = true
`;

  writeFile(path.join(dir, "main.tf"), mainTf);
  writeFile(path.join(dir, "variables.tf"), variablesTf);
  writeFile(path.join(dir, "terraform.tfvars"), tfvars);
  writeFile(path.join(dir, "backend.hcl"), backendHcl);
}

function genAzure(dir, name, tierName, tier, region, regionIndex) {
  const t = tier.azure;
  const mainTf =
    banner([
      `${name} Environment – Azure – ${region} – main.tf`,
      `Tier: ${tierName} — ${tier.description}`,
    ]) +
    `

terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.azure_subscription_id
}

locals {
  environment = "${name}"
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}

###############################################################################
# Azure – Region Stack
###############################################################################

module "stack" {
  source = "../../../../modules/azure/region-stack"

${block([
  ["project_name", raw("var.project_name")],
  ["environment", raw("local.environment")],
  ["location", raw("var.location")],
  ["region_index", raw("var.region_index")],
])}

${block([
  ["subnet_names", t.subnet_names],
  ["acr_sku", t.acr_sku],
  ["keyvault_sku", t.keyvault_sku],
  ["keyvault_soft_delete_days", t.keyvault_soft_delete_days],
  ["keyvault_purge_protection", t.keyvault_purge_protection],
])}

${block([
  ["aks_kubernetes_version", raw("var.kubernetes_version")],
  ["aks_vm_size", t.aks_vm_size],
  ["aks_node_count", t.aks_node_count],
  ["aks_enable_auto_scaling", t.aks_enable_auto_scaling],
  ["aks_min_count", t.aks_min_count],
  ["aks_max_count", t.aks_max_count],
])}

${block([["alert_email", raw("var.alert_email")]])}

${block([["tags", raw("local.common_tags")]])}
}
`;

  const variablesTf =
    banner([`${name} Environment – Azure – ${region} – variables.tf`]) +
    `

variable "project_name" {
  description = "Short name of the project (used as prefix for resource names)."
  type        = string
}

variable "owner" {
  description = "Team or individual responsible for this environment."
  type        = string
  default     = "platform-team"
}

variable "azure_subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "location" {
  description = "Azure region for this stack."
  type        = string
  default     = "${region}"
}

variable "region_index" {
  description = "Zero-based index of this region within the global CIDR allocation sequence recorded in .github/environments.json. Must be unique across that entire file."
  type        = number
  default     = ${regionIndex}
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster."
  type        = string
  default     = "1.30"
}

variable "alert_email" {
  description = "Email address to receive monitoring alerts."
  type        = string
  default     = "platform-team@example.com"
}
`;

  const tfvars =
    banner([
      `${name} Environment – Azure – ${region} – terraform.tfvars`,
      `Concrete values for the ${name}/azure/${region} stack.`,
    ]) +
    `

project_name          = "one-deploy-dash"
owner                 = "platform-team"
azure_subscription_id = "00000000-0000-0000-0000-000000000000"  # replace
location              = "${region}"
kubernetes_version    = "1.30"
alert_email           = "platform-team@example.com"
`;

  const backendHcl =
    banner([
      `${name} Environment – Azure – ${region} – backend.hcl`,
      "Usage: terraform init -backend-config=backend.hcl",
    ]) +
    `

resource_group_name  = "one-deploy-dash-tfstate-rg"
storage_account_name = "onedeploydashtfstate"
container_name       = "tfstate"
key                  = "environments/${name}/azure/${region}/terraform.tfstate"
`;

  writeFile(path.join(dir, "main.tf"), mainTf);
  writeFile(path.join(dir, "variables.tf"), variablesTf);
  writeFile(path.join(dir, "terraform.tfvars"), tfvars);
  writeFile(path.join(dir, "backend.hcl"), backendHcl);
}

function genGcp(dir, name, tierName, tier, region, regionIndex) {
  const t = tier.gcp;
  const mainTf =
    banner([
      `${name} Environment – GCP – ${region} – main.tf`,
      `Tier: ${tierName} — ${tier.description}`,
    ]) +
    `

terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {}
}

provider "google" {
  project = var.gcp_project
  region  = var.region
}

locals {
  environment = "${name}"
  common_labels = {
    environment = local.environment
    project     = replace(lower(var.project_name), " ", "-")
    managed_by  = "terraform"
  }
}

###############################################################################
# GCP – Region Stack
###############################################################################

module "stack" {
  source = "../../../../modules/gcp/region-stack"

${block([
  ["project_name", raw("var.project_name")],
  ["environment", raw("local.environment")],
  ["gcp_project", raw("var.gcp_project")],
  ["region", raw("var.region")],
  ["region_index", raw("var.region_index")],
])}

${block([
  ["gke_mode", t.gke_mode],
  ["gke_node_count", t.gke_node_count],
  ["gke_machine_type", t.gke_machine_type],
  ["gke_release_channel", t.gke_release_channel],
  ["gke_enable_private_cluster", t.gke_enable_private_cluster],
])}

${block([
  ["cloudsql_tier", t.cloudsql_tier],
  ["cloudsql_high_availability", t.cloudsql_high_availability],
  ["cloudsql_disk_size_gb", t.cloudsql_disk_size_gb],
])}

${block([
  ["kms_protection_level", t.kms_protection_level],
  ["notification_email", raw("var.notification_email")],
])}

${block([["labels", raw("local.common_labels")]])}
}
`;

  const variablesTf =
    banner([`${name} Environment – GCP – ${region} – variables.tf`]) +
    `

variable "project_name" {
  description = "Short name of the project (used as prefix for resource names)."
  type        = string
}

variable "gcp_project" {
  description = "GCP project ID this stack is deployed into."
  type        = string
}

variable "region" {
  description = "GCP region for this stack."
  type        = string
  default     = "${region}"
}

variable "region_index" {
  description = "Zero-based index of this region within the global CIDR allocation sequence recorded in .github/environments.json. Must be unique across that entire file."
  type        = number
  default     = ${regionIndex}
}

variable "notification_email" {
  description = "Email address to receive monitoring alerts."
  type        = string
  default     = "platform-team@example.com"
}
`;

  const tfvars =
    banner([
      `${name} Environment – GCP – ${region} – terraform.tfvars`,
      `Concrete values for the ${name}/gcp/${region} stack.`,
    ]) +
    `

project_name       = "one-deploy-dash"
gcp_project        = "my-gcp-project-${name}"  # replace with real project ID
region             = "${region}"
notification_email = "platform-team@example.com"
`;

  const backendHcl =
    banner([
      `${name} Environment – GCP – ${region} – backend.hcl`,
      "Usage: terraform init -backend-config=backend.hcl",
    ]) +
    `

bucket = "one-deploy-dash-tfstate-CHANGEME"  # replace CHANGEME with your real GCP project ID
prefix = "environments/${name}/gcp/${region}"
`;

  writeFile(path.join(dir, "main.tf"), mainTf);
  writeFile(path.join(dir, "variables.tf"), variablesTf);
  writeFile(path.join(dir, "terraform.tfvars"), tfvars);
  writeFile(path.join(dir, "backend.hcl"), backendHcl);
}

const GENERATORS = { aws: genAws, azure: genAzure, gcp: genGcp };

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main() {
  const { positional, flags } = parseArgs(process.argv.slice(2));
  const [name, tierName] = positional;

  if (!name || !tierName) {
    fail('usage: generate-environment.cjs <name> <tier> [--aws=r1,r2] [--azure=r1,r2] [--gcp=r1,r2] [--dry-run]');
  }
  if (!/^[a-z][a-z0-9-]*$/.test(name)) {
    fail(`environment name "${name}" must be lowercase alphanumeric/hyphen, starting with a letter`);
  }

  const environments = loadJson(ENVIRONMENTS_PATH);
  const tiers = loadJson(TIERS_PATH);

  if (Object.prototype.hasOwnProperty.call(environments, name)) {
    fail(`environment "${name}" already exists in ${path.relative(REPO_ROOT, ENVIRONMENTS_PATH)}`);
  }
  if (!Object.prototype.hasOwnProperty.call(tiers, tierName) || tierName.startsWith("$")) {
    const known = Object.keys(tiers).filter((k) => !k.startsWith("$"));
    fail(`unknown tier "${tierName}" -- known tiers: ${known.join(", ")}`);
  }

  const requested = {
    aws: splitRegions(flags.aws),
    azure: splitRegions(flags.azure),
    gcp: splitRegions(flags.gcp),
  };
  const totalRegions = requested.aws.length + requested.azure.length + requested.gcp.length;
  if (totalRegions === 0) {
    fail("at least one region is required across --aws / --azure / --gcp");
  }

  // region_index must be unique across the ENTIRE environments.json file.
  let nextIndex = 0;
  for (const env of Object.values(environments)) {
    for (const cloud of ["aws", "azure", "gcp"]) {
      for (const entry of env[cloud] || []) {
        nextIndex = Math.max(nextIndex, entry.region_index + 1);
      }
    }
  }

  const tier = tiers[tierName];
  const dryRun = Boolean(flags["dry-run"]);
  const newEntry = { tier: tierName, aws: [], azure: [], gcp: [] };
  const created = [];

  for (const cloud of ["aws", "azure", "gcp"]) {
    for (const region of requested[cloud]) {
      const regionIndex = nextIndex++;
      const dir = path.join(REPO_ROOT, "environments", name, cloud, region);
      if (fs.existsSync(dir)) {
        fail(`${path.relative(REPO_ROOT, dir)} already exists`);
      }
      if (!dryRun) {
        GENERATORS[cloud](dir, name, tierName, tier, region, regionIndex);
      }
      newEntry[cloud].push({ region, region_index: regionIndex });
      created.push(path.relative(REPO_ROOT, dir));
    }
  }
  for (const cloud of ["aws", "azure", "gcp"]) {
    if (newEntry[cloud].length === 0) delete newEntry[cloud];
  }

  if (!dryRun) {
    environments[name] = newEntry;
    fs.writeFileSync(ENVIRONMENTS_PATH, serializeEnvironments(environments), "utf8");
  }

  console.log(`${dryRun ? "[dry-run] would create" : "Created"} environment "${name}" (tier: ${tierName}):`);
  for (const dir of created) console.log(`  - ${dir}/`);
  if (!dryRun) {
    console.log(`Updated ${path.relative(REPO_ROOT, ENVIRONMENTS_PATH)}.`);
    console.log("\nNext steps:");
    console.log("  1. Fill in the real account/subscription/project IDs in each new terraform.tfvars (marked '# replace').");
    console.log("  2. Review each backend.hcl, then: terraform init -backend-config=backend.hcl && terraform plan -var-file=terraform.tfvars");
    console.log("  3. Commit, push, and open a PR -- the terraform-plan pipeline will pick up the new cells automatically.");
  }
}

if (require.main === module) {
  main();
}

module.exports = { serializeEnvironments, ENVIRONMENTS_PATH, TIERS_PATH };
