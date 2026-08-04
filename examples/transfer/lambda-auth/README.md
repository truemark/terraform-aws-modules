```terraform
provider "aws" {}

terraform {
  backend "s3" {}
  required_providers {
    aws = {
      version = "~> 5.0"
    }
  }
}

# Public SFTP server with Lambda-based custom authentication and a Route 53
# custom hostname.
#
# Creates:
#   - A public SFTP server that delegates authentication to a Lambda function
#   - A CloudWatch log group with configurable retention
#   - An IAM logging role
#   - A Route 53 CNAME pointing var.hostname at the Transfer server endpoint
#
# Lambda authentication contract:
#   Transfer invokes the function with this event payload:
#     {
#       "username":  "alice",
#       "password":  "...",    // empty string for public-key auth
#       "protocol":  "SFTP",
#       "serverId":  "s-...",
#       "sourceIp":  "203.0.113.10"
#     }
#
#   The function must return a JSON object. A successful response looks like:
#     {
#       "Role":              "arn:aws:iam::123456789012:role/SftpUserRole",
#       "HomeDirectory":     "/my-bucket/alice",
#       "HomeDirectoryType": "PATH",
#       "Policy":            ""   // optional session policy JSON
#     }
#
#   Return an empty object {} or omit Role to signal authentication failure.
#
# Invocation role trust policy:
#   The invocation role must allow transfer.amazonaws.com to assume it.
#   See the Identity Provider section of the aws-transfer module README.
#
# Adding users:
#   With Lambda authentication, user identities are managed inside the Lambda
#   function (e.g. against Secrets Manager, a database, or an IdP). There is
#   no need to create aws_transfer_user resources.

module "sftp" {
  source  = "truemark/truemark/aws//modules/transfer/aws-transfer"
  version = ">=0"

  name = var.name

  # Lambda-based authentication
  identity_provider_type = "AWS_LAMBDA"
  function_arn           = var.function_arn
  invocation_role        = var.invocation_role_arn

  # Custom hostname via Route 53
  zone_id  = var.zone_id
  hostname = var.hostname

  # Logging
  log_group_retention_in_days = var.log_group_retention_in_days
  log_group_skip_destroy      = true

  tags = var.tags
}

variable "name" {
  description = "Name prefix applied to all resources."
  type        = string
  default     = "sftp-gateway"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "function_arn" {
  description = "ARN of the Lambda function that authenticates SFTP connections."
  type        = string
}

variable "invocation_role_arn" {
  description = "ARN of the IAM role Transfer assumes when invoking the Lambda function."
  type        = string
}

variable "zone_id" {
  description = "Route 53 hosted zone ID for the custom hostname CNAME."
  type        = string
}

variable "hostname" {
  description = "Fully qualified domain name for the server (e.g. sftp.example.com)."
  type        = string
}

variable "log_group_retention_in_days" {
  description = "Number of days to retain Transfer logs in CloudWatch."
  type        = number
  default     = 90
}

output "server_id" {
  description = "Transfer server ID."
  value       = module.sftp.server_id
}

output "server_endpoint" {
  description = "AWS-managed DNS hostname of the server endpoint."
  value       = module.sftp.server_endpoint
}

output "custom_hostname" {
  description = "Route 53 CNAME FQDN. Clients connect to this hostname."
  value       = module.sftp.route53_record_fqdn
}

output "log_group_name" {
  description = "CloudWatch log group receiving Transfer server activity logs."
  value       = module.sftp.log_group_name
}
```
