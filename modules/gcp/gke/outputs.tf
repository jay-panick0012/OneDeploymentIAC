###############################################################################
# GCP GKE Module – outputs.tf
###############################################################################

locals {
  cluster = var.mode == "autopilot" ? google_container_cluster.autopilot[0] : google_container_cluster.standard[0]
}

output "cluster_id" {
  description = "Identifier of the GKE cluster."
  value       = local.cluster.id
}

output "cluster_endpoint" {
  description = "IP address of the GKE cluster master endpoint."
  value       = local.cluster.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded public certificate authority for the cluster."
  value       = local.cluster.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_name" {
  description = "Name of the GKE cluster."
  value       = local.cluster.name
}

output "cluster_location" {
  description = "Region or zone where the cluster is located."
  value       = local.cluster.location
}

output "workload_identity_pool" {
  description = "Workload identity pool (PROJECT_ID.svc.id.goog)."
  value       = var.enable_workload_identity ? "${var.project}.svc.id.goog" : ""
}
