###############################################################################
# AWS S3 Module – variables.tf
###############################################################################

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket."
  type        = string
}

variable "region" {
  description = "AWS region where the bucket is created. Used for documentation; provider region controls actual placement."
  type        = string
  default     = "us-east-1"
}

variable "versioning_enabled" {
  description = "Enable S3 object versioning."
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm. Valid values: AES256, aws:kms."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "sse_algorithm must be AES256 or aws:kms."
  }
}

variable "kms_key_id" {
  description = "ARN or ID of the KMS key to use when sse_algorithm is aws:kms."
  type        = string
  default     = null
}

variable "glacier_transition_days" {
  description = "Number of days after which objects transition to GLACIER storage class. Set to 0 to disable."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
