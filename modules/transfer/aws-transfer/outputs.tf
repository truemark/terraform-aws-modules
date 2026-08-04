################################################################################
# Transfer Server
################################################################################

output "server_id" {
  description = "Unique identifier of the Transfer server (e.g. s-xxxxxxxxxxxxxxxxxxxx)."
  value       = join("", aws_transfer_server.this[*].id)
}

output "server_arn" {
  description = "Amazon Resource Name (ARN) of the Transfer server."
  value       = join("", aws_transfer_server.this[*].arn)
}

output "server_endpoint" {
  description = "DNS hostname of the Transfer server endpoint. For PUBLIC servers this is the AWS-managed hostname. For VPC servers this is the VPC endpoint DNS name."
  value       = join("", aws_transfer_server.this[*].endpoint)
}

output "server_host_key_fingerprint" {
  description = "MD5 fingerprint of the host key for the Transfer server. Use this to verify the server identity in client known-hosts files."
  value       = join("", aws_transfer_server.this[*].host_key_fingerprint)
}

################################################################################
# CloudWatch Log Group
################################################################################

output "log_group_id" {
  description = "Identifier of the managed CloudWatch log group. Empty string when create_log_group is false."
  value       = join("", aws_cloudwatch_log_group.this[*].id)
}

output "log_group_name" {
  description = "Name of the managed CloudWatch log group. Empty string when create_log_group is false."
  value       = join("", aws_cloudwatch_log_group.this[*].name)
}

output "log_group_arn" {
  description = "ARN of the managed CloudWatch log group. Empty string when create_log_group is false."
  value       = join("", aws_cloudwatch_log_group.this[*].arn)
}

################################################################################
# IAM Logging Role
################################################################################

output "logging_role_id" {
  description = "Unique identifier of the managed IAM logging role. Empty string when create_logging_role is false or logging_role_arn is provided."
  value       = join("", aws_iam_role.logging[*].id)
}

output "logging_role_name" {
  description = "Name of the managed IAM logging role. Empty string when create_logging_role is false or logging_role_arn is provided."
  value       = join("", aws_iam_role.logging[*].name)
}

output "logging_role_arn" {
  description = "ARN of the IAM logging role in use by the Transfer server. Returns the managed role ARN or the caller-supplied logging_role_arn."
  value       = local.resolved_logging_role_arn
}

################################################################################
# Security Group
################################################################################

output "security_group_id" {
  description = "ID of the managed VPC security group. Empty string when create_security_group is false or endpoint_type is PUBLIC."
  value       = join("", aws_security_group.this[*].id)
}

output "security_group_arn" {
  description = "ARN of the managed VPC security group. Empty string when create_security_group is false or endpoint_type is PUBLIC."
  value       = join("", aws_security_group.this[*].arn)
}

output "security_group_name" {
  description = "Name of the managed VPC security group. Empty string when create_security_group is false or endpoint_type is PUBLIC."
  value       = join("", aws_security_group.this[*].name)
}

################################################################################
# Elastic IPs
################################################################################

output "eip_ids" {
  description = "List of Elastic IP resource IDs created by this module. Empty list when create_eips is false."
  value       = aws_eip.this[*].id
}

output "eip_allocation_ids" {
  description = "List of Elastic IP allocation IDs associated with the VPC endpoint. Returns managed EIP allocation IDs when create_eips is true, or the caller-supplied address_allocation_ids otherwise."
  value       = local.resolved_address_allocation_ids
}

output "eip_public_ips" {
  description = "List of public IP addresses of the managed Elastic IPs. Empty list when create_eips is false."
  value       = aws_eip.this[*].public_ip
}

################################################################################
# Route 53
################################################################################

output "route53_record_id" {
  description = "Identifier of the Route 53 CNAME record for the custom hostname. Empty string when zone_id or hostname are not provided."
  value       = join("", aws_route53_record.this[*].id)
}

output "route53_record_fqdn" {
  description = "Fully qualified domain name of the Route 53 CNAME record. Empty string when zone_id or hostname are not provided."
  value       = join("", aws_route53_record.this[*].fqdn)
}
