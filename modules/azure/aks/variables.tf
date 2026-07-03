###############################################################################
# Azure AKS Module – variables.tf
###############################################################################

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to create for the AKS cluster."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster."
  type        = string
  default     = "1.30"
}

variable "node_count" {
  description = "Fixed number of nodes in the default node pool. Used when enable_auto_scaling is false."
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM size for nodes in the default node pool."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "enable_auto_scaling" {
  description = "Enable cluster autoscaler on the default node pool."
  type        = bool
  default     = false
}

variable "min_count" {
  description = "Minimum node count when autoscaling is enabled."
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum node count when autoscaling is enabled."
  type        = number
  default     = 5
}

variable "network_plugin" {
  description = "Network plugin for the AKS cluster. Valid values: azure, kubenet, none."
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet", "none"], var.network_plugin)
    error_message = "network_plugin must be azure, kubenet, or none."
  }
}

variable "enable_rbac" {
  description = "Enable Azure RBAC for Kubernetes authorization."
  type        = bool
  default     = true
}

variable "environment" {
  description = "Deployment environment (dev, staging, production)."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
