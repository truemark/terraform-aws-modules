################################################################################
# Global
################################################################################

variable "create" {
  description = "Controls whether resources in this module are created. Set to false to skip creation without removing the module call — useful for conditional user provisioning."
  type        = bool
  default     = true
}

variable "server_id" {
  description = "ID of the Transfer server to attach this user to. Use the server_id output from the root module."
  type        = string
}

variable "tags" {
  description = "Map of tags applied to all resources. Resource-specific tag variables are merged on top of these."
  type        = map(string)
  default     = {}
}

variable "suppress_tagging" {
  description = "When true, TrueMark automation component tags are not applied to any resources."
  type        = bool
  default     = false
}

################################################################################
# Transfer User
################################################################################

variable "user_name" {
  description = "Username for the Transfer user. Must be 3–100 characters and match the pattern [a-zA-Z0-9_][a-zA-Z0-9._-]*."
  type        = string
}

variable "role_arn" {
  description = "ARN of an existing IAM role the Transfer server assumes when the user accesses files. Required when create_role is false. The role must have a trust policy allowing transfer.amazonaws.com to assume it and must grant the S3 or EFS permissions the user needs."
  type        = string
  default     = null
}

variable "home_directory_type" {
  description = "Type of home directory for the user. PATH sets a static S3 or EFS path via home_directory. LOGICAL uses home_directory_mappings to present a virtual directory tree to the user independent of the real storage layout."
  type        = string
  default     = "PATH"

  validation {
    condition     = contains(["PATH", "LOGICAL"], var.home_directory_type)
    error_message = "home_directory_type must be PATH or LOGICAL."
  }
}

variable "home_directory" {
  description = "Absolute path within the S3 bucket or EFS file system to use as the user's home directory. Only used when home_directory_type is PATH. Example: /my-bucket/users/alice."
  type        = string
  default     = null
}

variable "home_directory_mappings" {
  description = "Virtual-to-real directory mappings used when home_directory_type is LOGICAL. Each entry maps a virtual path (shown to the SFTP client) to a real S3 or EFS target path. A single mapping of entry='/' and target='/bucket/prefix/user' is the most common pattern."
  type = list(object({
    entry  = string
    target = string
  }))
  default = []
}

variable "session_policy" {
  description = "JSON IAM session policy to scope the user's effective permissions at connect time. The session policy is intersected with the user's IAM role — it can only reduce permissions, not expand them. Useful for multi-tenant deployments where all users share one role but each user's session should be restricted to their own prefix."
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

variable "user_tags" {
  description = "Additional tags applied only to the Transfer user resource. Merged with and overriding var.tags."
  type        = map(string)
  default     = {}
}

################################################################################
# IAM Role
################################################################################

variable "create_role" {
  description = "When true, an IAM role is created for this user with a trust policy allowing transfer.amazonaws.com to assume it. S3 access is configured via s3_bucket_arns, s3_prefix_arns, and s3_access_mode. Mutually exclusive with role_arn — set one or the other."
  type        = bool
  default     = false
}

variable "role_name" {
  description = "Name for the managed IAM role. Defaults to <user_name>-transfer when not specified."
  type        = string
  default     = null
}

variable "role_permissions_boundary" {
  description = "ARN of the IAM permissions boundary policy to attach to the managed role. Required in AWS Organizations environments that enforce a permissions boundary on all IAM roles."
  type        = string
  default     = null
}

variable "role_tags" {
  description = "Additional tags applied only to the managed IAM role. Merged with and overriding var.tags."
  type        = map(string)
  default     = {}
}

################################################################################
# S3 Access (used when create_role is true)
################################################################################

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs the user can list. Grants s3:ListBucket and s3:GetBucketLocation on these resources. Only used when create_role is true."
  type        = list(string)
  default     = []
}

variable "s3_prefix_arns" {
  description = "List of S3 object ARNs (e.g. arn:aws:s3:::bucket/prefix/*) the user can access. The operations permitted are determined by s3_access_mode. Only used when create_role is true."
  type        = list(string)
  default     = []
}

variable "s3_access_mode" {
  description = "Access pattern applied to s3_prefix_arns on the managed role. read_write grants GetObject, GetObjectVersion, PutObject, and PutObjectAcl. write_only grants PutObject and PutObjectAcl with an explicit Deny on GetObject and GetObjectVersion — use this for drop-box patterns where partners upload files but must not read back other uploads. read_only grants GetObject and GetObjectVersion only."
  type        = string
  default     = "read_write"

  validation {
    condition     = contains(["read_write", "write_only", "read_only"], var.s3_access_mode)
    error_message = "s3_access_mode must be read_write, write_only, or read_only."
  }
}

################################################################################
# SSH Public Keys
################################################################################

variable "ssh_public_keys" {
  description = "Map of SSH public keys to associate with this user. The map key is a short, stable identifier used as the Terraform resource address (e.g. 'laptop', 'ci_deploy'); the value is the full RSA, ECDSA, or ED25519 public key string. Multiple keys allow a user to authenticate from different clients or rotate keys without downtime."
  type        = map(string)
  default     = {}
}
