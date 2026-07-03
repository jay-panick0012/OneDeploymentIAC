###############################################################################
# AWS RDS Module – outputs.tf
###############################################################################

output "db_endpoint" {
  description = "Connection endpoint of the RDS instance (host:port)."
  value       = aws_db_instance.this.endpoint
}

output "db_port" {
  description = "Port the database listens on."
  value       = aws_db_instance.this.port
}

output "db_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.id
}

output "db_arn" {
  description = "ARN of the RDS instance."
  value       = aws_db_instance.this.arn
}

output "db_name" {
  description = "Name of the initial database."
  value       = aws_db_instance.this.db_name
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret that stores the master user credentials."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
