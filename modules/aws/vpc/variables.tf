###############################################################################
# AWS VPC Module – variables.tf
###############################################################################

variable "vpc_name" {
  description = "Name prefix for all VPC resources."
  type        = string
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets. One per AZ recommended."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets. One per AZ recommended."
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to place subnets in."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (cost-saving for dev). When false, one NAT per AZ."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
