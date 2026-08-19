###############################################################################
# GCP Monitoring Module – main.tf
# Creates: Email notification channel and an alert policy
###############################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

resource "google_monitoring_notification_channel" "email" {
  project      = var.project
  display_name = var.notification_channel_display_name
  type         = "email"

  labels = {
    email_address = var.notification_email
  }
}

resource "google_monitoring_alert_policy" "this" {
  project      = var.project
  display_name = var.alert_policy_display_name
  combiner     = var.combiner

  conditions {
    display_name = var.alert_condition_display_name

    condition_threshold {
      filter          = var.alert_condition_filter
      duration        = var.alert_duration
      comparison      = "COMPARISON_GT"
      threshold_value = var.alert_threshold_value

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}
