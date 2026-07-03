###############################################################################
# Dev Environment – main.tf
# Orchestrates all cloud modules with dev-sized defaults.
# Cost-optimized: single NAT, smaller instances, no HA.
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
  environment = "dev"
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
  common_labels = {
    environment = local.environment
    project     = replace(lower(var.project_name), " ", "-")
    managed_by  = "terraform"
  }
}

###############################################################################
# AWS – VPC
###############################################################################

module "aws_vpc" {
  source = "../../../modules/aws/vpc"

  vpc_name             = "${var.project_name}-${local.environment}"
  cidr_block           = "10.10.0.0/16"
  public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24"]
  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b"]
  single_nat_gateway   = true  # dev: save cost with single NAT

  tags = local.common_tags
}

###############################################################################
# AWS – KMS
###############################################################################

module "aws_kms" {
  source = "../../../modules/aws/kms"

  key_alias            = "${var.project_name}-${local.environment}"
  key_usage            = "ENCRYPT_DECRYPT"
  rotation_enabled     = true
  deletion_window_days = 7  # dev: shorter retention

  tags = local.common_tags
}

###############################################################################
# AWS – S3 (artifact storage)
###############################################################################

module "aws_s3_artifacts" {
  source = "../../../modules/aws/s3"

  bucket_name             = "${var.project_name}-${local.environment}-artifacts-${var.aws_account_id}"
  versioning_enabled      = true
  sse_algorithm           = "aws:kms"
  kms_key_id              = module.aws_kms.key_arn
  glacier_transition_days = 30  # dev: faster archival

  tags = local.common_tags
}

###############################################################################
# AWS – ECR
###############################################################################

module "aws_ecr" {
  source = "../../../modules/aws/ecr"

  repository_name    = "${var.project_name}-${local.environment}"
  scan_on_push       = true
  immutable_tags     = false  # dev: allow overwriting tags
  retain_image_count = 10

  tags = local.common_tags
}

###############################################################################
# AWS – EKS
###############################################################################

module "aws_eks" {
  source = "../../../modules/aws/eks"

  cluster_name        = "${var.project_name}-${local.environment}"
  kubernetes_version  = var.kubernetes_version
  region              = var.aws_region
  vpc_id              = module.aws_vpc.vpc_id
  subnet_ids          = module.aws_vpc.private_subnet_ids
  node_instance_types = ["t3.medium"]
  desired_size        = 2
  min_size            = 1
  max_size            = 3
  disk_size_gb        = 30
  environment         = local.environment
  private_endpoint    = false
  enable_oidc         = true

  tags = local.common_tags
}

###############################################################################
# AWS – RDS
###############################################################################

module "aws_rds" {
  source = "../../../modules/aws/rds"

  identifier             = "${var.project_name}-${local.environment}"
  engine                 = "postgres"
  engine_version         = "16.2"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  db_name                = replace(var.project_name, "-", "_")
  username               = "dbadmin"
  multi_az               = false  # dev: single AZ to save cost
  backup_retention_period = 3
  subnet_ids             = module.aws_vpc.private_subnet_ids
  vpc_security_group_ids = []     # add security group IDs here

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
  address_space       = ["10.20.0.0/16"]

  subnets = [
    {
      name           = "aks-nodes"
      address_prefix = "10.20.1.0/24"
    },
    {
      name           = "data"
      address_prefix = "10.20.2.0/24"
    },
  ]

  tags = local.common_tags
}

###############################################################################
# Azure – ACR
###############################################################################

module "azure_acr" {
  source = "../../../modules/azure/acr"

  registry_name       = "${replace(var.project_name, "-", "")}${local.environment}acr"
  resource_group_name = "${var.project_name}-${local.environment}-rg"
  location            = var.azure_location
  sku                 = "Basic"
  admin_enabled       = false
  georeplications     = []

  tags = local.common_tags

  depends_on = [module.azure_vnet]
}

###############################################################################
# Azure – Key Vault
###############################################################################

module "azure_keyvault" {
  source = "../../../modules/azure/keyvault"

  vault_name          = "${replace(var.project_name, "-", "")}${local.environment}kv"
  resource_group_name = "${var.project_name}-${local.environment}-rg"
  location            = var.azure_location
  sku                 = "standard"
  soft_delete_days    = 7   # dev: shorter retention
  purge_protection    = false

  tags = local.common_tags

  depends_on = [module.azure_vnet]
}

###############################################################################
# Azure – AKS
###############################################################################

module "azure_aks" {
  source = "../../../modules/azure/aks"

  cluster_name        = "${var.project_name}-${local.environment}-aks"
  resource_group_name = "${var.project_name}-${local.environment}-rg"
  location            = var.azure_location
  kubernetes_version  = var.kubernetes_version
  node_count          = 2
  vm_size             = "Standard_D2s_v3"
  enable_auto_scaling = false
  network_plugin      = "azure"
  enable_rbac         = true
  environment         = local.environment

  tags = local.common_tags
}

###############################################################################
# GCP – GCS (Terraform state bucket example)
###############################################################################

module "gcp_gcs_artifacts" {
  source = "../../../modules/gcp/gcs"

  bucket_name        = "${replace(var.project_name, "-", "_")}_${local.environment}_artifacts_${var.gcp_project}"
  project            = var.gcp_project
  location           = upper(var.gcp_region)
  storage_class      = "STANDARD"
  versioning         = true
  lifecycle_age_days = 30

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
# GCP – KMS
###############################################################################

module "gcp_kms" {
  source = "../../../modules/gcp/kms"

  key_ring_name        = "${var.project_name}-${local.environment}"
  key_name             = "default"
  project              = var.gcp_project
  location             = var.gcp_region
  rotation_period_days = 90
  protection_level     = "SOFTWARE"

  labels = local.common_labels
}

###############################################################################
# GCP – GKE
###############################################################################

module "gcp_gke" {
  source = "../../../modules/gcp/gke"

  cluster_name               = "${var.project_name}-${local.environment}"
  project                    = var.gcp_project
  location                   = var.gcp_region
  mode                       = "standard"
  node_count                 = 1
  machine_type               = "e2-medium"
  kubernetes_release_channel = "regular"
  enable_workload_identity   = true
  enable_private_cluster     = false
  master_ipv4_cidr_block     = "172.16.0.0/28"
}
