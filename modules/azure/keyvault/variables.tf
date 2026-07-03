###############################################################################
# Azure Key Vault Module – variables.tf
###############################################################################

variable "vault_name" {
  description = "Name of the Key Vault (3-24 chars, globally unique, alphanumeric and hyphens)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the Key Vault into."
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault."
  type        = string
  default     = "eastus"
}

variable "sku" {
  description = "SKU for the Key Vault. Valid values: standard, premium."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku)
    error_message = "sku must be standard or premium."
  }
}

variable "soft_delete_days" {
  description = "Number of days to retain deleted vault objects (7-90)."
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_days >= 7 && var.soft_delete_days <= 90
    error_message = "soft_delete_days must be between 7 and 90."
  }
}

variable "purge_protection" {
  description = "Enable purge protection. Once enabled, cannot be disabled. Mandatory for production."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
