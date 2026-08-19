###############################################################################
# Staging Environment – GCP – us-central1 – variables.tf
###############################################################################

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
  default     = "us-central1"
}

variable "region_index" {
  description = "Zero-based index of this region within the global CIDR allocation sequence (dev=0, staging=1&2, production=3&4)."
  type        = number
  default     = 1
}

variable "notification_email" {
  description = "Email address to receive monitoring alerts."
  type        = string
  default     = "platform-team@example.com"
}
