################################################################################
# Global
################################################################################

variable "create" {
  description = "Controls whether resources in this module are created. Set to false to skip creation without removing the module call."
  type        = bool
  default     = true
}

variable "server_id" {
  description = "ID of the Transfer server to attach this access configuration to. The server must use identity_provider_type = AWS_DIRECTORY_SERVICE."
  type        = string
}

################################################################################
# Access Configuration
################################################################################

variable "external_id" {
  description = "Security Identifier (SID) of the Active Directory group this access configuration applies to. All directory users who are members of this group will connect using the home directory and IAM role defined here. Format: S-1-5-21-<domain>-<RID>."
  type        = string
}

variable "role_arn" {
  description = "ARN of the IAM role the Transfer server assumes when members of this AD group access files. The role must allow transfer.amazonaws.com to assume it and must grant the S3 or EFS permissions required for this group."
  type        = string
}

variable "home_directory_type" {
  description = "Type of home directory for members of this AD group. PATH sets a static S3 or EFS path via home_directory. LOGICAL uses home_directory_mappings to present a virtual directory tree independent of the real storage layout."
  type        = string
  default     = "PATH"

  validation {
    condition     = contains(["PATH", "LOGICAL"], var.home_directory_type)
    error_message = "home_directory_type must be PATH or LOGICAL."
  }
}

variable "home_directory" {
  description = "Absolute path within the S3 bucket or EFS file system to use as the home directory for members of this AD group. Only used when home_directory_type is PATH. Example: /partner-bucket/acme."
  type        = string
  default     = null
}

variable "home_directory_mappings" {
  description = "Virtual-to-real directory mappings used when home_directory_type is LOGICAL. Each entry maps a virtual path shown to the SFTP client to a real S3 or EFS target path."
  type = list(object({
    entry  = string
    target = string
  }))
  default = []
}

variable "session_policy" {
  description = "JSON IAM session policy to scope the effective permissions of members of this AD group at connect time. The session policy is intersected with the IAM role — it can only reduce permissions, not expand them."
  type        = string
  default     = null
}

variable "posix_profile" {
  description = "POSIX user and group identity for EFS-backed Transfer servers. Required when the Transfer server domain is EFS. Set secondary_gids to an empty list when no supplemental groups are needed."
  type = object({
    uid            = number
    gid            = number
    secondary_gids = list(number)
  })
  default = null
}
