###############################################################################
# GCP Artifact Registry Module – outputs.tf
###############################################################################

output "repository_id" {
  description = "Repository ID."
  value       = google_artifact_registry_repository.this.repository_id
}

output "repository_name" {
  description = "Full resource name of the repository."
  value       = google_artifact_registry_repository.this.name
}

output "create_time" {
  description = "Time at which the repository was created."
  value       = google_artifact_registry_repository.this.create_time
}

output "docker_uri" {
  description = "Docker URI prefix for the repository (only meaningful when format = DOCKER)."
  value       = "${var.location}-docker.pkg.dev/${var.project}/${var.repository_id}"
}
