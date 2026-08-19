###############################################################################
# GCP Pub/Sub Module – main.tf
# Creates: Pub/Sub topic, subscription, and optional dead-letter topic
###############################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

resource "google_pubsub_topic" "this" {
  name    = var.topic_name
  project = var.project
  labels  = var.labels
}

resource "google_pubsub_topic" "dead_letter" {
  count = var.enable_dead_letter ? 1 : 0

  name    = "${var.topic_name}-dead-letter"
  project = var.project
  labels  = var.labels
}

resource "google_pubsub_subscription" "this" {
  name    = var.subscription_name
  project = var.project
  topic   = google_pubsub_topic.this.id

  ack_deadline_seconds       = var.ack_deadline_seconds
  message_retention_duration = var.message_retention_duration

  dynamic "dead_letter_policy" {
    for_each = var.enable_dead_letter ? [1] : []
    content {
      dead_letter_topic     = google_pubsub_topic.dead_letter[0].id
      max_delivery_attempts = var.dead_letter_max_delivery_attempts
    }
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  labels = var.labels
}
