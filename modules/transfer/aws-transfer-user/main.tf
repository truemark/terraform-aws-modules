################################################################################
# IAM Role
################################################################################

data "aws_iam_policy_document" "user_assume_role" {
  count = local.create && var.create_role && var.role_arn == null ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "user" {
  count = local.create && var.create_role && var.role_arn == null ? 1 : 0

  name                 = local.role_name
  assume_role_policy   = data.aws_iam_policy_document.user_assume_role[0].json
  permissions_boundary = var.role_permissions_boundary

  tags = merge(local.component_tags, var.tags, local.name_tag, var.role_tags)
}

data "aws_iam_policy_document" "user_s3_access" {
  count = local.create_s3_policy ? 1 : 0

  dynamic "statement" {
    for_each = length(var.s3_bucket_arns) > 0 ? [1] : []
    content {
      sid       = "AllowBucketListing"
      effect    = "Allow"
      actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
      resources = var.s3_bucket_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_prefix_arns) > 0 && contains(["read_write", "write_only"], var.s3_access_mode) ? [1] : []
    content {
      sid       = "AllowObjectWrite"
      effect    = "Allow"
      actions   = ["s3:PutObject", "s3:PutObjectAcl"]
      resources = var.s3_prefix_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_prefix_arns) > 0 && contains(["read_write", "read_only"], var.s3_access_mode) ? [1] : []
    content {
      sid       = "AllowObjectRead"
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:GetObjectVersion"]
      resources = var.s3_prefix_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_prefix_arns) > 0 && var.s3_access_mode == "write_only" ? [1] : []
    content {
      sid       = "DenyObjectRead"
      effect    = "Deny"
      actions   = ["s3:GetObject", "s3:GetObjectVersion"]
      resources = var.s3_prefix_arns
    }
  }
}

resource "aws_iam_role_policy" "user_s3_access" {
  count = local.create_s3_policy ? 1 : 0

  name   = "s3-access"
  role   = aws_iam_role.user[0].id
  policy = data.aws_iam_policy_document.user_s3_access[0].json
}

################################################################################
# Transfer User
################################################################################

resource "aws_transfer_user" "this" {
  count = local.create ? 1 : 0

  server_id           = var.server_id
  user_name           = var.user_name
  role                = local.resolved_role_arn
  home_directory_type = var.home_directory_type
  home_directory      = var.home_directory_type == "PATH" ? var.home_directory : null
  policy              = var.session_policy

  dynamic "home_directory_mappings" {
    for_each = var.home_directory_type == "LOGICAL" ? var.home_directory_mappings : []
    content {
      entry  = home_directory_mappings.value.entry
      target = home_directory_mappings.value.target
    }
  }

  dynamic "posix_profile" {
    for_each = var.posix_profile != null ? [var.posix_profile] : []
    content {
      uid            = posix_profile.value.uid
      gid            = posix_profile.value.gid
      secondary_gids = posix_profile.value.secondary_gids
    }
  }

  tags = merge(local.component_tags, var.tags, local.name_tag, var.user_tags)

  lifecycle {
    precondition {
      condition     = var.role_arn != null || var.create_role
      error_message = "Either role_arn must be set or create_role must be true."
    }
  }

  depends_on = [aws_iam_role_policy.user_s3_access]
}

################################################################################
# SSH Public Keys
################################################################################

resource "aws_transfer_ssh_key" "this" {
  for_each = local.create ? var.ssh_public_keys : {}

  server_id = var.server_id
  user_name = var.user_name
  body      = each.value

  depends_on = [aws_transfer_user.this]
}
