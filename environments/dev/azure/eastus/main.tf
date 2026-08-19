###############################################################################
# Dev Environment – Azure – eastus – main.tf
# Cost-optimized: Basic ACR, fixed node count, no HA.
###############################################################################

terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.azure_subscription_id
}

locals {
  environment = "dev"
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}

###############################################################################
# Azure – Region Stack
###############################################################################

module "stack" {
  source = "../../../../modules/azure/region-stack"

  project_name = var.project_name
  environment  = local.environment
  location     = var.location
  region_index = var.region_index

  acr_sku                   = "Basic"
  keyvault_sku              = "standard"
  keyvault_soft_delete_days = 7
  keyvault_purge_protection = false

  aks_kubernetes_version  = var.kubernetes_version
  aks_vm_size             = "Standard_D2s_v3"
  aks_node_count          = 2
  aks_enable_auto_scaling = false

  alert_email = var.alert_email

  tags = local.common_tags
}
