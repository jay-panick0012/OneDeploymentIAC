###############################################################################
# Azure Key Vault Module – main.tf
# Creates: Key Vault with access policy for the calling principal
###############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = var.vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku
  soft_delete_retention_days = var.soft_delete_days
  purge_protection_enabled   = var.purge_protection

  rbac_authorization_enabled = false

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = []
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create", "Delete", "Get", "Import", "List",
      "Purge", "Recover", "Restore", "Update", "GetRotationPolicy",
    ]

    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set",
    ]

    certificate_permissions = [
      "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers",
      "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers",
      "Purge", "Recover", "Restore", "SetIssuers", "Update",
    ]
  }

  tags = merge(var.tags, { Name = var.vault_name })
}
