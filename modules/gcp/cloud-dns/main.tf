###############################################################################
# GCP Cloud DNS Module – main.tf
# Creates: Cloud DNS managed zone and record sets
###############################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

resource "google_dns_managed_zone" "this" {
  name        = var.zone_name
  dns_name    = var.dns_name
  project     = var.project
  description = var.description
  labels      = var.labels
}

resource "google_dns_record_set" "this" {
  for_each = { for record in var.records : "${record.name}-${record.type}" => record }

  name         = each.value.name
  type         = each.value.type
  ttl          = each.value.ttl
  managed_zone = google_dns_managed_zone.this.name
  project      = var.project
  rrdatas      = each.value.rrdatas
}
