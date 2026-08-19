###############################################################################
# AWS Route53 Module – variables.tf
###############################################################################

variable "zone_name" {
  description = "Domain name for the hosted zone (e.g. example.com)."
  type        = string
}

variable "private_zone" {
  description = "Create a private hosted zone associated with a VPC instead of a public zone."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID to associate with the zone. Required when private_zone is true."
  type        = string
  default     = null
}

variable "records" {
  description = "List of DNS records to create in the zone."
  type = list(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    records = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Map of tags to apply to the hosted zone. Note: tags do not apply to the private zone's VPC association(s)."
  type        = map(string)
  default     = {}
}
