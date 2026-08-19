###############################################################################
# Azure Service Bus Module – main.tf
# Creates: Service Bus namespace and queue
###############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100"
    }
  }
}

resource "azurerm_servicebus_namespace" "this" {
  name                = var.namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  tags = merge(var.tags, { Name = var.namespace_name })
}

resource "azurerm_servicebus_queue" "this" {
  name         = var.queue_name
  namespace_id = azurerm_servicebus_namespace.this.id

  max_delivery_count = var.max_delivery_count
  lock_duration      = var.lock_duration
}
