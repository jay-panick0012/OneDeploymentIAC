###############################################################################
# Azure Region Stack Module – main.tf
# Composes: Resource Group, VNet, ACR, Key Vault, AKS, and optional Service
# Bus, Monitor, and DNS into a single deployable stack for one Azure region.
# Called once per environments/<env>/azure/<region>/ root, each with its own
# provider and state.
###############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  name_prefix         = "${var.project_name}-${var.environment}-${var.location}"
  name_compact        = lower(replace(local.name_prefix, "-", ""))
  resource_group_name = "${local.name_prefix}-rg"
  vnet_cidr           = cidrsubnet(var.vnet_supernet, 8, var.region_index)
  subnets = [
    for i, name in var.subnet_names : {
      name           = name
      address_prefix = cidrsubnet(local.vnet_cidr, 8, i + 1)
    }
  ]
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location

  tags = var.tags
}

module "vnet" {
  source = "../vnet"

  vnet_name           = "${local.name_prefix}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = [local.vnet_cidr]
  subnets             = local.subnets

  tags = var.tags
}

module "acr" {
  source = "../acr"

  registry_name       = "${local.name_compact}acr"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = var.acr_sku
  admin_enabled       = false
  georeplications     = var.acr_georeplications

  tags = var.tags

  depends_on = [module.vnet]
}

module "keyvault" {
  source = "../keyvault"

  vault_name          = "${local.name_compact}kv"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = var.keyvault_sku
  soft_delete_days    = var.keyvault_soft_delete_days
  purge_protection    = var.keyvault_purge_protection

  tags = var.tags

  depends_on = [module.vnet]
}

module "aks" {
  source = "../aks"

  cluster_name        = "${local.name_prefix}-aks"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  kubernetes_version  = var.aks_kubernetes_version
  node_count          = var.aks_node_count
  vm_size             = var.aks_vm_size
  enable_auto_scaling = var.aks_enable_auto_scaling
  min_count           = var.aks_min_count
  max_count           = var.aks_max_count
  network_plugin      = "azure"
  enable_rbac         = true
  environment         = var.environment

  tags = var.tags

  depends_on = [module.vnet]
}

module "messaging" {
  source = "../servicebus"
  count  = var.enable_messaging ? 1 : 0

  namespace_name      = "${local.name_prefix}-sbns"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  queue_name          = "${local.name_prefix}-events"

  tags = var.tags
}

module "monitoring" {
  source = "../monitor"
  count  = var.enable_monitoring ? 1 : 0

  workspace_name          = "${local.name_prefix}-logs"
  resource_group_name     = azurerm_resource_group.this.name
  location                = azurerm_resource_group.this.location
  action_group_name       = "${local.name_prefix}-alerts"
  action_group_short_name = substr(local.name_compact, 0, 12)
  email_receivers = var.alert_email != "" ? [
    { name = "primary", email_address = var.alert_email }
  ] : []
  alert_scopes = [module.aks.cluster_id]

  tags = var.tags
}

module "dns" {
  source = "../dns"
  count  = var.enable_dns ? 1 : 0

  zone_name           = var.dns_zone_name
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}
