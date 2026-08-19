###############################################################################
# Production Environment – GCP – us-central1 – main.tf
# Full-HA: standard GKE with private nodes, regional Cloud SQL HA.
###############################################################################

terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }

  backend "gcs" {}
}

provider "google" {
  project = var.gcp_project
  region  = var.region
}

locals {
  environment = "production"
  common_labels = {
    environment = local.environment
    project     = replace(lower(var.project_name), " ", "-")
    managed_by  = "terraform"
    criticality = "high"
  }
}

###############################################################################
# GCP – Region Stack
###############################################################################

module "stack" {
  source = "../../../../modules/gcp/region-stack"

  project_name = var.project_name
  environment  = local.environment
  gcp_project  = var.gcp_project
  region       = var.region
  region_index = var.region_index

  gke_mode                   = "standard"
  gke_node_count             = 3
  gke_machine_type           = "n2-standard-4"
  gke_release_channel        = "stable"
  gke_enable_private_cluster = true

  cloudsql_tier              = "db-n1-standard-4"
  cloudsql_high_availability = true
  cloudsql_disk_size_gb      = 100

  kms_protection_level = "HSM"
  notification_email   = var.notification_email

  labels = local.common_labels
}
