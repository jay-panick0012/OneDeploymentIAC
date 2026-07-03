###############################################################################
# GCP GKE Module – variables.tf
###############################################################################

variable "cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
}

variable "project" {
  description = "GCP project ID."
  type        = string
}

variable "location" {
  description = "GCP region or zone for the cluster. Use a region for regional (HA) clusters."
  type        = string
}

variable "mode" {
  description = "Cluster mode. Valid values: autopilot, standard."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["autopilot", "standard"], var.mode)
    error_message = "mode must be autopilot or standard."
  }
}

variable "network" {
  description = "VPC network name or self_link."
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "VPC subnetwork name or self_link."
  type        = string
  default     = "default"
}

variable "node_count" {
  description = "Initial node count per zone (standard mode only)."
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for cluster nodes (standard mode only)."
  type        = string
  default     = "e2-medium"
}

variable "kubernetes_release_channel" {
  description = "Release channel for automatic upgrades. Valid values: rapid, regular, stable, unspecified."
  type        = string
  default     = "regular"

  validation {
    condition     = contains(["rapid", "regular", "stable", "unspecified"], var.kubernetes_release_channel)
    error_message = "kubernetes_release_channel must be rapid, regular, stable, or unspecified."
  }
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for pod-level GCP IAM."
  type        = bool
  default     = true
}

variable "enable_private_cluster" {
  description = "Enable private nodes (nodes get private IP addresses only)."
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the master network (required when enable_private_cluster = true)."
  type        = string
  default     = "172.16.0.0/28"
}

variable "tags" {
  description = "Map of labels to apply. Note: GKE uses labels, not tags."
  type        = map(string)
  default     = {}
}
