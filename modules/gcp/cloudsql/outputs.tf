###############################################################################
# GCP Cloud SQL Module – outputs.tf
###############################################################################

output "connection_name" {
  description = "Connection name for Cloud SQL Proxy (PROJECT:REGION:INSTANCE)."
  value       = google_sql_database_instance.this.connection_name
}

output "self_link" {
  description = "Self link of the Cloud SQL instance."
  value       = google_sql_database_instance.this.self_link
}

output "private_ip_address" {
  description = "Private IP address of the Cloud SQL instance."
  value       = google_sql_database_instance.this.private_ip_address
}

output "service_account_email_address" {
  description = "Service account email address for the Cloud SQL instance (used for IAM auth)."
  value       = google_sql_database_instance.this.service_account_email_address
}

output "instance_name" {
  description = "Full name of the Cloud SQL instance (includes random suffix)."
  value       = google_sql_database_instance.this.name
}

output "database_name" {
  description = "Name of the database created in the instance."
  value       = google_sql_database.this.name
}
