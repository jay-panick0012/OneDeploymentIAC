###############################################################################
# Azure Service Bus Module – outputs.tf
###############################################################################

output "namespace_id" {
  description = "Resource ID of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.this.id
}

output "namespace_default_connection_string" {
  description = "Default primary connection string for the Service Bus namespace."
  value       = azurerm_servicebus_namespace.this.default_primary_connection_string
  sensitive   = true
}

output "queue_id" {
  description = "Resource ID of the Service Bus queue."
  value       = azurerm_servicebus_queue.this.id
}
