###############################################################################
# GCP Artifact Registry Module – variables.tf
###############################################################################

variable "repository_id" {
  description = "Repository ID (lowercase letters, numbers, hyphens; 1-63 chars)."
  type        = string
}

variable "project" {
  description = "GCP project ID."
  type        = string
}

variable "location" {
  description = "GCP region for the repository."
  type        = string
}

variable "format" {
  description = "Repository format. Valid values: DOCKER, MAVEN, NPM, PYTHON, APT, YUM, GO, GENERIC."
  type        = string
  default     = "DOCKER"

  validation {
    condition     = contains(["DOCKER", "MAVEN", "NPM", "PYTHON", "APT", "YUM", "GO", "GENERIC"], upper(var.format))
    error_message = "format must be one of: DOCKER, MAVEN, NPM, PYTHON, APT, YUM, GO, GENERIC."
  }
}

variable "description" {
  description = "Human-readable description of the repository."
  type        = string
  default     = ""
}

variable "labels" {
  description = "Map of labels to apply to the repository."
  type        = map(string)
  default     = {}
}
