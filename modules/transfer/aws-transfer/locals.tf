locals {
  create = var.create
  is_vpc = var.endpoint_type == "VPC"

  component_tags = var.suppress_tagging ? {} : {
    "truemark:automation:component-id"     = "terraform-aws-transfer"
    "truemark:automation:component-url"    = "https://github.com/truemark/terraform-aws-transfer"
    "truemark:automation:component-vendor" = "truemark"
  }

  name_tag = { Name = var.name }

  log_group_name    = coalesce(var.log_group_name, "/aws/transfer/${var.name}")
  logging_role_name = coalesce(var.logging_role_name, "${var.name}-transfer-logging")

  # Resolve the structured log destinations passed to the server. The managed
  # log group ARN is used automatically unless the caller supplies overrides.
  resolved_log_destinations = (
    length(var.structured_log_destinations) > 0
    ? var.structured_log_destinations
    : (local.create && var.create_log_group ? [aws_cloudwatch_log_group.this[0].arn] : [])
  )

  # Resolve the logging role ARN: prefer the caller-supplied ARN, then the
  # managed role, then null (no logging).
  resolved_logging_role_arn = (
    var.logging_role_arn != null
    ? var.logging_role_arn
    : (local.create && var.create_logging_role ? aws_iam_role.logging[0].arn : null)
  )

  # Collect all security group IDs for the VPC endpoint.
  all_security_group_ids = compact(concat(
    var.additional_security_group_ids,
    local.create && local.is_vpc && var.create_security_group ? [aws_security_group.this[0].id] : [],
  ))

  # Resolve EIP allocation IDs: managed EIPs take precedence over caller-supplied IDs.
  resolved_address_allocation_ids = var.create_eips ? aws_eip.this[*].allocation_id : var.address_allocation_ids

  # Build the set of security group ingress rules based on enabled protocols.
  # Each rule gets a stable key so for_each produces deterministic resource addresses.
  sg_ingress_port_rules = merge(
    contains(var.protocols, "SFTP") ? {
      sftp = { from_port = 22, to_port = 22 }
    } : {},
    contains(var.protocols, "FTPS") ? {
      ftps_control = { from_port = 21, to_port = 21 }
      ftps_passive = { from_port = 8192, to_port = 8200 }
    } : {},
  )

  # Whether to include the protocol_details block on the server.
  needs_protocol_details = (
    var.passive_ip != null ||
    var.tls_session_resumption_mode != null ||
    var.set_stat_option != null
  )
}
