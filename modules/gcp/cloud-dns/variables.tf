###############################################################################
# GCP Cloud DNS Module – variables.tf
###############################################################################

variable "zone_name" {
  description = "The Terraform/GCP resource name for the managed zone, e.g. \"example-zone\" (not the DNS domain)."
  type        = string
}

variable "dns_name" {
  description = "The actual DNS domain for the zone, with a trailing dot, e.g. \"example.com.\"."
  type        = string
}

variable "project" {
  description = "GCP project ID."
  type        = string
}

variable "description" {
  description = "Description of the managed zone."
  type        = string
  default     = ""
}

variable "records" {
  description = "List of DNS record sets to create in the managed zone."
  type = list(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    rrdatas = list(string)
  }))
  default = []
}

variable "labels" {
  description = "Map of labels to apply to the managed zone."
  type        = map(string)
  default     = {}
}
