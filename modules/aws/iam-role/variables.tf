###############################################################################
# AWS IAM Role Module – variables.tf
###############################################################################

variable "role_name" {
  description = "Name of the IAM role."
  type        = string
}

variable "trusted_service" {
  description = "AWS service principal that can assume this role (e.g. ec2.amazonaws.com, lambda.amazonaws.com)."
  type        = string
}

variable "managed_policy_arns" {
  description = "List of AWS managed or customer-managed policy ARNs to attach to the role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Map of tags to apply to the IAM role."
  type        = map(string)
  default     = {}
}
