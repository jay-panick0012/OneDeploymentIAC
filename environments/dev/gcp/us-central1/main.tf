###############################################################################
# Dev Environment – GCP – us-central1 – main.tf
# Cost-optimized: standard GKE, single node, no HA.
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
  environment = "dev"
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
  gke_node_count             = 1
  gke_machine_type           = "e2-medium"
  gke_release_channel        = "regular"
  gke_enable_private_cluster = false

  cloudsql_tier              = "db-f1-micro"
  cloudsql_high_availability = false
  cloudsql_disk_size_gb      = 20

  kms_protection_level = "SOFTWARE"
  notification_email   = var.notification_email

  labels = local.common_labels
}
