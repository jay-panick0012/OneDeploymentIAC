###############################################################################
# Azure AKS Module – main.tf
# Creates: AKS cluster with Azure CNI, SystemAssigned identity, RBAC, and
#          optional autoscaling. Deploys into an existing resource group
#          (resource_group_name) shared with sibling modules (vnet, acr,
#          keyvault) rather than creating its own.
###############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                         = "system"
    node_count                   = var.enable_auto_scaling ? null : var.node_count
    vm_size                      = var.vm_size
    auto_scaling_enabled         = var.enable_auto_scaling
    min_count                    = var.enable_auto_scaling ? var.min_count : null
    max_count                    = var.enable_auto_scaling ? var.max_count : null
    os_disk_size_gb              = 50
    type                         = "VirtualMachineScaleSets"
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = var.network_plugin
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = var.enable_rbac
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  auto_scaler_profile {
    balance_similar_node_groups = true
    expander                    = "random"
  }

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

###############################################################################
# Log Analytics Workspace (for Container Insights)
###############################################################################

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.cluster_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}
