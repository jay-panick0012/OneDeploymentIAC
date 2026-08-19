###############################################################################
# AWS CloudWatch Module – main.tf
# Creates: Log group, metric alarm, and a minimal monitoring dashboard
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days

  tags = merge(var.tags, { Name = var.log_group_name })
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = var.alarm_name
  comparison_operator = var.alarm_comparison_operator
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = var.alarm_metric_name
  namespace           = var.alarm_namespace
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.alarm_threshold
  alarm_description   = "Alarm when ${var.alarm_metric_name} in ${var.alarm_namespace} crosses ${var.alarm_threshold}."
  alarm_actions       = var.alarm_actions
  dimensions          = var.dimensions

  tags = merge(var.tags, { Name = var.alarm_name })
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.alarm_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            [var.alarm_namespace, var.alarm_metric_name]
          ]
          period = var.alarm_period_seconds
          stat   = "Average"
          region = data.aws_region.current.name
          title  = var.alarm_name
        }
      }
    ]
  })
}
