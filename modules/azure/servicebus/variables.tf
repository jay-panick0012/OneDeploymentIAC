###############################################################################
# Azure Service Bus Module – variables.tf
###############################################################################

variable "namespace_name" {
  description = "Name of the Service Bus namespace (6-50 chars, globally unique)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the Service Bus namespace into."
  type        = string
}

variable "location" {
  description = "Azure region for the Service Bus namespace."
  type        = string
  default     = "eastus"
}

variable "sku" {
  description = "SKU for the Service Bus namespace. Valid values: Basic, Standard, Premium."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "queue_name" {
  description = "Name of the Service Bus queue."
  type        = string
}

variable "max_delivery_count" {
  description = "Maximum number of delivery attempts for a message before it is dead-lettered."
  type        = number
  default     = 10
}

variable "lock_duration" {
  description = "Lock duration for messages in the queue, as an ISO 8601 duration (e.g. PT30S)."
  type        = string
  default     = "PT30S"
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
