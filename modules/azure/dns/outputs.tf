###############################################################################
# Azure DNS Module – outputs.tf
###############################################################################

output "zone_id" {
  description = "Resource ID of the public DNS zone."
  value       = azurerm_dns_zone.this.id
}

output "name_servers" {
  description = "Name servers assigned to the DNS zone."
  value       = azurerm_dns_zone.this.name_servers
}
