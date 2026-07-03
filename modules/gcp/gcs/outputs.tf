###############################################################################
# GCP GCS Module – outputs.tf
###############################################################################

output "bucket_name" {
  description = "Name of the GCS bucket."
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "Base URL of the bucket in gs:// form."
  value       = google_storage_bucket.this.url
}

output "self_link" {
  description = "URI of the bucket."
  value       = google_storage_bucket.this.self_link
}

output "storage_class" {
  description = "Storage class of the bucket."
  value       = google_storage_bucket.this.storage_class
}
