###############################################################################
# GCP Artifact Registry Module – main.tf
# Creates: Artifact Registry repository (Docker, Maven, NPM, etc.)
###############################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

resource "google_artifact_registry_repository" "this" {
  provider = google

  repository_id = var.repository_id
  project       = var.project
  location      = var.location
  format        = upper(var.format)
  description   = var.description

  labels = var.labels

  cleanup_policy_dry_run = false

  dynamic "cleanup_policies" {
    for_each = var.format == "DOCKER" ? [1] : []
    content {
      id     = "delete-untagged"
      action = "DELETE"
      condition {
        tag_state = "UNTAGGED"
        older_than = "1209600s" # 14 days
      }
    }
  }

  dynamic "cleanup_policies" {
    for_each = var.format == "DOCKER" ? [1] : []
    content {
      id     = "keep-minimum-versions"
      action = "KEEP"
      most_recent_versions {
        keep_count = 10
      }
    }
  }
}
