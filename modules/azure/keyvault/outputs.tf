###############################################################################
# Azure Key Vault Module – outputs.tf
###############################################################################

output "vault_id" {
  description = "Resource ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "vault_uri" {
  description = "URI of the Key Vault (e.g. https://myvault.vault.azure.net/)."
  value       = azurerm_key_vault.this.vault_uri
}

output "tenant_id" {
  description = "Tenant ID associated with the Key Vault."
  value       = azurerm_key_vault.this.tenant_id
}

output "vault_name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.this.name
}
