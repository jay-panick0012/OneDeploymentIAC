###############################################################################
# State Backend – GCP GCS
#
# Bootstrap steps (run once before `terraform init`):
#
#   1. Create the GCS bucket:
#      gsutil mb -p MY_PROJECT -l US -b on gs://one-deploy-dash-tfstate-MY_PROJECT
#
#   2. Enable versioning:
#      gsutil versioning set on gs://one-deploy-dash-tfstate-MY_PROJECT
#
#   3. Set lifecycle rules (optional, keep last 100 versions):
#      gsutil lifecycle set lifecycle.json gs://one-deploy-dash-tfstate-MY_PROJECT
#
#   4. Add the backend block to each environment's main.tf and run
#      `terraform init`. The prefix path isolates each environment.
#      GCS does not require a separate lock table — it uses object locking.
###############################################################################

# backend "gcs" {
#   bucket = "one-deploy-dash-tfstate-my-gcp-project"
#   prefix = "environments/${terraform.workspace}"
#
#   # Workload Identity (for GKE-hosted CI runners):
#   # impersonate_service_account = "terraform@my-gcp-project.iam.gserviceaccount.com"
# }

###############################################################################
# Bootstrap resources (apply in a separate "bootstrap" step):
###############################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

variable "gcp_project" {
  description = "GCP project ID for the state backend resources."
  type        = string
}

variable "gcp_region" {
  description = "GCP region. Used only for provider configuration; GCS bucket uses var.bucket_location."
  type        = string
  default     = "us-central1"
}

variable "state_bucket_name" {
  description = "GCS bucket name for Terraform state. Must be globally unique."
  type        = string
  default     = ""
  # If empty, constructed as: one-deploy-dash-tfstate-${gcp_project}
}

variable "bucket_location" {
  description = "GCS bucket location (region, dual-region or multi-region such as US, EU)."
  type        = string
  default     = "US"
}

locals {
  resolved_bucket_name = var.state_bucket_name != "" ? var.state_bucket_name : "one-deploy-dash-tfstate-${var.gcp_project}"
}

resource "google_storage_bucket" "tfstate" {
  name                        = local.resolved_bucket_name
  project                     = var.gcp_project
  location                    = upper(var.bucket_location)
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 100
      is_live            = false
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  labels = {
    managed_by = "terraform"
    purpose    = "terraform-state"
  }
}

# Grant the Terraform service account access to the state bucket
resource "google_storage_bucket_iam_member" "tfstate_admin" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.terraform_sa_email}"
}

variable "terraform_sa_email" {
  description = "Email of the GCP service account that runs Terraform (granted objectAdmin on state bucket)."
  type        = string
}

output "state_bucket_name" {
  description = "Name of the GCS bucket holding Terraform state."
  value       = google_storage_bucket.tfstate.name
}

output "state_bucket_url" {
  description = "gs:// URL of the state bucket."
  value       = google_storage_bucket.tfstate.url
}
