###############################################################################
# GCP GKE Module – main.tf
# Creates: GKE cluster (autopilot or standard), node pool, private networking
###############################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

locals {
  is_autopilot = var.mode == "autopilot"
}

###############################################################################
# Autopilot Cluster
###############################################################################

resource "google_container_cluster" "autopilot" {
  count    = local.is_autopilot ? 1 : 0
  provider = google

  name     = var.cluster_name
  project  = var.project
  location = var.location

  enable_autopilot = true

  network    = var.network
  subnetwork = var.subnetwork

  private_cluster_config {
    enable_private_nodes    = var.enable_private_cluster
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  workload_identity_config {
    workload_pool = var.enable_workload_identity ? "${var.project}.svc.id.goog" : ""
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  release_channel {
    channel = upper(var.kubernetes_release_channel)
  }

  ip_allocation_policy {}

  deletion_protection = false
}

###############################################################################
# Standard Cluster
###############################################################################

resource "google_container_cluster" "standard" {
  count    = local.is_autopilot ? 0 : 1
  provider = google

  name     = var.cluster_name
  project  = var.project
  location = var.location

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network
  subnetwork = var.subnetwork

  private_cluster_config {
    enable_private_nodes    = var.enable_private_cluster
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  workload_identity_config {
    workload_pool = var.enable_workload_identity ? "${var.project}.svc.id.goog" : ""
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  release_channel {
    channel = upper(var.kubernetes_release_channel)
  }

  ip_allocation_policy {}

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  deletion_protection = false
}

###############################################################################
# Node Pool (standard mode only)
###############################################################################

resource "google_container_node_pool" "primary" {
  count    = local.is_autopilot ? 0 : 1
  provider = google

  name     = "${var.cluster_name}-primary-pool"
  project  = var.project
  cluster  = google_container_cluster.standard[0].name
  location = var.location

  initial_node_count = var.node_count

  autoscaling {
    min_node_count = var.node_count
    max_node_count = var.node_count * 3
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    disk_type    = "pd-ssd"
    disk_size_gb = 50
    image_type   = "COS_CONTAINERD"

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/trace.append",
    ]

    workload_metadata_config {
      mode = var.enable_workload_identity ? "GKE_METADATA" : "MODE_UNSPECIFIED"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}
