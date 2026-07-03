###############################################################################
# Azure AKS Module – outputs.tf
###############################################################################

output "cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.id
}

output "kube_config" {
  description = "Raw kubeconfig for the AKS cluster. Handle as sensitive."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster API server."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "kubelet_identity" {
  description = "Kubelet identity object_id (used for ACR pull role assignments)."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "cluster_principal_id" {
  description = "Principal ID of the system-assigned managed identity."
  value       = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "resource_group_name" {
  description = "Name of the resource group containing the cluster."
  value       = azurerm_resource_group.this.name
}

output "node_resource_group" {
  description = "Auto-generated resource group containing cluster nodes."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}
