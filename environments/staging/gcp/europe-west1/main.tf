###############################################################################
# Staging Environment – GCP – europe-west1 – main.tf
# Mid-tier sizing: standard GKE, HA Cloud SQL.
###############################################################################

terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {}
}

provider "google" {
  project = var.gcp_project
  region  = var.region
}

locals {
  environment = "staging"
  common_labels = {
    environment = local.environment
    project     = replace(lower(var.project_name), " ", "-")
    managed_by  = "terraform"
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
  gke_node_count             = 2
  gke_machine_type           = "e2-standard-2"
  gke_release_channel        = "regular"
  gke_enable_private_cluster = true

  cloudsql_tier              = "db-n1-standard-2"
  cloudsql_high_availability = true
  cloudsql_disk_size_gb      = 50

  kms_protection_level = "SOFTWARE"
  notification_email   = var.notification_email

  labels = local.common_labels
}
