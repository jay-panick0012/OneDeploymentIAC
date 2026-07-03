###############################################################################
# Production Environment – main.tf
# Full HA configuration: multi-AZ NAT, large instances, HA databases,
# private endpoints, immutable image tags, Premium ACR with geo-replication.
###############################################################################

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.47"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.11"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
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

provider "azuread" {}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

locals {
  environment = "production"
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = var.owner
    Criticality = "high"
  }
  common_labels = {
    environment = local.environment
    project     = replace(lower(var.project_name), " ", "-")
    managed_by  = "terraform"
    criticality = "high"
  }
}

###############################################################################
# AWS – VPC (3 AZs, NAT per AZ)
###############################################################################

module "aws_vpc" {
  source = "../../../modules/aws/vpc"

  vpc_name             = "${var.project_name}-${local.environment}"
  cidr_block           = "10.12.0.0/16"
  public_subnet_cidrs  = ["10.12.1.0/24", "10.12.2.0/24", "10.12.3.0/24"]
  private_subnet_cidrs = ["10.12.11.0/24", "10.12.12.0/24", "10.12.13.0/24"]
  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  single_nat_gateway   = false

  tags = local.common_tags
}

###############################################################################
# AWS – KMS (HSM-backed via higher deletion window)
###############################################################################

module "aws_kms" {
  source = "../../../modules/aws/kms"

  key_alias            = "${var.project_name}-${local.environment}"
  key_usage            = "ENCRYPT_DECRYPT"
  rotation_enabled     = true
  deletion_window_days = 30  # production: max retention

  tags = local.common_tags
}

###############################################################################
# AWS – S3
###############################################################################

module "aws_s3_artifacts" {
  source = "../../../modules/aws/s3"

  bucket_name             = "${var.project_name}-${local.environment}-artifacts-${var.aws_account_id}"
  versioning_enabled      = true
  sse_algorithm           = "aws:kms"
  kms_key_id              = module.aws_kms.key_arn
  glacier_transition_days = 90

  tags = local.common_tags
}

###############################################################################
# AWS – ECR (immutable)
###############################################################################

module "aws_ecr" {
  source = "../../../modules/aws/ecr"

  repository_name    = "${var.project_name}-${local.environment}"
  scan_on_push       = true
  immutable_tags     = true
  retain_image_count = 30

  tags = local.common_tags
}

###############################################################################
# AWS – EKS (private endpoint, larger nodes)
###############################################################################

module "aws_eks" {
  source = "../../../modules/aws/eks"

  cluster_name        = "${var.project_name}-${local.environment}"
  kubernetes_version  = var.kubernetes_version
  region              = var.aws_region
  vpc_id              = module.aws_vpc.vpc_id
  subnet_ids          = module.aws_vpc.private_subnet_ids
  node_instance_types = ["m6i.xlarge"]
  desired_size        = 4
  min_size            = 3
  max_size            = 12
  disk_size_gb        = 100
  environment         = local.environment
  private_endpoint    = true
  enable_oidc         = true

  tags = local.common_tags
}

###############################################################################
# AWS – IAM Role (example: for a Lambda / pipeline execution role)
###############################################################################

module "aws_pipeline_role" {
  source = "../../../modules/aws/iam-role"

  role_name       = "${var.project_name}-${local.environment}-pipeline-role"
  trusted_service = "lambda.amazonaws.com"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
  ]

  tags = local.common_tags
}

###############################################################################
# AWS – RDS (Multi-AZ, r6g large)
###############################################################################

module "aws_rds" {
  source = "../../../modules/aws/rds"

  identifier              = "${var.project_name}-${local.environment}"
  engine                  = "postgres"
  engine_version          = "16.2"
  instance_class          = "db.r6g.xlarge"
  allocated_storage       = 100
  db_name                 = replace(var.project_name, "-", "_")
  username                = "dbadmin"
  multi_az                = true
  backup_retention_period = 14
  subnet_ids              = module.aws_vpc.private_subnet_ids
  vpc_security_group_ids  = []

  tags = local.common_tags
}

###############################################################################
# Azure – VNet
###############################################################################

module "azure_vnet" {
  source = "../../../modules/azure/vnet"

  vnet_name           = "${var.project_name}-${local.environment}-vnet"
  resource_group_name = "${var.project_name}-${local.environment}-rg"
  location            = var.azure_location
  address_space       = ["10.22.0.0/16"]

  subnets = [
    {
      name           = "aks-nodes"
      address_prefix = "10.22.1.0/23"
    },
    {
      name           = "data"
      address_prefix = "10.22.4.0/24"
    },
    {
      name           = "services"
      address_prefix = "10.22.5.0/24"
    },
    {
      name           = "management"
      address_prefix = "10.22.6.0/24"
    },
  ]

  tags = local.common_tags
}

###############################################################################
# Azure – ACR (Premium with geo-replication)
###############################################################################

module "azure_acr" {
  source = "../../../modules/azure/acr"

  registry_name       = "${replace(var.project_name, "-", "")}${local.environment}acr"
  resource_group_name = "${var.project_name}-${local.environment}-rg"
  location            = var.azure_location
  sku                 = "Premium"
  admin_enabled       = false
  georeplications = [
    {
      location                = "westus2"
      zone_redundancy_enabled = true
    },
  ]

  tags = local.common_tags

  depends_on = [module.azure_vnet]
}

###############################################################################
# Azure – Key Vault (Premium SKU for HSM-backed keys)
###############################################################################

module "azure_keyvault" {
  source = "../../../modules/azure/keyvault"

  vault_name          = "${replace(var.project_name, "-", "")}${local.environment}kv"
  resource_group_name = "${var.project_name}-${local.environment}-rg"
  location            = var.azure_location
  sku                 = "premium"
  soft_delete_days    = 90
  purge_protection    = true

  tags = local.common_tags

  depends_on = [module.azure_vnet]
}

###############################################################################
# Azure – AKS (autoscaling, larger VMs)
###############################################################################

module "azure_aks" {
  source = "../../../modules/azure/aks"

  cluster_name        = "${var.project_name}-${local.environment}-aks"
  resource_group_name = "${var.project_name}-${local.environment}-rg"
  location            = var.azure_location
  kubernetes_version  = var.kubernetes_version
  vm_size             = "Standard_D8s_v3"
  enable_auto_scaling = true
  min_count           = 3
  max_count           = 12
  network_plugin      = "azure"
  enable_rbac         = true
  environment         = local.environment

  tags = local.common_tags
}

###############################################################################
# Azure – Service Principal (for CI/CD pipelines)
###############################################################################

module "azure_service_principal" {
  source = "../../../modules/azure/service-principal"

  app_name             = "${var.project_name}-${local.environment}-sp"
  role_definition_name = "Contributor"
  scope                = "/subscriptions/${var.azure_subscription_id}"
  secret_expiry_months = 6
}

###############################################################################
# GCP – GCS
###############################################################################

module "gcp_gcs_artifacts" {
  source = "../../../modules/gcp/gcs"

  bucket_name        = "${replace(var.project_name, "-", "_")}_${local.environment}_artifacts_${var.gcp_project}"
  project            = var.gcp_project
  location           = "US"  # multi-region for production
  storage_class      = "STANDARD"
  versioning         = true
  lifecycle_age_days = 90

  labels = local.common_labels
}

###############################################################################
# GCP – Artifact Registry
###############################################################################

module "gcp_artifact_registry" {
  source = "../../../modules/gcp/artifact-registry"

  repository_id = "${var.project_name}-${local.environment}"
  project       = var.gcp_project
  location      = var.gcp_region
  format        = "DOCKER"
  description   = "Docker images for ${var.project_name} ${local.environment}"

  labels = local.common_labels
}

###############################################################################
# GCP – KMS (HSM protection for production)
###############################################################################

module "gcp_kms" {
  source = "../../../modules/gcp/kms"

  key_ring_name        = "${var.project_name}-${local.environment}"
  key_name             = "default"
  project              = var.gcp_project
  location             = var.gcp_region
  rotation_period_days = 90
  protection_level     = "HSM"

  labels = local.common_labels
}

###############################################################################
# GCP – GKE (private cluster, regional)
###############################################################################

module "gcp_gke" {
  source = "../../../modules/gcp/gke"

  cluster_name               = "${var.project_name}-${local.environment}"
  project                    = var.gcp_project
  location                   = var.gcp_region  # regional for HA
  mode                       = "standard"
  node_count                 = 3
  machine_type               = "n2-standard-4"
  kubernetes_release_channel = "stable"
  enable_workload_identity   = true
  enable_private_cluster     = true
  master_ipv4_cidr_block     = "172.16.2.0/28"
}

###############################################################################
# GCP – Cloud SQL (HA)
###############################################################################

module "gcp_cloudsql" {
  source = "../../../modules/gcp/cloudsql"

  instance_name     = "${var.project_name}-${local.environment}"
  project           = var.gcp_project
  region            = var.gcp_region
  database_version  = "POSTGRES_16"
  tier              = "db-n1-standard-4"
  high_availability = true
  backup_enabled    = true
  backup_start_time = "01:00"
  disk_size_gb      = 100

  labels = local.common_labels
}
