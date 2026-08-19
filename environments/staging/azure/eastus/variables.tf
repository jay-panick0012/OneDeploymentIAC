###############################################################################
# Staging Environment – Azure – eastus – variables.tf
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

variable "azure_subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "location" {
  description = "Azure region for this stack."
  type        = string
  default     = "eastus"
}

variable "region_index" {
  description = "Zero-based index of this region within the global CIDR allocation sequence (dev=0, staging=1&2, production=3&4)."
  type        = number
  default     = 1
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster."
  type        = string
  default     = "1.30"
}

variable "alert_email" {
  description = "Email address to receive monitoring alerts."
  type        = string
  default     = "platform-team@example.com"
}
