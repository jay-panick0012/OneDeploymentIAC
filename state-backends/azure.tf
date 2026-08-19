###############################################################################
# State Backend – Azure Blob Storage
#
# Bootstrap steps (run once before `terraform init`):
#
#   1. Create resource group, storage account, and container:
#      az group create \
#        --name one-deploy-dash-tfstate-rg \
#        --location eastus
#
#      az storage account create \
#        --name onedeploydashtfstate \
#        --resource-group one-deploy-dash-tfstate-rg \
#        --location eastus \
#        --sku Standard_LRS \
#        --encryption-services blob \
#        --min-tls-version TLS1_2
#
#      az storage container create \
#        --name tfstate \
#        --account-name onedeploydashtfstate \
#        --public-access off
#
#   2. Enable versioning on the storage account:
#      az storage account blob-service-properties update \
#        --account-name onedeploydashtfstate \
#        --resource-group one-deploy-dash-tfstate-rg \
#        --enable-versioning true
#
#   3. Add the backend block to each environment's main.tf and run
#      `terraform init`. The blob key path isolates each environment.
###############################################################################

# backend "azurerm" {
#   resource_group_name  = "one-deploy-dash-tfstate-rg"
#   storage_account_name = "onedeploydashtfstate"
#   container_name       = "tfstate"
#   key                  = "environments/${terraform.workspace}/terraform.tfstate"
#
#   # Authentication options (choose one):
#   # Option A – Service Principal (recommended for CI):
#   #   use_oidc        = true   # or use_azuread_auth = true
#   #   subscription_id = "00000000-0000-0000-0000-000000000000"
#   #   tenant_id       = "00000000-0000-0000-0000-000000000000"
#   #   client_id       = "00000000-0000-0000-0000-000000000000"
#   #
#   # Option B – Managed Identity (for Azure-hosted runners):
#   #   use_msi = true
# }

###############################################################################
# Bootstrap resources (apply in a separate "bootstrap" step):
###############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

variable "azure_subscription_id" {
  description = "Azure subscription ID for the state backend resources."
  type        = string
}

variable "state_resource_group" {
  description = "Resource group name for Terraform state resources."
  type        = string
  default     = "one-deploy-dash-tfstate-rg"
}

variable "state_storage_account_name" {
  description = "Storage account name (3-24 lowercase alphanumeric, globally unique)."
  type        = string
  default     = "onedeploydashtfstate"
}

variable "state_location" {
  description = "Azure region for state backend resources."
  type        = string
  default     = "eastus"
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.state_resource_group
  location = var.state_location

  tags = {
    ManagedBy = "terraform"
    Purpose   = "terraform-state"
  }
}

resource "azurerm_storage_account" "tfstate" {
  name                            = var.state_storage_account_name
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"       # geo-redundant for state durability
  account_kind                    = "StorageV2"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false       # enforce Azure AD auth
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 90
    }
    container_delete_retention_policy {
      days = 90
    }
  }

  tags = {
    ManagedBy = "terraform"
    Purpose   = "terraform-state"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

output "storage_account_name" {
  description = "Name of the Azure storage account holding Terraform state."
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Name of the blob container holding Terraform state."
  value       = azurerm_storage_container.tfstate.name
}
