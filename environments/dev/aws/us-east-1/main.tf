###############################################################################
# Dev Environment – AWS – us-east-1 – main.tf
# Cost-optimized: single NAT, smaller instances, no HA.
###############################################################################

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
  environment = "dev"
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

  project_name   = var.project_name
  environment    = local.environment
  region         = var.region
  region_index   = var.region_index
  aws_account_id = var.aws_account_id

  single_nat_gateway         = true
  kms_deletion_window_days   = 7
  s3_glacier_transition_days = 30
  ecr_immutable_tags         = false
  ecr_retain_image_count     = 10

  kubernetes_version      = var.kubernetes_version
  eks_node_instance_types = ["t3.medium"]
  eks_desired_size        = 2
  eks_min_size            = 1
  eks_max_size            = 3
  eks_disk_size_gb        = 30
  eks_private_endpoint    = false

  rds_instance_class          = "db.t3.medium"
  rds_allocated_storage       = 20
  rds_multi_az                = false
  rds_backup_retention_period = 3

  tags = local.common_tags
}
