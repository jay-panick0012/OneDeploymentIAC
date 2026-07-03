###############################################################################
# Dev Environment – variables.tf
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

# ── AWS ───────────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region for all AWS resources."
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID (used to build globally-unique S3 bucket names)."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS and AKS clusters."
  type        = string
  default     = "1.30"
}

# ── Azure ─────────────────────────────────────────────────────────────────────

variable "azure_subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "azure_location" {
  description = "Azure region for all Azure resources."
  type        = string
  default     = "eastus"
}

# ── GCP ───────────────────────────────────────────────────────────────────────

variable "gcp_project" {
  description = "GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for all GCP resources."
  type        = string
  default     = "us-central1"
}
