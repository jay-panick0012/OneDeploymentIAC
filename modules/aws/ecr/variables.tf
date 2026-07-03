###############################################################################
# AWS ECR Module – variables.tf
###############################################################################

variable "repository_name" {
  description = "Name of the ECR repository."
  type        = string
}

variable "scan_on_push" {
  description = "Enable vulnerability scanning on every image push."
  type        = bool
  default     = true
}

variable "immutable_tags" {
  description = "When true, image tags cannot be overwritten (IMMUTABLE). Recommended for production."
  type        = bool
  default     = false
}

variable "retain_image_count" {
  description = "Number of tagged images (with 'v' prefix) to retain before expiring older ones."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
