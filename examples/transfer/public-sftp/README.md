```terraform
provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {}
  required_providers {
    aws = {
      version = "~> 5.0"
    }
  }
}

# Minimal public SFTP server with SERVICE_MANAGED identity.
#
# Creates:
#   - A public SFTP server (accessible at the server endpoint over port 22)
#   - A CloudWatch log group with 30-day retention
#   - An IAM logging role
#   - One SFTP user with a write-only IAM role scoped to the supplied S3 bucket
#
# After apply, give the user the server endpoint and their private key. They
# connect with:
#   sftp -i /path/to/private-key <user_name>@<server_endpoint>

locals {
  name = "my-sftp"
  tags = {
    "automation:id" = local.name
  }
}

module "sftp" {
  source  = "truemark/truemark/aws//modules/transfer/aws-transfer"
  version = ">=0"

  name = local.name
  tags = local.tags
}

module "user" {
  source  = "truemark/truemark/aws//modules/transfer/aws-transfer-user"
  version = ">=0"

  server_id = module.sftp.server_id
  user_name = var.user_name

  # Create a scoped IAM role for this user. write_only allows uploads but
  # prevents reading back files — a common pattern for partner drop-boxes.
  create_role    = true
  s3_access_mode = "write_only"
  s3_bucket_arns = ["arn:aws:s3:::${var.bucket_name}"]
  s3_prefix_arns = ["arn:aws:s3:::${var.bucket_name}/*"]
  home_directory = "/${var.bucket_name}"

  ssh_public_keys = {
    primary = var.ssh_public_key
  }

  tags = local.tags
}

variable "bucket_name" {
  description = "Name of the S3 bucket used as the user's home directory."
  type        = string
}

variable "user_name" {
  description = "SFTP username."
  type        = string
  default     = "upload-user"
}

variable "ssh_public_key" {
  description = "SSH public key string to associate with the user."
  type        = string
}

output "server_id" {
  description = "Transfer server ID."
  value       = module.sftp.server_id
}

output "server_endpoint" {
  description = "DNS hostname clients use to connect: sftp <user>@<endpoint>"
  value       = module.sftp.server_endpoint
}

output "user_role_arn" {
  description = "ARN of the IAM role created for the SFTP user."
  value       = module.user.role_arn
}

output "log_group_name" {
  description = "CloudWatch log group receiving Transfer server activity logs."
  value       = module.sftp.log_group_name
}
```
