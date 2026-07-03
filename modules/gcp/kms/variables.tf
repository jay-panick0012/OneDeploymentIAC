###############################################################################
# GCP KMS Module – variables.tf
###############################################################################

variable "key_ring_name" {
  description = "Name of the KMS key ring."
  type        = string
}

variable "key_name" {
  description = "Name of the KMS crypto key within the ring."
  type        = string
}

variable "project" {
  description = "GCP project ID."
  type        = string
}

variable "location" {
  description = "GCP region or 'global' for the key ring."
  type        = string
}

variable "rotation_period_days" {
  description = "Number of days between automatic key version rotations."
  type        = number
  default     = 90
}

variable "protection_level" {
  description = "Protection level for the key. Valid values: SOFTWARE, HSM."
  type        = string
  default     = "SOFTWARE"

  validation {
    condition     = contains(["SOFTWARE", "HSM"], upper(var.protection_level))
    error_message = "protection_level must be SOFTWARE or HSM."
  }
}

variable "labels" {
  description = "Map of labels to apply to the crypto key."
  type        = map(string)
  default     = {}
}
