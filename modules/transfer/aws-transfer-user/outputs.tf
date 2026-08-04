################################################################################
# IAM Role
################################################################################

output "role_arn" {
  description = "ARN of the IAM role in use by the Transfer user. Returns the managed role ARN or the caller-supplied role_arn."
  value       = local.resolved_role_arn
}

output "role_name" {
  description = "Name of the managed IAM role. Empty string when create_role is false or role_arn is provided."
  value       = join("", aws_iam_role.user[*].name)
}

################################################################################
# Transfer User
################################################################################

output "user_arn" {
  description = "ARN of the Transfer user."
  value       = join("", aws_transfer_user.this[*].arn)
}

output "user_name" {
  description = "Username of the Transfer user."
  value       = join("", aws_transfer_user.this[*].user_name)
}

output "user_id" {
  description = "Unique identifier of the Transfer user, in the form server-id/username."
  value       = join("", aws_transfer_user.this[*].id)
}

################################################################################
# SSH Public Keys
################################################################################

output "ssh_key_ids" {
  description = "Map of SSH key resource IDs keyed by the caller-supplied map key from ssh_public_keys. Empty map when no keys are configured."
  value       = { for k, v in aws_transfer_ssh_key.this : k => v.id }
}
