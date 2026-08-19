###############################################################################
# GCP Pub/Sub Module – variables.tf
###############################################################################

variable "topic_name" {
  description = "Name of the Pub/Sub topic."
  type        = string
}

variable "project" {
  description = "GCP project ID."
  type        = string
}

variable "subscription_name" {
  description = "Name of the Pub/Sub subscription."
  type        = string
}

variable "ack_deadline_seconds" {
  description = "Deadline, in seconds, for the subscriber to acknowledge receipt of a message."
  type        = number
  default     = 20
}

variable "message_retention_duration" {
  description = "How long to retain unacknowledged messages, expressed as a duration string (e.g. '604800s')."
  type        = string
  default     = "604800s"
}

variable "enable_dead_letter" {
  description = "Whether to create a dead-letter topic and attach a dead-letter policy to the subscription."
  type        = bool
  default     = false
}

variable "dead_letter_max_delivery_attempts" {
  description = "Maximum number of delivery attempts before a message is forwarded to the dead-letter topic."
  type        = number
  default     = 5
}

variable "labels" {
  description = "Map of labels to apply to the topic and subscription."
  type        = map(string)
  default     = {}
}
