###############################################################################
# AWS KMS Module – outputs.tf
###############################################################################

output "key_id" {
  description = "Globally unique identifier for the KMS key."
  value       = aws_kms_key.this.key_id
}

output "key_arn" {
  description = "ARN of the KMS key."
  value       = aws_kms_key.this.arn
}

output "alias_arn" {
  description = "ARN of the KMS key alias."
  value       = aws_kms_alias.this.arn
}

output "alias_name" {
  description = "Full alias name including the 'alias/' prefix."
  value       = aws_kms_alias.this.name
}
