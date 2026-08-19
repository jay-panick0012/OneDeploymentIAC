###############################################################################
# AWS Region Stack Module – variables.tf
###############################################################################

variable "project_name" {
  description = "Short name of the project (used as prefix for resource names)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, production)."
  type        = string
}

variable "region" {
  description = "AWS region this stack is deployed into. Must match the aws provider's configured region."
  type        = string
}

variable "region_index" {
  description = "Zero-based index of this region within the environment's region list. Used to derive a non-overlapping /16 CIDR block via cidrsubnet(var.vpc_supernet, 8, region_index). Each environment/region combination across the whole repo must use a unique index to avoid CIDR collisions."
  type        = number
}

variable "vpc_supernet" {
  description = "Supernet that this region's VPC /16 is carved out of."
  type        = string
  default     = "10.0.0.0/8"
}

variable "availability_zone_suffixes" {
  description = "AZ letter suffixes to place subnets in (e.g. [\"a\", \"b\"] for 2 AZs, [\"a\", \"b\", \"c\"] for 3)."
  type        = list(string)
  default     = ["a", "b"]
}

variable "aws_account_id" {
  description = "AWS account ID (used to build a globally-unique S3 bucket name)."
  type        = string
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (cost-saving for dev). When false, one NAT per AZ."
  type        = bool
  default     = true
}

variable "kms_deletion_window_days" {
  description = "KMS key deletion window in days (7-30)."
  type        = number
  default     = 30
}

variable "s3_glacier_transition_days" {
  description = "Days after which S3 artifact objects transition to GLACIER."
  type        = number
  default     = 90
}

variable "ecr_immutable_tags" {
  description = "When true, ECR image tags cannot be overwritten. Recommended for production."
  type        = bool
  default     = false
}

variable "ecr_retain_image_count" {
  description = "Number of tagged ECR images to retain before expiring older ones."
  type        = number
  default     = 30
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.30"
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for the EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_desired_size" {
  description = "Desired number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "eks_min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 1
}

variable "eks_max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 4
}

variable "eks_disk_size_gb" {
  description = "EBS disk size in GB for each EKS node."
  type        = number
  default     = 50
}

variable "eks_private_endpoint" {
  description = "Enable a private-only EKS API server endpoint."
  type        = bool
  default     = false
}

variable "rds_instance_class" {
  description = "RDS instance class (e.g. db.t3.medium, db.r6g.xlarge)."
  type        = string
  default     = "db.t3.medium"
}

variable "rds_allocated_storage" {
  description = "Allocated RDS storage in GiB."
  type        = number
  default     = 20
}

variable "rds_multi_az" {
  description = "Enable RDS Multi-AZ deployment for high availability."
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain automated RDS backups."
  type        = number
  default     = 7
}

variable "enable_messaging" {
  description = "Create the SNS topic + SQS queue for this region."
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Create the CloudWatch log group, alarm, and dashboard for this region."
  type        = bool
  default     = true
}

variable "enable_dns" {
  description = "Create a Route 53 hosted zone for this region."
  type        = bool
  default     = false
}

variable "dns_zone_name" {
  description = "Domain name for the Route 53 hosted zone. Required when enable_dns = true."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
