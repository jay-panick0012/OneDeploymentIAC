###############################################################################
# Azure Region Stack Module – outputs.tf
###############################################################################

output "resource_group_name" {
  description = "Name of the region's resource group."
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "Resource ID of the region's virtual network."
  value       = module.vnet.vnet_id
}

output "acr_login_server" {
  description = "Login server URL of the region's Container Registry."
  value       = module.acr.login_server
}

output "keyvault_uri" {
  description = "URI of the region's Key Vault."
  value       = module.keyvault.vault_uri
}

output "aks_cluster_id" {
  description = "Resource ID of the region's AKS cluster."
  value       = module.aks.cluster_id
}

output "aks_cluster_fqdn" {
  description = "FQDN of the region's AKS cluster API server."
  value       = module.aks.cluster_fqdn
}

output "servicebus_namespace_id" {
  description = "Resource ID of the region's Service Bus namespace. Empty string when enable_messaging = false."
  value       = var.enable_messaging ? module.messaging[0].namespace_id : ""
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the region's Log Analytics workspace. Empty string when enable_monitoring = false."
  value       = var.enable_monitoring ? module.monitoring[0].workspace_id : ""
}

output "dns_zone_id" {
  description = "Resource ID of the region's DNS zone. Empty string when enable_dns = false."
  value       = var.enable_dns ? module.dns[0].zone_id : ""
}
