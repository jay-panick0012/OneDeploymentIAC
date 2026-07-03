###############################################################################
# AWS EKS Module – variables.tf
###############################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.30"
}

variable "region" {
  description = "AWS region where the cluster is deployed."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC in which to create the EKS cluster."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs (private subnets recommended for nodes)."
  type        = list(string)
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
}

variable "disk_size_gb" {
  description = "EBS disk size in GB for each node."
  type        = number
  default     = 50
}

variable "environment" {
  description = "Deployment environment (dev, staging, production)."
  type        = string
}

variable "private_endpoint" {
  description = "Enable private API server endpoint. When true, public endpoint is disabled."
  type        = bool
  default     = false
}

variable "enable_oidc" {
  description = "Create an OIDC provider to enable IAM Roles for Service Accounts (IRSA)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
