###############################################################################
# GCP Region Stack Module – main.tf
# Composes: GCS, Artifact Registry, KMS, GKE, Cloud SQL, and optional
# Pub/Sub, Monitoring, and Cloud DNS into a single deployable stack for one
# GCP region. Called once per environments/<env>/gcp/<region>/ root, each
# with its own provider and state.
###############################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

locals {
  name_prefix            = "${var.project_name}-${var.environment}-${var.region}"
  name_prefix_underscore = replace(local.name_prefix, "-", "_")
  gcs_location           = var.gcs_location != "" ? var.gcs_location : upper(var.region)
  gke_master_cidr        = cidrsubnet("172.16.0.0/12", 16, var.region_index)
}

module "gcs_artifacts" {
  source = "../gcs"

  bucket_name        = "${local.name_prefix_underscore}_artifacts_${var.gcp_project}"
  project            = var.gcp_project
  location           = local.gcs_location
  storage_class      = var.gcs_storage_class
  versioning         = true
  lifecycle_age_days = var.gcs_lifecycle_age_days

  labels = var.labels
}

module "artifact_registry" {
  source = "../artifact-registry"

  repository_id = local.name_prefix
  project       = var.gcp_project
  location      = var.region
  format        = "DOCKER"
  description   = "Docker images for ${var.project_name} ${var.environment} (${var.region})"

  labels = var.labels
}

module "kms" {
  source = "../kms"

  key_ring_name        = local.name_prefix
  key_name             = "default"
  project              = var.gcp_project
  location             = var.region
  rotation_period_days = var.kms_rotation_period_days
  protection_level     = var.kms_protection_level

  labels = var.labels
}

module "gke" {
  source = "../gke"

  cluster_name               = local.name_prefix
  project                    = var.gcp_project
  location                   = var.region
  mode                       = var.gke_mode
  node_count                 = var.gke_node_count
  machine_type               = var.gke_machine_type
  kubernetes_release_channel = var.gke_release_channel
  enable_workload_identity   = true
  enable_private_cluster     = var.gke_enable_private_cluster
  master_ipv4_cidr_block     = local.gke_master_cidr
}

module "cloudsql" {
  source = "../cloudsql"

  instance_name     = local.name_prefix
  project           = var.gcp_project
  region            = var.region
  database_version  = "POSTGRES_16"
  tier              = var.cloudsql_tier
  high_availability = var.cloudsql_high_availability
  backup_enabled    = true
  backup_start_time = var.cloudsql_backup_start_time
  disk_size_gb      = var.cloudsql_disk_size_gb

  labels = var.labels
}

module "messaging" {
  source = "../pubsub"
  count  = var.enable_messaging ? 1 : 0

  topic_name        = "${local.name_prefix}-events"
  project           = var.gcp_project
  subscription_name = "${local.name_prefix}-events-sub"

  labels = var.labels
}

module "monitoring" {
  source = "../monitoring"
  count  = var.enable_monitoring ? 1 : 0

  project                            = var.gcp_project
  notification_channel_display_name  = "${local.name_prefix}-notify"
  notification_email                 = var.notification_email
  alert_policy_display_name          = "${local.name_prefix}-gke-cpu-high"
  alert_condition_filter             = "resource.type=\"k8s_node\" AND metric.type=\"kubernetes.io/node/cpu/allocatable_utilization\""
}

module "dns" {
  source = "../cloud-dns"
  count  = var.enable_dns ? 1 : 0

  zone_name = var.dns_zone_name
  dns_name  = var.dns_domain
  project   = var.gcp_project

  labels = var.labels
}
