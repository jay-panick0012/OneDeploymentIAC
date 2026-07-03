###############################################################################
# AWS RDS Module – variables.tf
###############################################################################

variable "identifier" {
  description = "Unique identifier for the RDS instance."
  type        = string
}

variable "engine" {
  description = "Database engine. Valid values: mysql, postgres, mariadb, oracle-ee, sqlserver-ex."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Database engine version."
  type        = string
  default     = "16.2"
}

variable "instance_class" {
  description = "RDS instance class (e.g. db.t3.medium, db.r6g.large)."
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Allocated storage in GiB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the initial database to create."
  type        = string
}

variable "username" {
  description = "Master username for the database."
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups (0 disables backups)."
  type        = number
  default     = 7
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group (should be private subnets)."
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs to associate with the DB instance."
  type        = list(string)
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
