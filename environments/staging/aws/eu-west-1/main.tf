###############################################################################
# Staging Environment – AWS – eu-west-1 – main.tf
# Mid-tier sizing: NAT per AZ, moderate instance sizes, HA database.
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
  environment = "staging"
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

  availability_zone_suffixes = ["a", "b", "c"]
  single_nat_gateway         = false
  kms_deletion_window_days   = 14
  s3_glacier_transition_days = 60
  ecr_immutable_tags         = true
  ecr_retain_image_count     = 20

  kubernetes_version      = var.kubernetes_version
  eks_node_instance_types = ["t3.large"]
  eks_desired_size        = 3
  eks_min_size            = 2
  eks_max_size            = 6
  eks_disk_size_gb        = 50
  eks_private_endpoint    = true

  rds_instance_class          = "db.r6g.large"
  rds_allocated_storage       = 50
  rds_multi_az                = true
  rds_backup_retention_period = 7

  tags = local.common_tags
}
