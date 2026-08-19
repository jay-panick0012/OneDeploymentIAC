###############################################################################
# GCP Region Stack Module – outputs.tf
###############################################################################

output "gcs_artifacts_bucket_name" {
  description = "Name of the region's GCS artifacts bucket."
  value       = module.gcs_artifacts.bucket_name
}

output "artifact_registry_docker_uri" {
  description = "Docker URI prefix of the region's Artifact Registry repository."
  value       = module.artifact_registry.docker_uri
}

output "kms_crypto_key_id" {
  description = "Full resource ID of the region's KMS crypto key."
  value       = module.kms.crypto_key_id
}

output "gke_cluster_name" {
  description = "Name of the region's GKE cluster."
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "Endpoint of the region's GKE cluster master."
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "cloudsql_connection_name" {
  description = "Connection name of the region's Cloud SQL instance (PROJECT:REGION:INSTANCE)."
  value       = module.cloudsql.connection_name
}

output "pubsub_topic_id" {
  description = "Full resource ID of the region's Pub/Sub topic. Empty string when enable_messaging = false."
  value       = var.enable_messaging ? module.messaging[0].topic_id : ""
}

output "monitoring_alert_policy_id" {
  description = "Resource ID of the region's alert policy. Empty string when enable_monitoring = false."
  value       = var.enable_monitoring ? module.monitoring[0].alert_policy_id : ""
}

output "dns_managed_zone_id" {
  description = "Resource ID of the region's Cloud DNS managed zone. Empty string when enable_dns = false."
  value       = var.enable_dns ? module.dns[0].managed_zone_id : ""
}
