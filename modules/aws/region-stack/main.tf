###############################################################################
# AWS Region Stack Module – main.tf
# Composes: VPC, KMS, S3, ECR, EKS, RDS, and optional SNS/SQS, CloudWatch,
# and Route 53 into a single deployable stack for one AWS region. Called once
# per environments/<env>/aws/<region>/ root, each with its own provider and
# state, so this module never needs provider aliasing.
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  name_prefix          = "${var.project_name}-${var.environment}-${var.region}"
  az_count             = length(var.availability_zone_suffixes)
  vpc_cidr             = cidrsubnet(var.vpc_supernet, 8, var.region_index)
  public_subnet_cidrs  = [for i in range(local.az_count) : cidrsubnet(local.vpc_cidr, 8, i + 1)]
  private_subnet_cidrs = [for i in range(local.az_count) : cidrsubnet(local.vpc_cidr, 8, i + 11)]
  availability_zones   = [for s in var.availability_zone_suffixes : "${var.region}${s}"]
}

module "vpc" {
  source = "../vpc"

  vpc_name             = local.name_prefix
  cidr_block           = local.vpc_cidr
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  availability_zones   = local.availability_zones
  single_nat_gateway   = var.single_nat_gateway

  tags = var.tags
}

module "kms" {
  source = "../kms"

  key_alias            = local.name_prefix
  key_usage            = "ENCRYPT_DECRYPT"
  rotation_enabled     = true
  deletion_window_days = var.kms_deletion_window_days

  tags = var.tags
}

module "s3_artifacts" {
  source = "../s3"

  bucket_name             = "${local.name_prefix}-artifacts-${var.aws_account_id}"
  region                  = var.region
  versioning_enabled      = true
  sse_algorithm           = "aws:kms"
  kms_key_id              = module.kms.key_arn
  glacier_transition_days = var.s3_glacier_transition_days

  tags = var.tags
}

module "ecr" {
  source = "../ecr"

  repository_name    = local.name_prefix
  scan_on_push       = true
  immutable_tags     = var.ecr_immutable_tags
  retain_image_count = var.ecr_retain_image_count

  tags = var.tags
}

module "eks" {
  source = "../eks"

  cluster_name        = local.name_prefix
  kubernetes_version  = var.kubernetes_version
  region              = var.region
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  node_instance_types = var.eks_node_instance_types
  desired_size        = var.eks_desired_size
  min_size            = var.eks_min_size
  max_size            = var.eks_max_size
  disk_size_gb        = var.eks_disk_size_gb
  environment         = var.environment
  private_endpoint    = var.eks_private_endpoint
  enable_oidc         = true

  tags = var.tags
}

module "rds" {
  source = "../rds"

  identifier              = local.name_prefix
  engine                  = "postgres"
  engine_version          = "16.2"
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  db_name                 = replace(var.project_name, "-", "_")
  username                = "dbadmin"
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  subnet_ids              = module.vpc.private_subnet_ids
  vpc_security_group_ids  = []

  tags = var.tags
}

module "messaging" {
  source = "../sns-sqs"
  count  = var.enable_messaging ? 1 : 0

  topic_name = "${local.name_prefix}-events"
  queue_name = "${local.name_prefix}-events"

  tags = var.tags
}

module "monitoring" {
  source = "../cloudwatch"
  count  = var.enable_monitoring ? 1 : 0

  log_group_name    = "/aws/${local.name_prefix}"
  alarm_name        = "${local.name_prefix}-eks-node-cpu-high"
  alarm_metric_name = "node_cpu_utilization"
  alarm_namespace   = "ContainerInsights"
  dimensions        = { ClusterName = local.name_prefix }

  tags = var.tags
}

module "dns" {
  source = "../route53"
  count  = var.enable_dns ? 1 : 0

  zone_name = var.dns_zone_name

  tags = var.tags
}
