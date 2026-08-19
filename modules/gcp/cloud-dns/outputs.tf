###############################################################################
# GCP Cloud DNS Module – outputs.tf
###############################################################################

output "name_servers" {
  description = "Delegation name servers assigned to the managed zone."
  value       = google_dns_managed_zone.this.name_servers
}

output "managed_zone_id" {
  description = "Full resource ID of the managed zone."
  value       = google_dns_managed_zone.this.id
}
