locals {
  create = var.create

  access_role_name = coalesce(var.access_role_name, "${var.name}-sftp-connector")
  secret_name      = coalesce(var.secret_name, "${var.name}-sftp-connector")

  # Resolve the access role ARN: prefer the caller-supplied ARN, then the managed role.
  resolved_access_role_arn = (
    var.access_role_arn != null
    ? var.access_role_arn
    : (local.create && var.create_access_role ? aws_iam_role.access[0].arn : null)
  )

  # Logging role: use the explicit override, then the managed access role, then null (no logging).
  resolved_logging_role_arn = (
    var.logging_role_arn != null
    ? var.logging_role_arn
    : (local.create && var.create_access_role && var.access_role_arn == null
       ? aws_iam_role.access[0].arn
       : null)
  )

  # Resolve the Secrets Manager secret ARN.
  resolved_secret_arn = (
    var.secret_arn != null
    ? var.secret_arn
    : (local.create && var.create_secret ? aws_secretsmanager_secret.this[0].arn : null)
  )

  component_tags = var.suppress_tagging ? {} : {
    "truemark:automation:component-id"     = "terraform-aws-transfer"
    "truemark:automation:component-url"    = "https://github.com/truemark/terraform-aws-transfer"
    "truemark:automation:component-vendor" = "truemark"
  }

  name_tag = { Name = var.name }
}
