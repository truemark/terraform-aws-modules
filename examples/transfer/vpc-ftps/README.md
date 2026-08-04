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

# VPC endpoint with SFTP + FTPS, Elastic IPs, and scoped ingress rules.
#
# Creates:
#   - A VPC Transfer endpoint with one Elastic IP per subnet
#   - SFTP (port 22) and FTPS (port 21 + 8192-8200) enabled
#   - A managed security group with IPv4 CIDR, IPv6 CIDR, and source SG ingress rules
#   - A CloudWatch log group (skip_destroy = true — safe to destroy the server
#     without losing the audit trail)
#
# FTPS notes:
#   - certificate_arn must be an ACM certificate in the same region
#   - passive_ip should be the Elastic IP (or NAT IP) reachable by clients
#
# After apply, give partners the Elastic IPs from eip_public_ips. Partners
# connect to any of those IPs on port 21 (FTPS) or 22 (SFTP).

module "transfer" {
  source  = "truemark/truemark/aws//modules/transfer/aws-transfer"
  version = ">=0"

  name = var.name

  # Protocols
  protocols   = ["SFTP", "FTPS"]
  certificate = var.certificate_arn
  passive_ip  = var.passive_ip

  # VPC endpoint — one Elastic IP per subnet
  endpoint_type = "VPC"
  vpc_id        = var.vpc_id
  subnet_ids    = var.subnet_ids
  create_eips   = true
  eip_count     = length(var.subnet_ids)

  # Ingress: IPv4 partner CIDRs + optional IPv6 + optional source SGs
  security_group_ingress_cidr_ipv4     = var.ingress_cidr_ipv4
  security_group_ingress_cidr_ipv6     = var.ingress_cidr_ipv6
  security_group_ingress_source_sg_ids = var.internal_security_group_ids

  # Logging — skip_destroy preserves audit logs if the server is ever destroyed
  log_group_retention_in_days = var.log_group_retention_in_days
  log_group_skip_destroy      = true

  tags = var.tags
}

variable "name" {
  description = "Name prefix applied to all resources."
  type        = string
  default     = "partner-transfer"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "ID of the VPC in which to place the Transfer endpoint."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the VPC endpoint. One per AZ for high availability."
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the FTPS server (must be in the same region)."
  type        = string
}

variable "passive_ip" {
  description = "Public IP FTPS clients use for passive data connections."
  type        = string
}

variable "ingress_cidr_ipv4" {
  description = "IPv4 CIDRs permitted to connect to the Transfer endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ingress_cidr_ipv6" {
  description = "IPv6 CIDRs permitted to connect to the Transfer endpoint."
  type        = list(string)
  default     = []
}

variable "internal_security_group_ids" {
  description = "Security group IDs for intra-VPC clients."
  type        = list(string)
  default     = []
}

variable "log_group_retention_in_days" {
  description = "Number of days to retain Transfer logs in CloudWatch."
  type        = number
  default     = 90
}

output "server_id" {
  description = "Transfer server ID."
  value       = module.transfer.server_id
}

output "server_endpoint" {
  description = "VPC endpoint DNS hostname."
  value       = module.transfer.server_endpoint
}

output "eip_public_ips" {
  description = "Public IP addresses of the Elastic IPs. Share with partners for allowlisting."
  value       = module.transfer.eip_public_ips
}

output "eip_allocation_ids" {
  description = "Elastic IP allocation IDs."
  value       = module.transfer.eip_allocation_ids
}

output "security_group_id" {
  description = "ID of the managed security group."
  value       = module.transfer.security_group_id
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group."
  value       = module.transfer.log_group_arn
}
```
