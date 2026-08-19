###############################################################################
# AWS CloudWatch Module – variables.tf
###############################################################################

variable "log_group_name" {
  description = "Name of the CloudWatch log group."
  type        = string
}

variable "retention_in_days" {
  description = "Number of days to retain log events in the log group."
  type        = number
  default     = 30
}

variable "alarm_name" {
  description = "Name of the CloudWatch metric alarm."
  type        = string
}

variable "alarm_metric_name" {
  description = "Name of the metric to alarm on."
  type        = string
  default     = "CPUUtilization"
}

variable "alarm_namespace" {
  description = "Namespace of the metric to alarm on."
  type        = string
  default     = "AWS/EKS"
}

variable "alarm_threshold" {
  description = "Threshold value the metric is compared against."
  type        = number
  default     = 80
}

variable "alarm_comparison_operator" {
  description = "Arithmetic operation used to compare the metric to the threshold. Valid values: GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold, LessThanLowerOrGreaterThanUpperThreshold, GreaterThanUpperThreshold."
  type        = string
  default     = "GreaterThanThreshold"

  validation {
    condition = contains([
      "GreaterThanOrEqualToThreshold",
      "GreaterThanThreshold",
      "LessThanThreshold",
      "LessThanOrEqualToThreshold",
      "LessThanLowerOrGreaterThanUpperThreshold",
      "GreaterThanUpperThreshold",
    ], var.alarm_comparison_operator)
    error_message = "alarm_comparison_operator must be one of: GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold, LessThanLowerOrGreaterThanUpperThreshold, GreaterThanUpperThreshold."
  }
}

variable "alarm_evaluation_periods" {
  description = "Number of periods over which data is compared to the threshold."
  type        = number
  default     = 3
}

variable "alarm_period_seconds" {
  description = "Length of time, in seconds, over which the metric is evaluated."
  type        = number
  default     = 300
}

variable "alarm_actions" {
  description = "List of ARNs (e.g. SNS topics) to notify when the alarm transitions to ALARM state."
  type        = list(string)
  default     = []
}

variable "dimensions" {
  description = "Map of dimensions to apply to the alarm's metric."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
