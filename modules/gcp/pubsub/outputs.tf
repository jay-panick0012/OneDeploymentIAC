###############################################################################
# GCP Pub/Sub Module – outputs.tf
###############################################################################

output "topic_id" {
  description = "Full resource ID of the Pub/Sub topic."
  value       = google_pubsub_topic.this.id
}

output "subscription_id" {
  description = "Full resource ID of the Pub/Sub subscription."
  value       = google_pubsub_subscription.this.id
}

output "dead_letter_topic_id" {
  description = "Full resource ID of the dead-letter topic, or an empty string when disabled."
  value       = var.enable_dead_letter ? google_pubsub_topic.dead_letter[0].id : ""
}
