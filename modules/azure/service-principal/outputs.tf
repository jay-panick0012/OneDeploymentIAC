###############################################################################
# Azure Service Principal Module – outputs.tf
###############################################################################

output "application_id" {
  description = "Resource ID of the AAD application."
  value       = azuread_application.this.id
}

output "object_id" {
  description = "Object ID of the service principal in AAD."
  value       = azuread_service_principal.this.object_id
}

output "client_id" {
  description = "Client (Application) ID used for authentication."
  value       = azuread_application.this.client_id
}

output "client_secret" {
  description = "Client secret value. Store securely in Key Vault immediately after creation."
  value       = azuread_service_principal_password.this.value
  sensitive   = true
}

output "tenant_id" {
  description = "Azure Active Directory tenant ID."
  value       = data.azuread_client_config.current.tenant_id
}
