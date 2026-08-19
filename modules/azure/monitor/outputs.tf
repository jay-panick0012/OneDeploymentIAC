###############################################################################
# Azure Monitor Module – outputs.tf
###############################################################################

output "workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_primary_shared_key" {
  description = "Primary shared key of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "action_group_id" {
  description = "Resource ID of the Monitor action group."
  value       = azurerm_monitor_action_group.this.id
}
