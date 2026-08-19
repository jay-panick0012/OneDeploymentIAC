###############################################################################
# Staging Environment – Azure – westeurope – main.tf
# Mid-tier sizing: Standard ACR/Key Vault, AKS autoscaling.
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
  environment = "staging"
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

  subnet_names = ["aks-nodes", "data", "services"]

  acr_sku                   = "Standard"
  keyvault_sku              = "standard"
  keyvault_soft_delete_days = 30
  keyvault_purge_protection = true

  aks_kubernetes_version  = var.kubernetes_version
  aks_vm_size             = "Standard_D4s_v3"
  aks_enable_auto_scaling = true
  aks_min_count           = 2
  aks_max_count           = 6

  alert_email = var.alert_email

  tags = local.common_tags
}
