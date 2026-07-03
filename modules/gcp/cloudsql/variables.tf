###############################################################################
# GCP Cloud SQL Module – variables.tf
###############################################################################

variable "instance_name" {
  description = "Base name for the Cloud SQL instance. A random suffix is appended."
  type        = string
}

variable "project" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region for the Cloud SQL instance."
  type        = string
}

variable "database_version" {
  description = "Database engine version (e.g. POSTGRES_16, MYSQL_8_0, SQLSERVER_2019_STANDARD)."
  type        = string
  default     = "POSTGRES_16"
}

variable "tier" {
  description = "Machine tier for the Cloud SQL instance (e.g. db-f1-micro, db-n1-standard-2)."
  type        = string
  default     = "db-n1-standard-2"
}

variable "high_availability" {
  description = "Enable regional high availability (REGIONAL availability type with failover replica)."
  type        = bool
  default     = false
}

variable "backup_enabled" {
  description = "Enable automated backups."
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Start time for automated backups in HH:MM format (UTC)."
  type        = string
  default     = "02:00"
}

variable "disk_size_gb" {
  description = "Initial disk size in GB."
  type        = number
  default     = 20
}

variable "labels" {
  description = "Map of labels to apply to the Cloud SQL instance."
  type        = map(string)
  default     = {}
}
