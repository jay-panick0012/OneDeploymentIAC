###############################################################################
# GCP GCS Module – main.tf
# Creates: GCS bucket with versioning, lifecycle rules, and uniform access
###############################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

resource "google_storage_bucket" "this" {
  name                        = var.bucket_name
  project                     = var.project
  location                    = upper(var.location)
  storage_class               = upper(var.storage_class)
  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = var.versioning
  }

  lifecycle_rule {
    condition {
      age = var.lifecycle_age_days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = var.lifecycle_age_days * 3
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.versioning ? [1] : []
    content {
      condition {
        num_newer_versions = 5
        with_state         = "ARCHIVED"
      }
      action {
        type = "Delete"
      }
    }
  }

  labels = var.labels
}
