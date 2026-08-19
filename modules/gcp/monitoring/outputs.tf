###############################################################################
# GCP Monitoring Module – outputs.tf
###############################################################################

output "notification_channel_id" {
  description = "Full resource ID of the email notification channel."
  value       = google_monitoring_notification_channel.email.id
}

output "alert_policy_id" {
  description = "Full resource ID of the alert policy."
  value       = google_monitoring_alert_policy.this.name
}
