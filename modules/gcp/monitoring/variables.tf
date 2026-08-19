###############################################################################
# GCP Monitoring Module – variables.tf
###############################################################################

variable "project" {
  description = "GCP project ID."
  type        = string
}

variable "notification_channel_display_name" {
  description = "Display name for the email notification channel."
  type        = string
}

variable "notification_email" {
  description = "Email address to receive alert notifications."
  type        = string
}

variable "alert_policy_display_name" {
  description = "Display name for the alert policy."
  type        = string
}

variable "alert_condition_filter" {
  description = "Cloud Monitoring filter expression for the alert condition, e.g. resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\"."
  type        = string
}

variable "alert_condition_display_name" {
  description = "Display name for the alert condition."
  type        = string
  default     = "condition"
}

variable "alert_threshold_value" {
  description = "Threshold value above which the alert condition is triggered."
  type        = number
  default     = 0.8
}

variable "alert_duration" {
  description = "Duration the condition must be met before the alert fires, expressed as a duration string (e.g. '300s')."
  type        = string
  default     = "300s"
}

variable "combiner" {
  description = "How to combine multiple conditions in the alert policy. Valid values: AND, OR, AND_WITH_MATCHING_RESOURCE."
  type        = string
  default     = "OR"

  validation {
    condition     = contains(["AND", "OR", "AND_WITH_MATCHING_RESOURCE"], upper(var.combiner))
    error_message = "combiner must be AND, OR, or AND_WITH_MATCHING_RESOURCE."
  }
}
