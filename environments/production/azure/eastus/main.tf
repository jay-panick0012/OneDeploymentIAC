###############################################################################
# Production Environment – Azure – eastus – main.tf
# Full-HA: Premium ACR, autoscaling AKS node pool.
###############################################################################

terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
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
  environment = "production"
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = var.owner
    Criticality = "high"
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
  subnet_names = ["aks-nodes", "data", "services", "management"]

  acr_sku                   = "Premium"
  keyvault_sku              = "premium"
  keyvault_soft_delete_days = 90
  keyvault_purge_protection = true

  aks_kubernetes_version  = var.kubernetes_version
  aks_vm_size             = "Standard_D8s_v3"
  aks_enable_auto_scaling = true
  aks_min_count           = 3
  aks_max_count           = 12

  alert_email = var.alert_email

  tags = local.common_tags
}
