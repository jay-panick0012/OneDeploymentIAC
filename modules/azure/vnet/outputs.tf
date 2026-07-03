###############################################################################
# Azure VNet Module – outputs.tf
###############################################################################

output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet name to subnet resource ID."
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "nsg_ids" {
  description = "Map of subnet name to associated NSG resource ID."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "address_space" {
  description = "Address space of the virtual network."
  value       = azurerm_virtual_network.this.address_space
}
