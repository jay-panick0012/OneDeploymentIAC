###############################################################################
# Azure ACR Module – variables.tf
###############################################################################

variable "registry_name" {
  description = "Name of the Azure Container Registry (5-50 alphanumeric chars, globally unique)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the registry into."
  type        = string
}

variable "location" {
  description = "Azure region for the registry."
  type        = string
  default     = "eastus"
}

variable "sku" {
  description = "SKU of the registry. Valid values: Basic, Standard, Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable admin user credentials. Not recommended for production; use managed identity instead."
  type        = bool
  default     = false
}

variable "georeplications" {
  description = "List of geo-replication locations. Only valid when sku = Premium."
  type = list(object({
    location                = string
    zone_redundancy_enabled = optional(bool, false)
  }))
  default = []
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
