###############################################################################
# AWS KMS Module – main.tf
# Creates: KMS customer-managed key with alias and automatic rotation
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_kms_key" "this" {
  description              = "KMS key for ${var.key_alias}"
  key_usage                = var.key_usage
  customer_master_key_spec = var.key_usage == "SIGN_VERIFY" ? "RSA_2048" : "SYMMETRIC_DEFAULT"
  enable_key_rotation      = var.rotation_enabled && var.key_usage == "ENCRYPT_DECRYPT"
  deletion_window_in_days  = var.deletion_window_days
  multi_region             = false

  tags = merge(var.tags, { Name = var.key_alias })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.key_alias}"
  target_key_id = aws_kms_key.this.key_id
}
