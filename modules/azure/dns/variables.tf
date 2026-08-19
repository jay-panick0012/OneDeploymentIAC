###############################################################################
# Azure DNS Module – variables.tf
###############################################################################

variable "zone_name" {
  description = "Name of the public DNS zone (e.g. \"example.com\")."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the DNS zone into."
  type        = string
}

variable "records" {
  description = "List of DNS records to create in the zone. Supported types are A, CNAME, and TXT."
  type = list(object({
    name   = string
    type   = string
    ttl    = optional(number, 300)
    values = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
