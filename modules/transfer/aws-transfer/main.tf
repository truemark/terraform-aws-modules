################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  count = local.create && var.create_log_group ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_group_retention_in_days
  kms_key_id        = var.log_group_kms_key_id
  skip_destroy      = var.log_group_skip_destroy

  tags = merge(local.component_tags, var.tags, local.name_tag, var.log_group_tags)
}

################################################################################
# IAM Logging Role
################################################################################

data "aws_iam_policy_document" "transfer_assume_role" {
  count = local.create && var.create_logging_role && var.logging_role_arn == null ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "logging" {
  count = local.create && var.create_logging_role && var.logging_role_arn == null ? 1 : 0

  name                 = local.logging_role_name
  assume_role_policy   = data.aws_iam_policy_document.transfer_assume_role[0].json
  permissions_boundary = var.logging_role_permissions_boundary

  tags = merge(local.component_tags, var.tags, local.name_tag, var.logging_role_tags)
}

resource "aws_iam_role_policy_attachment" "logging" {
  count = local.create && var.create_logging_role && var.logging_role_arn == null ? 1 : 0

  role       = aws_iam_role.logging[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
}

################################################################################
# Security Group (VPC endpoint only)
################################################################################

resource "aws_security_group" "this" {
  count = local.create && local.is_vpc && var.create_security_group ? 1 : 0

  name        = coalesce(var.security_group_name, var.name)
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(local.component_tags, var.tags, local.name_tag, var.security_group_tags, {
    Name = coalesce(var.security_group_name, var.name)
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.create && local.is_vpc && var.create_security_group ? {
    for pair in setproduct(
      keys(local.sg_ingress_port_rules),
      var.security_group_ingress_cidr_ipv4
    ) : "${pair[0]}-${pair[1]}" => {
      rule_key  = pair[0]
      cidr_ipv4 = pair[1]
      from_port = local.sg_ingress_port_rules[pair[0]].from_port
      to_port   = local.sg_ingress_port_rules[pair[0]].to_port
    }
  } : {}

  security_group_id = aws_security_group.this[0].id
  ip_protocol       = "tcp"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_ipv4         = each.value.cidr_ipv4

  tags = merge(local.component_tags, var.tags, local.name_tag, var.security_group_tags)
}

resource "aws_vpc_security_group_ingress_rule" "ipv6" {
  for_each = local.create && local.is_vpc && var.create_security_group ? {
    for pair in setproduct(
      keys(local.sg_ingress_port_rules),
      var.security_group_ingress_cidr_ipv6
    ) : "${pair[0]}-${pair[1]}" => {
      from_port = local.sg_ingress_port_rules[pair[0]].from_port
      to_port   = local.sg_ingress_port_rules[pair[0]].to_port
      cidr_ipv6 = pair[1]
    }
  } : {}

  security_group_id = aws_security_group.this[0].id
  ip_protocol       = "tcp"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_ipv6         = each.value.cidr_ipv6

  tags = merge(local.component_tags, var.tags, local.name_tag, var.security_group_tags)
}

resource "aws_vpc_security_group_ingress_rule" "source_sg" {
  for_each = local.create && local.is_vpc && var.create_security_group ? {
    for pair in setproduct(
      keys(local.sg_ingress_port_rules),
      var.security_group_ingress_source_sg_ids
    ) : "${pair[0]}-${pair[1]}" => {
      from_port                    = local.sg_ingress_port_rules[pair[0]].from_port
      to_port                      = local.sg_ingress_port_rules[pair[0]].to_port
      referenced_security_group_id = pair[1]
    }
  } : {}

  security_group_id            = aws_security_group.this[0].id
  ip_protocol                  = "tcp"
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  referenced_security_group_id = each.value.referenced_security_group_id

  tags = merge(local.component_tags, var.tags, local.name_tag, var.security_group_tags)
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = local.create && local.is_vpc && var.create_security_group ? {
    for cidr in var.security_group_egress_cidr_ipv4 : cidr => cidr
  } : {}

  security_group_id = aws_security_group.this[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = each.value

  tags = merge(local.component_tags, var.tags, local.name_tag, var.security_group_tags)
}

resource "aws_vpc_security_group_egress_rule" "ipv6" {
  for_each = local.create && local.is_vpc && var.create_security_group ? {
    for cidr in var.security_group_egress_cidr_ipv6 : cidr => cidr
  } : {}

  security_group_id = aws_security_group.this[0].id
  ip_protocol       = "-1"
  cidr_ipv6         = each.value

  tags = merge(local.component_tags, var.tags, local.name_tag, var.security_group_tags)
}

################################################################################
# Elastic IPs (VPC endpoint with internet access)
################################################################################

resource "aws_eip" "this" {
  count = local.create && local.is_vpc && var.create_eips ? var.eip_count : 0

  domain = "vpc"

  tags = merge(local.component_tags, var.tags, local.name_tag, var.eip_tags, {
    Name = "${var.name}-${count.index}"
  })
}

################################################################################
# Transfer Server
################################################################################

resource "aws_transfer_server" "this" {
  count = local.create ? 1 : 0

  endpoint_type            = var.endpoint_type
  protocols                = var.protocols
  identity_provider_type   = var.identity_provider_type
  security_policy_name     = var.security_policy_name
  certificate              = var.certificate
  domain                   = var.domain
  host_key                 = var.host_key
  force_destroy            = var.force_destroy
  logging_role             = local.resolved_logging_role_arn
  structured_log_destinations = local.resolved_log_destinations

  pre_authentication_login_banner  = var.pre_authentication_login_banner
  post_authentication_login_banner = var.post_authentication_login_banner

  # Identity provider details — all top-level attributes in the provider schema
  directory_id                = var.directory_id
  function                    = var.function_arn
  invocation_role             = var.invocation_role
  sftp_authentication_methods = var.sftp_authentication_methods

  dynamic "endpoint_details" {
    for_each = local.is_vpc ? [1] : []
    content {
      vpc_id                 = var.vpc_id
      subnet_ids             = var.subnet_ids
      security_group_ids     = local.all_security_group_ids
      address_allocation_ids = local.resolved_address_allocation_ids
    }
  }

  dynamic "protocol_details" {
    for_each = local.needs_protocol_details ? [1] : []
    content {
      passive_ip                   = var.passive_ip
      tls_session_resumption_mode  = var.tls_session_resumption_mode
      set_stat_option              = var.set_stat_option
    }
  }

  dynamic "s3_storage_options" {
    for_each = var.domain == "S3" ? [1] : []
    content {
      directory_listing_optimization = var.s3_directory_listing_optimization
    }
  }

  tags = merge(local.component_tags, var.tags, local.name_tag, var.server_tags)

  depends_on = [aws_iam_role_policy_attachment.logging]
}

################################################################################
# Route 53 Custom Hostname
################################################################################

resource "aws_route53_record" "this" {
  count = local.create && var.zone_id != null && var.hostname != null ? 1 : 0

  zone_id = var.zone_id
  name    = var.hostname
  type    = "CNAME"
  ttl     = 300
  records = [aws_transfer_server.this[0].endpoint]
}
