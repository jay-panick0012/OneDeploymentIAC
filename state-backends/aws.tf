###############################################################################
# State Backend – AWS S3
#
# Bootstrap steps (run once before `terraform init`):
#
#   1. Create the S3 bucket manually or with a one-off apply:
#      aws s3api create-bucket \
#        --bucket one-deploy-dash-tfstate \
#        --region us-east-1
#
#      aws s3api put-bucket-versioning \
#        --bucket one-deploy-dash-tfstate \
#        --versioning-configuration Status=Enabled
#
#      aws s3api put-bucket-encryption \
#        --bucket one-deploy-dash-tfstate \
#        --server-side-encryption-configuration \
#          '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms"}}]}'
#
#   2. Create the DynamoDB lock table:
#      aws dynamodb create-table \
#        --table-name one-deploy-dash-tflock \
#        --attribute-definitions AttributeName=LockID,AttributeType=S \
#        --key-schema AttributeName=LockID,KeyType=HASH \
#        --billing-mode PAY_PER_REQUEST \
#        --region us-east-1
#
#   3. Paste the backend block below into the environment's main.tf (or a
#      backend.tf file), then run `terraform init`.
#
# The `key` path uses the workspace name, giving each environment an isolated
# state file within the same bucket.
###############################################################################

# backend "s3" {
#   bucket         = "one-deploy-dash-tfstate"
#   key            = "environments/${terraform.workspace}/terraform.tfstate"
#   region         = "us-east-1"
#   encrypt        = true
#   kms_key_id     = "arn:aws:kms:us-east-1:123456789012:alias/one-deploy-dash-tfstate"
#   dynamodb_table = "one-deploy-dash-tflock"
#
#   # Optional: assume a role for cross-account state access
#   # role_arn     = "arn:aws:iam::123456789012:role/terraform-state-role"
# }

###############################################################################
# Alternatively, configure via TF_BACKEND_* environment variables and pass
# -backend-config flags at init time (preferred for CI):
#
#   terraform init \
#     -backend-config="bucket=one-deploy-dash-tfstate" \
#     -backend-config="key=environments/production/terraform.tfstate" \
#     -backend-config="region=us-east-1" \
#     -backend-config="dynamodb_table=one-deploy-dash-tflock" \
#     -backend-config="encrypt=true"
###############################################################################

# The resources below can be used to bootstrap state infrastructure
# in a separate "bootstrap" workspace before using the backend above.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform state."
  type        = string
  default     = "one-deploy-dash-tfstate"
}

variable "state_lock_table_name" {
  description = "Name of the DynamoDB table used for state locking."
  type        = string
  default     = "one-deploy-dash-tflock"
}

variable "state_aws_region" {
  description = "AWS region for the state backend resources."
  type        = string
  default     = "us-east-1"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = var.state_bucket_name
    ManagedBy = "terraform"
    Purpose   = "terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tflock" {
  name         = var.state_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name      = var.state_lock_table_name
    ManagedBy = "terraform"
    Purpose   = "terraform-state-lock"
  }
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket."
  value       = aws_s3_bucket.tfstate.arn
}

output "lock_table_arn" {
  description = "ARN of the DynamoDB lock table."
  value       = aws_dynamodb_table.tflock.arn
}
