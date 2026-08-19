###############################################################################
# Azure Service Principal Module – main.tf
# Creates: AAD Application, Service Principal, password credential, role assignment
###############################################################################

terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.47"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.11"
    }
  }
}

data "azuread_client_config" "current" {}

resource "azuread_application" "this" {
  display_name = var.app_name

  feature_tags {
    enterprise = true
    gallery    = false
  }
}

resource "azuread_service_principal" "this" {
  client_id                    = azuread_application.this.client_id
  app_role_assignment_required = false

  feature_tags {
    enterprise = true
  }
}

resource "time_rotating" "secret_rotation" {
  rotation_months = var.secret_expiry_months
}

resource "azuread_service_principal_password" "this" {
  service_principal_id = azuread_service_principal.this.id
  display_name         = "${var.app_name}-secret"

  rotate_when_changed = {
    rotation = time_rotating.secret_rotation.id
  }
}

resource "azurerm_role_assignment" "this" {
  scope                = var.scope
  role_definition_name = var.role_definition_name
  principal_id         = azuread_service_principal.this.object_id
}
