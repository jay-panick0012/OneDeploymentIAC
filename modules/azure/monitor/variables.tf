###############################################################################
# Azure Monitor Module – variables.tf
###############################################################################

variable "workspace_name" {
  description = "Name of the Log Analytics workspace."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy the monitoring resources into."
  type        = string
}

variable "location" {
  description = "Azure region for the monitoring resources."
  type        = string
  default     = "eastus"
}

variable "retention_in_days" {
  description = "Number of days to retain data in the Log Analytics workspace."
  type        = number
  default     = 30
}

variable "sku" {
  description = "SKU of the Log Analytics workspace."
  type        = string
  default     = "PerGB2018"
}

variable "action_group_name" {
  description = "Name of the Monitor action group."
  type        = string
}

variable "action_group_short_name" {
  description = "Short name of the action group, used in notifications. Max 12 characters."
  type        = string
}

variable "email_receivers" {
  description = "List of email receivers to notify via the action group."
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "alert_scopes" {
  description = "List of resource IDs the metric alert monitors. When empty, the metric alert resource is not created."
  type        = list(string)
  default     = []
}

variable "alert_name" {
  description = "Name of the metric alert."
  type        = string
  default     = "high-cpu-alert"
}

variable "alert_criteria_metric_namespace" {
  description = "Metric namespace for the alert criteria."
  type        = string
  default     = "Microsoft.Compute/virtualMachines"
}

variable "alert_criteria_metric_name" {
  description = "Metric name for the alert criteria."
  type        = string
  default     = "Percentage CPU"
}

variable "alert_criteria_aggregation" {
  description = "Aggregation type for the alert criteria (e.g. Average, Total, Maximum)."
  type        = string
  default     = "Average"
}

variable "alert_criteria_operator" {
  description = "Comparison operator for the alert criteria (e.g. GreaterThan, LessThan)."
  type        = string
  default     = "GreaterThan"
}

variable "alert_criteria_threshold" {
  description = "Threshold value for the alert criteria."
  type        = number
  default     = 80
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
