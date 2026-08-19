###############################################################################
# AWS SNS-SQS Module – outputs.tf
###############################################################################

output "topic_arn" {
  description = "ARN of the SNS topic."
  value       = aws_sns_topic.this.arn
}

output "queue_arn" {
  description = "ARN of the main SQS queue."
  value       = aws_sqs_queue.this.arn
}

output "queue_url" {
  description = "URL of the main SQS queue."
  value       = aws_sqs_queue.this.id
}

output "dlq_arn" {
  description = "ARN of the dead-letter queue. Empty string if the DLQ is disabled."
  value       = local.dlq_enabled ? aws_sqs_queue.dlq[0].arn : ""
}
