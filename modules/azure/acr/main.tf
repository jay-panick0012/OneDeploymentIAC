###############################################################################
# Azure ACR Module – main.tf
# Creates: Azure Container Registry with optional geo-replication
###############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_container_registry" "this" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.georeplications : []
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = lookup(georeplications.value, "zone_redundancy_enabled", false)
      tags                    = var.tags
    }
  }

  network_rule_bypass_option = "AzureServices"

  tags = merge(var.tags, { Name = var.registry_name })
}
