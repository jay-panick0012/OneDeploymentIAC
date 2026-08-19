###############################################################################
# GCP Region Stack Module – variables.tf
###############################################################################

variable "project_name" {
  description = "Short name of the project (used as prefix for resource names)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, production)."
  type        = string
}

variable "gcp_project" {
  description = "GCP project ID this stack is deployed into."
  type        = string
}

variable "region" {
  description = "GCP region this stack is deployed into (e.g. us-central1, europe-west1). Must match the google provider's configured region."
  type        = string
}

variable "region_index" {
  description = "Zero-based index of this region within the environment's region list. Used to derive a non-overlapping /28 GKE master CIDR via cidrsubnet(172.16.0.0/12, 16, region_index). Each environment/region combination across the whole repo must use a unique index to avoid CIDR collisions."
  type        = number
}

variable "kms_rotation_period_days" {
  description = "Number of days between automatic KMS key version rotations."
  type        = number
  default     = 90
}

variable "kms_protection_level" {
  description = "Protection level for the KMS key. Valid values: SOFTWARE, HSM."
  type        = string
  default     = "SOFTWARE"
}

variable "gcs_storage_class" {
  description = "Default storage class for the artifacts bucket."
  type        = string
  default     = "STANDARD"
}

variable "gcs_location" {
  description = "GCS bucket location override. When empty, defaults to upper(var.region) (a single-region bucket co-located with the stack)."
  type        = string
  default     = ""
}

variable "gcs_lifecycle_age_days" {
  description = "Age in days after which artifact objects transition to NEARLINE storage."
  type        = number
  default     = 30
}

variable "gke_mode" {
  description = "GKE cluster mode. Valid values: autopilot, standard."
  type        = string
  default     = "standard"
}

variable "gke_node_count" {
  description = "Initial node count per zone (standard mode only)."
  type        = number
  default     = 1
}

variable "gke_machine_type" {
  description = "Machine type for cluster nodes (standard mode only)."
  type        = string
  default     = "e2-medium"
}

variable "gke_release_channel" {
  description = "Release channel for automatic upgrades. Valid values: rapid, regular, stable, unspecified."
  type        = string
  default     = "regular"
}

variable "gke_enable_private_cluster" {
  description = "Enable private nodes for the GKE cluster."
  type        = bool
  default     = false
}

variable "cloudsql_tier" {
  description = "Machine tier for the Cloud SQL instance."
  type        = string
  default     = "db-n1-standard-2"
}

variable "cloudsql_high_availability" {
  description = "Enable regional high availability for Cloud SQL."
  type        = bool
  default     = false
}

variable "cloudsql_backup_start_time" {
  description = "Start time for automated Cloud SQL backups in HH:MM format (UTC)."
  type        = string
  default     = "02:00"
}

variable "cloudsql_disk_size_gb" {
  description = "Initial Cloud SQL disk size in GB."
  type        = number
  default     = 20
}

variable "enable_messaging" {
  description = "Create the Pub/Sub topic + subscription for this region."
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Create the notification channel + alert policy for this region."
  type        = bool
  default     = true
}

variable "notification_email" {
  description = "Email address to receive monitoring alerts. Required when enable_monitoring = true."
  type        = string
  default     = ""
}

variable "enable_dns" {
  description = "Create a Cloud DNS managed zone for this region."
  type        = bool
  default     = false
}

variable "dns_zone_name" {
  description = "Terraform/GCP resource name for the managed zone (e.g. example-zone). Required when enable_dns = true."
  type        = string
  default     = ""
}

variable "dns_domain" {
  description = "DNS domain name with trailing dot (e.g. example.com.). Required when enable_dns = true."
  type        = string
  default     = ""
}

variable "labels" {
  description = "Map of labels to apply to all resources."
  type        = map(string)
  default     = {}
}
