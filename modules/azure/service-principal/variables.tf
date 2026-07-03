###############################################################################
# Azure Service Principal Module – variables.tf
###############################################################################

variable "app_name" {
  description = "Display name for the AAD application and service principal."
  type        = string
}

variable "role_definition_name" {
  description = "Azure built-in or custom role to assign to the service principal."
  type        = string
  default     = "Contributor"
}

variable "scope" {
  description = "Resource scope for the role assignment (e.g. subscription ID, resource group ID)."
  type        = string
}

variable "secret_expiry_months" {
  description = "Number of months before the client secret is rotated."
  type        = number
  default     = 12
}

variable "tags" {
  description = "Map of tags. Not directly applied to AAD resources but used for documentation."
  type        = map(string)
  default     = {}
}
