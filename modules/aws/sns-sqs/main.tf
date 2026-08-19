###############################################################################
# AWS SNS-SQS Module – main.tf
# Creates: SNS topic fanning out to an SQS queue (with dead-letter queue)
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  topic_name = var.fifo ? "${var.topic_name}.fifo" : var.topic_name
  queue_name = var.fifo ? "${var.queue_name}.fifo" : var.queue_name
  dlq_name   = var.fifo ? "${var.queue_name}-dlq.fifo" : "${var.queue_name}-dlq"

  dlq_enabled = var.dlq_max_receive_count > 0
}

###############################################################################
# SNS Topic
###############################################################################

resource "aws_sns_topic" "this" {
  name       = local.topic_name
  fifo_topic = var.fifo

  tags = merge(var.tags, { Name = local.topic_name })
}

###############################################################################
# Dead-Letter Queue
###############################################################################

resource "aws_sqs_queue" "dlq" {
  count = local.dlq_enabled ? 1 : 0

  name                      = local.dlq_name
  fifo_queue                = var.fifo
  message_retention_seconds = var.message_retention_seconds

  tags = merge(var.tags, { Name = local.dlq_name })
}

###############################################################################
# Main Queue
###############################################################################

resource "aws_sqs_queue" "this" {
  name                       = local.queue_name
  fifo_queue                 = var.fifo
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds

  redrive_policy = local.dlq_enabled ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.dlq_max_receive_count
  }) : null

  tags = merge(var.tags, { Name = local.queue_name })
}

###############################################################################
# SNS -> SQS Subscription
###############################################################################

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.this.arn
}

###############################################################################
# Queue Policy Allowing SNS to Publish
###############################################################################

data "aws_iam_policy_document" "sqs_policy" {
  statement {
    sid     = "AllowSNSPublish"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    resources = [aws_sqs_queue.this.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.this.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.id
  policy    = data.aws_iam_policy_document.sqs_policy.json
}
