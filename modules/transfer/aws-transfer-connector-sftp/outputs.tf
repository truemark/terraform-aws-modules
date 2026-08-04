################################################################################
# Transfer Connector
################################################################################

output "connector_id" {
  description = "Unique identifier of the Transfer connector (e.g. c-xxxxxxxxxxxxxxxxxxxx)."
  value       = join("", aws_transfer_connector.this[*].connector_id)
}

output "connector_arn" {
  description = "ARN of the Transfer connector."
  value       = join("", aws_transfer_connector.this[*].arn)
}

################################################################################
# IAM Access Role
################################################################################

output "access_role_arn" {
  description = "ARN of the IAM access role in use by the connector. Returns the managed role ARN or the caller-supplied access_role_arn."
  value       = local.resolved_access_role_arn
}

output "access_role_name" {
  description = "Name of the managed IAM access role. Empty string when create_access_role is false or access_role_arn is provided."
  value       = join("", aws_iam_role.access[*].name)
}

################################################################################
# Secrets Manager
################################################################################

output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding the SSH credentials. Returns the managed secret ARN or the caller-supplied secret_arn. Populate this secret with the required JSON before initiating transfers."
  value       = local.resolved_secret_arn
}

output "secret_name" {
  description = "Name of the managed Secrets Manager secret. Empty string when create_secret is false or secret_arn is provided."
  value       = join("", aws_secretsmanager_secret.this[*].name)
}
