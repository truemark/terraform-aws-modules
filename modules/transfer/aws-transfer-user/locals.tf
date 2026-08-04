locals {
  create = var.create

  role_name = coalesce(var.role_name, "${var.user_name}-transfer")

  # Resolve the role ARN: prefer the caller-supplied ARN, then the managed role.
  resolved_role_arn = (
    var.role_arn != null
    ? var.role_arn
    : (local.create && var.create_role ? aws_iam_role.user[0].arn : null)
  )

  # Create the S3 access policy when managing the role and at least one ARN is provided.
  create_s3_policy = (
    local.create && var.create_role && var.role_arn == null &&
    (length(var.s3_bucket_arns) > 0 || length(var.s3_prefix_arns) > 0)
  )

  component_tags = var.suppress_tagging ? {} : {
    "truemark:automation:component-id"     = "terraform-aws-transfer"
    "truemark:automation:component-url"    = "https://github.com/truemark/terraform-aws-transfer"
    "truemark:automation:component-vendor" = "truemark"
  }

  name_tag = { Name = var.user_name }
}
