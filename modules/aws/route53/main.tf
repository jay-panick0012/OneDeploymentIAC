###############################################################################
# AWS Route53 Module – main.tf
# Creates: Route53 hosted zone (public or private) and DNS records
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_route53_zone" "this" {
  name = var.zone_name

  dynamic "vpc" {
    for_each = var.private_zone ? [var.vpc_id] : []
    content {
      vpc_id = vpc.value
    }
  }

  tags = merge(var.tags, { Name = var.zone_name })
}

resource "aws_route53_record" "this" {
  for_each = { for r in var.records : "${r.name}-${r.type}" => r }

  zone_id = aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
}
