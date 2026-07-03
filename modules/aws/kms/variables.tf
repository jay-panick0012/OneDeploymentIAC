###############################################################################
# AWS KMS Module – variables.tf
###############################################################################

variable "key_alias" {
  description = "Alias for the KMS key (without the 'alias/' prefix)."
  type        = string
}

variable "key_usage" {
  description = "Intended use of the key. Valid values: ENCRYPT_DECRYPT, SIGN_VERIFY."
  type        = string
  default     = "ENCRYPT_DECRYPT"

  validation {
    condition     = contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY"], var.key_usage)
    error_message = "key_usage must be ENCRYPT_DECRYPT or SIGN_VERIFY."
  }
}

variable "rotation_enabled" {
  description = "Enable automatic annual key rotation. Only applies to symmetric keys (ENCRYPT_DECRYPT)."
  type        = bool
  default     = true
}

variable "deletion_window_days" {
  description = "Number of days to wait before deleting the key after it is scheduled for deletion (7-30)."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_days >= 7 && var.deletion_window_days <= 30
    error_message = "deletion_window_days must be between 7 and 30."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
