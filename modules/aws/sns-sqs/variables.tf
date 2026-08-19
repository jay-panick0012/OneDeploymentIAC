###############################################################################
# AWS SNS-SQS Module – variables.tf
###############################################################################

variable "topic_name" {
  description = "Name of the SNS topic (without the '.fifo' suffix)."
  type        = string
}

variable "queue_name" {
  description = "Name of the SQS queue (without the '.fifo' suffix)."
  type        = string
}

variable "fifo" {
  description = "Create the topic and queue as FIFO. Appends '.fifo' to all resource names when true."
  type        = bool
  default     = false
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for the main queue, in seconds."
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "Number of seconds messages are retained in the main queue and DLQ."
  type        = number
  default     = 345600
}

variable "dlq_max_receive_count" {
  description = "Number of receives before a message is moved to the dead-letter queue. Set to 0 to disable the DLQ."
  type        = number
  default     = 5

  validation {
    condition     = var.dlq_max_receive_count >= 0 && var.dlq_max_receive_count <= 1000
    error_message = "dlq_max_receive_count must be between 0 and 1000."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
