################################################################################
# Secrets Manager — SSH Credentials
################################################################################

resource "aws_secretsmanager_secret" "this" {
  count = local.create && var.create_secret && var.secret_arn == null ? 1 : 0

  name        = local.secret_name
  description = var.secret_description
  kms_key_id  = var.secret_kms_key_id

  tags = merge(local.component_tags, var.tags, local.name_tag, var.secret_tags)
}

################################################################################
# IAM Access Role
################################################################################

data "aws_iam_policy_document" "connector_assume_role" {
  count = local.create && var.create_access_role && var.access_role_arn == null ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "access" {
  count = local.create && var.create_access_role && var.access_role_arn == null ? 1 : 0

  name                 = local.access_role_name
  assume_role_policy   = data.aws_iam_policy_document.connector_assume_role[0].json
  permissions_boundary = var.access_role_permissions_boundary

  tags = merge(local.component_tags, var.tags, local.name_tag, var.access_role_tags)
}

# Attach AWSTransferLoggingAccess so the access role can also serve as the logging role.
resource "aws_iam_role_policy_attachment" "logging" {
  count = local.create && var.create_access_role && var.access_role_arn == null ? 1 : 0

  role       = aws_iam_role.access[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
}

# Inline policy scoped to the specific secret so the connector can read credentials.
data "aws_iam_policy_document" "secret_access" {
  count = local.create && var.create_access_role && var.access_role_arn == null ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [local.resolved_secret_arn]
  }
}

resource "aws_iam_role_policy" "secret_access" {
  count = local.create && var.create_access_role && var.access_role_arn == null ? 1 : 0

  name   = "secret-access"
  role   = aws_iam_role.access[0].id
  policy = data.aws_iam_policy_document.secret_access[0].json
}

################################################################################
# Transfer Connector
################################################################################

resource "aws_transfer_connector" "this" {
  count = local.create ? 1 : 0

  url          = var.url
  access_role  = local.resolved_access_role_arn
  logging_role = local.resolved_logging_role_arn

  sftp_config {
    user_secret_id    = local.resolved_secret_arn
    trusted_host_keys = var.trusted_host_keys
  }

  security_policy_name = var.security_policy_name

  tags = merge(local.component_tags, var.tags, local.name_tag, var.connector_tags)

  depends_on = [
    aws_iam_role_policy_attachment.logging,
    aws_iam_role_policy.secret_access,
  ]
}
