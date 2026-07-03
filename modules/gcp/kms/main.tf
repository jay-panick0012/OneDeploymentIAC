###############################################################################
# GCP KMS Module – main.tf
# Creates: KMS Key Ring and CryptoKey with rotation and protection level
###############################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

resource "google_kms_key_ring" "this" {
  name     = var.key_ring_name
  project  = var.project
  location = var.location
}

resource "google_kms_crypto_key" "this" {
  name     = var.key_name
  key_ring = google_kms_key_ring.this.id

  rotation_period = "${var.rotation_period_days * 24 * 3600}s"

  version_template {
    algorithm        = var.protection_level == "HSM" ? "GOOGLE_SYMMETRIC_ENCRYPTION" : "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = upper(var.protection_level)
  }

  lifecycle {
    prevent_destroy = true
  }

  labels = var.labels
}
