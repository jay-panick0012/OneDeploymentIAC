###############################################################################
# Azure ACR Module – outputs.tf
###############################################################################

output "registry_id" {
  description = "Resource ID of the Azure Container Registry."
  value       = azurerm_container_registry.this.id
}

output "login_server" {
  description = "Login server URL of the registry (e.g. myregistry.azurecr.io)."
  value       = azurerm_container_registry.this.login_server
}

output "admin_username" {
  description = "Admin username for the registry. Empty string when admin_enabled = false."
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_username : ""
  sensitive   = true
}

output "admin_password" {
  description = "Admin password for the registry. Empty string when admin_enabled = false."
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_password : ""
  sensitive   = true
}

output "registry_name" {
  description = "Name of the container registry."
  value       = azurerm_container_registry.this.name
}
