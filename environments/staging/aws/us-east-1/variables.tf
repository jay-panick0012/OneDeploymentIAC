###############################################################################
# Staging Environment – AWS – us-east-1 – variables.tf
###############################################################################

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
  default     = "us-east-1"
}

variable "region_index" {
  description = "Zero-based index of this region within the global CIDR allocation sequence (dev=0, staging=1&2, production=3&4)."
  type        = number
  default     = 1
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
