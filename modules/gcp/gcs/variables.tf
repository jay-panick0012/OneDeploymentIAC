###############################################################################
# GCP GCS Module – variables.tf
###############################################################################

variable "bucket_name" {
  description = "Globally unique name for the GCS bucket."
  type        = string
}

variable "project" {
  description = "GCP project ID."
  type        = string
}

variable "location" {
  description = "GCS bucket location (region, dual-region, or multi-region e.g. US, EU, asia)."
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Default storage class. Valid values: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], upper(var.storage_class))
    error_message = "storage_class must be STANDARD, NEARLINE, COLDLINE, or ARCHIVE."
  }
}

variable "versioning" {
  description = "Enable object versioning on the bucket."
  type        = bool
  default     = true
}

variable "lifecycle_age_days" {
  description = "Age in days after which objects transition to NEARLINE storage class."
  type        = number
  default     = 30
}

variable "labels" {
  description = "Map of labels to apply to the bucket."
  type        = map(string)
  default     = {}
}
