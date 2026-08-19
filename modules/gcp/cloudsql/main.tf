###############################################################################
# GCP Cloud SQL Module – main.tf
# Creates: Cloud SQL instance with HA, backups, and a database
###############################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "this" {
  name             = "${var.instance_name}-${random_id.suffix.hex}"
  project          = var.project
  region           = var.region
  database_version = var.database_version

  deletion_protection = true

  settings {
    tier              = var.tier
    availability_type = var.high_availability ? "REGIONAL" : "ZONAL"
    disk_size         = var.disk_size_gb
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.backup_start_time
      location                       = var.region
      point_in_time_recovery_enabled = var.high_availability
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = 14
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = null # Set via var or data source in calling module
      ssl_mode        = "ENCRYPTED_ONLY"
    }

    maintenance_window {
      day          = 7  # Sunday
      hour         = 3
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = false
    }

    user_labels = var.labels
  }
}

resource "google_sql_database" "this" {
  name     = var.instance_name
  project  = var.project
  instance = google_sql_database_instance.this.name
}
