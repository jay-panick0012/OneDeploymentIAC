###############################################################################
# Azure Monitor Module – main.tf
# Creates: Log Analytics workspace, action group, and metric alert
###############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days

  tags = merge(var.tags, { Name = var.workspace_name })
}

resource "azurerm_monitor_action_group" "this" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name

  dynamic "email_receiver" {
    for_each = var.email_receivers
    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.email_address
    }
  }

  tags = merge(var.tags, { Name = var.action_group_name })
}

resource "azurerm_monitor_metric_alert" "this" {
  count = length(var.alert_scopes) > 0 ? 1 : 0

  name                = var.alert_name
  resource_group_name = var.resource_group_name
  scopes              = var.alert_scopes

  criteria {
    metric_namespace = var.alert_criteria_metric_namespace
    metric_name      = var.alert_criteria_metric_name
    aggregation      = var.alert_criteria_aggregation
    operator         = var.alert_criteria_operator
    threshold        = var.alert_criteria_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }

  tags = merge(var.tags, { Name = var.alert_name })
}
