################################################################################
# Directory Service Access Configuration
################################################################################

resource "aws_transfer_access" "this" {
  count = var.create ? 1 : 0

  server_id           = var.server_id
  external_id         = var.external_id
  role                = var.role_arn
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
}
