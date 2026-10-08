locals {
  # This is why HCL makes it hard to have nice things
  tags = merge(
    var.automation_component == null ? {} : merge([for k, v in var.automation_component : { "automation:component-${replace(k, "_", "-")}" = v } if v != null]...),
    var.automation == null ? {} : merge([for k, v in var.automation : { "automation:${replace(k, "_", "-")}" = v } if v != null]...),
    var.cost_center == null ? {} : merge([for k, v in var.cost_center : { "cost-center:${replace(k, "_", "-")}" = v } if v != null]...),
    var.security == null ? {} : merge([for k, v in var.security : { "security:${replace(k, "_", "-")}" = v } if v != null]...),
    var.team == null ? {} : merge([for k, v in var.team : { "team:${replace(k, "_", "-")}" = v } if v != null]...)
  )
}
