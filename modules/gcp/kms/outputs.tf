###############################################################################
# GCP KMS Module – outputs.tf
###############################################################################

output "key_ring_id" {
  description = "Full resource ID of the KMS key ring."
  value       = google_kms_key_ring.this.id
}

output "crypto_key_id" {
  description = "Full resource ID of the KMS crypto key."
  value       = google_kms_crypto_key.this.id
}

output "key_ring_name" {
  description = "Name of the KMS key ring."
  value       = google_kms_key_ring.this.name
}

output "crypto_key_name" {
  description = "Name of the KMS crypto key."
  value       = google_kms_crypto_key.this.name
}
