###############################################################################
# Azure DNS Module – main.tf
# Creates: Public DNS zone and A, CNAME, and TXT records
###############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  a_records     = { for r in var.records : r.name => r if r.type == "A" }
  cname_records = { for r in var.records : r.name => r if r.type == "CNAME" }
  txt_records   = { for r in var.records : r.name => r if r.type == "TXT" }
}

resource "azurerm_dns_zone" "this" {
  name                = var.zone_name
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, { Name = var.zone_name })
}

resource "azurerm_dns_a_record" "a" {
  for_each = local.a_records

  name                = each.value.name
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.values

  tags = var.tags
}

resource "azurerm_dns_cname_record" "cname" {
  for_each = local.cname_records

  name                = each.value.name
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.values[0]

  tags = var.tags
}

resource "azurerm_dns_txt_record" "txt" {
  for_each = local.txt_records

  name                = each.value.name
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.values
    content {
      value = record.value
    }
  }

  tags = var.tags
}
