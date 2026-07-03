###############################################################################
# Azure VNet Module – variables.tf
###############################################################################

variable "vnet_name" {
  description = "Name of the virtual network."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the VNet into."
  type        = string
}

variable "location" {
  description = "Azure region for the VNet."
  type        = string
  default     = "eastus"
}

variable "address_space" {
  description = "List of address spaces for the VNet (e.g. ['10.0.0.0/16'])."
  type        = list(string)
}

variable "subnets" {
  description = "List of subnet definitions."
  type = list(object({
    name           = string
    address_prefix = string
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = optional(list(string), [])
    }))
  }))
  default = []
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
