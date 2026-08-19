###############################################################################
# Azure Region Stack Module – variables.tf
###############################################################################

variable "project_name" {
  description = "Short name of the project (used as prefix for resource names)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, production)."
  type        = string
}

variable "location" {
  description = "Azure region this stack is deployed into (e.g. eastus, westeurope)."
  type        = string
}

variable "region_index" {
  description = "Zero-based index of this region within the environment's region list. Used to derive a non-overlapping /16 CIDR block via cidrsubnet(var.vnet_supernet, 8, region_index). Each environment/region combination across the whole repo must use a unique index to avoid CIDR collisions."
  type        = number
}

variable "vnet_supernet" {
  description = "Supernet that this region's VNet /16 is carved out of."
  type        = string
  default     = "10.0.0.0/8"
}

variable "subnet_names" {
  description = "Names of subnets to create inside the VNet. One CIDR is derived per entry."
  type        = list(string)
  default     = ["aks-nodes", "data"]
}

variable "acr_sku" {
  description = "SKU for the Container Registry. Valid values: Basic, Standard, Premium."
  type        = string
  default     = "Standard"
}

variable "acr_georeplications" {
  description = "List of geo-replication locations for the registry. Only applied when acr_sku = Premium."
  type = list(object({
    location                = string
    zone_redundancy_enabled = optional(bool, false)
  }))
  default = []
}

variable "keyvault_sku" {
  description = "SKU for the Key Vault. Valid values: standard, premium."
  type        = string
  default     = "standard"
}

variable "keyvault_soft_delete_days" {
  description = "Number of days to retain deleted Key Vault objects (7-90)."
  type        = number
  default     = 90
}

variable "keyvault_purge_protection" {
  description = "Enable Key Vault purge protection. Mandatory for production."
  type        = bool
  default     = true
}

variable "aks_kubernetes_version" {
  description = "Kubernetes version for the AKS cluster."
  type        = string
  default     = "1.30"
}

variable "aks_vm_size" {
  description = "VM size for nodes in the default AKS node pool."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "aks_node_count" {
  description = "Fixed node count for the default node pool. Used when aks_enable_auto_scaling is false."
  type        = number
  default     = 2
}

variable "aks_enable_auto_scaling" {
  description = "Enable cluster autoscaler on the default node pool."
  type        = bool
  default     = false
}

variable "aks_min_count" {
  description = "Minimum node count when autoscaling is enabled."
  type        = number
  default     = 1
}

variable "aks_max_count" {
  description = "Maximum node count when autoscaling is enabled."
  type        = number
  default     = 5
}

variable "enable_messaging" {
  description = "Create the Service Bus namespace + queue for this region."
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Create the Log Analytics workspace, action group, and metric alert for this region."
  type        = bool
  default     = true
}

variable "enable_dns" {
  description = "Create an Azure DNS zone for this region."
  type        = bool
  default     = false
}

variable "dns_zone_name" {
  description = "Domain name for the Azure DNS zone. Required when enable_dns = true."
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email address to receive monitoring alerts. Required when enable_monitoring = true."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
