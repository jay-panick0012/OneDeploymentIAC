###############################################################################
# AWS Region Stack Module – outputs.tf
###############################################################################

output "vpc_id" {
  description = "ID of the region's VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block allocated to this region's VPC."
  value       = local.vpc_cidr
}

output "eks_cluster_name" {
  description = "Name of the region's EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API server endpoint of the region's EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "rds_db_endpoint" {
  description = "Connection endpoint of the region's RDS instance."
  value       = module.rds.db_endpoint
}

output "ecr_repository_url" {
  description = "URI of the region's ECR repository."
  value       = module.ecr.repository_url
}

output "s3_artifacts_bucket_id" {
  description = "Name of the region's S3 artifacts bucket."
  value       = module.s3_artifacts.bucket_id
}

output "kms_key_arn" {
  description = "ARN of the region's KMS key."
  value       = module.kms.key_arn
}

output "sns_topic_arn" {
  description = "ARN of the region's SNS topic. Empty string when enable_messaging = false."
  value       = var.enable_messaging ? module.messaging[0].topic_arn : ""
}

output "cloudwatch_log_group_name" {
  description = "Name of the region's CloudWatch log group. Empty string when enable_monitoring = false."
  value       = var.enable_monitoring ? module.monitoring[0].log_group_name : ""
}

output "route53_zone_id" {
  description = "ID of the region's Route 53 hosted zone. Empty string when enable_dns = false."
  value       = var.enable_dns ? module.dns[0].zone_id : ""
}
