###############################################################################
# AWS ECR Module – outputs.tf
###############################################################################

output "repository_url" {
  description = "Full URI of the ECR repository (used as Docker image prefix)."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.this.arn
}

output "registry_id" {
  description = "AWS account ID associated with the registry."
  value       = aws_ecr_repository.this.registry_id
}

output "repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.this.name
}
