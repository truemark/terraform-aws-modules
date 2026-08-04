################################################################################
# Global
################################################################################

variable "create" {
  description = "Controls whether resources in this module are created. Set to false to skip creation without removing the module call."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name prefix used for all resources created by this module. Applied as the full name or combined with a suffix depending on the resource."
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
# Transfer Connector
################################################################################

variable "url" {
  description = "URL of the remote SFTP server in the form sftp://hostname or sftp://hostname:port. The hostname may be a DNS name or IP address. Port defaults to 22 when omitted."
  type        = string
}

variable "trusted_host_keys" {
  description = "List of trusted SSH host key fingerprints for the remote SFTP server. The Transfer service verifies the remote server's presented host key against this list before establishing a connection. Obtain fingerprints by running ssh-keyscan against the remote host and hashing the output, or from the remote server operator."
  type        = list(string)
}

variable "security_policy_name" {
  description = "Cryptographic security policy for the outbound SFTP connection. Controls which ciphers and algorithms are accepted. When null, AWS uses its default connector security policy."
  type        = string
  default     = null
}

variable "connector_tags" {
  description = "Additional tags applied only to the Transfer connector resource. Merged with and overriding var.tags."
  type        = map(string)
  default     = {}
}

################################################################################
# IAM Access Role
################################################################################

variable "create_access_role" {
  description = "When true, an IAM role is created with permissions to read the SSH credentials secret from Secrets Manager and write connector activity logs to CloudWatch. Set to false and provide access_role_arn to use an existing role."
  type        = bool
  default     = true
}

variable "access_role_arn" {
  description = "ARN of an existing IAM role to use as the connector access role. When provided, the managed access role is not created. The role must allow transfer.amazonaws.com to assume it and must grant secretsmanager:GetSecretValue on the credentials secret."
  type        = string
  default     = null
}

variable "access_role_name" {
  description = "Name for the managed IAM access role. Defaults to <name>-sftp-connector when not specified."
  type        = string
  default     = null
}

variable "access_role_permissions_boundary" {
  description = "ARN of the IAM permissions boundary policy to attach to the managed access role. Required in AWS Organizations environments that enforce a permissions boundary on all IAM roles."
  type        = string
  default     = null
}

variable "access_role_tags" {
  description = "Additional tags applied only to the managed IAM access role. Merged with and overriding var.tags."
  type        = map(string)
  default     = {}
}

################################################################################
# Logging
################################################################################

variable "logging_role_arn" {
  description = "ARN of the IAM role the connector uses to write activity logs to CloudWatch. When null and create_access_role is true, the managed access role is used as the logging role (it already holds AWSTransferLoggingAccess). Set this explicitly to direct connector logs to a different role or to disable logging by providing an empty string."
  type        = string
  default     = null
}

################################################################################
# Secrets Manager
################################################################################

variable "create_secret" {
  description = "When true, a Secrets Manager secret is created to hold the SSH credentials used by the connector. The secret is created empty — populate it with the required JSON before initiating transfers. Set to false and provide secret_arn to use an existing secret."
  type        = bool
  default     = true
}

variable "secret_arn" {
  description = "ARN of an existing Secrets Manager secret containing the SSH credentials. Required when create_secret is false. The secret must contain a JSON object with at minimum a Username key and either a PrivateKey or Password key."
  type        = string
  default     = null
}

variable "secret_name" {
  description = "Name for the managed Secrets Manager secret. Defaults to <name>-sftp-connector when not specified."
  type        = string
  default     = null
}

variable "secret_description" {
  description = "Description for the managed Secrets Manager secret."
  type        = string
  default     = "SSH credentials for Transfer Family outbound SFTP connector"
}

variable "secret_kms_key_id" {
  description = "ARN or ID of the KMS key used to encrypt the secret at rest. When null, AWS-managed encryption is used."
  type        = string
  default     = null
}

variable "secret_tags" {
  description = "Additional tags applied only to the managed Secrets Manager secret. Merged with and overriding var.tags."
  type        = map(string)
  default     = {}
}
