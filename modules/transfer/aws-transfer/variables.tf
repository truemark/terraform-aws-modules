################################################################################
# Global
################################################################################

variable "create" {
  description = "Controls whether resources in this module are created. Set to false to prevent all resource creation without destroying existing infrastructure."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name used as the primary identifier for all resources created by this module. Applied as a name prefix or full name depending on the resource."
  type        = string
}

variable "tags" {
  description = "Map of tags applied to all resources. Resource-specific tag variables are merged on top of these."
  type        = map(string)
  default     = {}
}

variable "suppress_tagging" {
  description = "When true, TrueMark automation component tags (truemark:automation:component-id, truemark:automation:component-url, truemark:automation:component-vendor) are not applied to any resources. Set to true in environments where these tags conflict with existing tagging policies."
  type        = bool
  default     = false
}

################################################################################
# Transfer Server
################################################################################

variable "endpoint_type" {
  description = "Network endpoint type for the Transfer server. Valid values are PUBLIC and VPC. Use VPC to restrict access to a private VPC or to attach Elastic IPs for internet-accessible VPC endpoints."
  type        = string
  default     = "PUBLIC"
}

variable "protocols" {
  description = "File transfer protocols to enable on the server. Valid values are SFTP and FTPS. FTPS requires a certificate ARN provided via the certificate variable."
  type        = list(string)
  default     = ["SFTP"]
}

variable "identity_provider_type" {
  description = "Authentication mechanism for the server. SERVICE_MANAGED uses native AWS Transfer user management. AWS_LAMBDA delegates authentication to a Lambda function. AWS_DIRECTORY_SERVICE integrates with AWS Managed Microsoft AD."
  type        = string
  default     = "SERVICE_MANAGED"
}

variable "directory_id" {
  description = "Identifier of the AWS Directory Service directory to use for identity. Required when identity_provider_type is AWS_DIRECTORY_SERVICE."
  type        = string
  default     = null
}

variable "function_arn" {
  description = "ARN of the Lambda function to invoke for custom authentication. Required when identity_provider_type is AWS_LAMBDA."
  type        = string
  default     = null
}

variable "invocation_role" {
  description = "ARN of the IAM role that Transfer assumes when calling the Lambda function or connecting to AWS Directory Service. Required for AWS_LAMBDA and AWS_DIRECTORY_SERVICE identity provider types."
  type        = string
  default     = null
}

variable "sftp_authentication_methods" {
  description = "Authentication methods available to SFTP users. Valid values are PUBLIC_KEY, PASSWORD, PUBLIC_KEY_OR_PASSWORD, and PUBLIC_KEY_AND_PASSWORD. Applies to SERVICE_MANAGED and AWS_LAMBDA identity providers."
  type        = string
  default     = null
}

variable "security_policy_name" {
  description = "Cryptographic algorithm security policy for the Transfer server. Controls which TLS ciphers, curves, and protocol versions are accepted. Refer to AWS documentation for the full list of available policies."
  type        = string
  default     = "TransferSecurityPolicy-2024-01"
}

variable "pre_authentication_login_banner" {
  description = "Banner text displayed to SFTP/FTPS clients before the user authenticates. Useful for legal notices or usage policies."
  type        = string
  default     = null
}

variable "post_authentication_login_banner" {
  description = "Banner text displayed to SFTP/FTPS clients immediately after successful authentication."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "When true, all users and their associated SSH public keys are deleted from the server before the server itself is destroyed. When false, Terraform will error if users exist at destroy time."
  type        = bool
  default     = false
}

variable "domain" {
  description = "Storage domain backing the Transfer server. Valid values are S3 and EFS. This setting cannot be changed after server creation."
  type        = string
  default     = "S3"
}

variable "host_key" {
  description = "RSA, ECDSA, or ED25519 private key used as the server's host key. If omitted, AWS generates a host key automatically. Providing a custom key allows clients to verify the server identity without an SSH warning after reprovisioning."
  type        = string
  default     = null
  sensitive   = true
}

variable "server_tags" {
  description = "Additional tags applied only to the Transfer server resource. Merged with and overriding var.tags."
  type        = map(string)
  default     = {}
}

variable "s3_directory_listing_optimization" {
  description = "Controls whether the Transfer server uses optimized S3 directory listing (ListObjectsV2 with delimiter-based pagination). Valid values are ENABLED and DISABLED. Only applies when domain is S3. Enable for buckets with large object counts per prefix to reduce listing latency for SFTP clients."
  type        = string
  default     = "DISABLED"
}

################################################################################
# FTPS / Protocol Details
################################################################################

variable "certificate" {
  description = "ARN of the ACM certificate to use for the FTPS server. Required when FTPS is included in var.protocols."
  type        = string
  default     = null
}

variable "passive_ip" {
  description = "Passive IP address or FQDN that FTPS clients use for data connections. Set this to the NAT IP or Elastic IP when the server is behind a NAT device. Only relevant when FTPS is enabled."
  type        = string
  default     = null
}

variable "tls_session_resumption_mode" {
  description = "Controls how the Transfer server handles TLS session resumption for FTPS connections. Valid values are DISABLED, ENABLED, and ENFORCED. Defaults to ENFORCED for maximum security when set."
  type        = string
  default     = null
}

variable "set_stat_option" {
  description = "Controls how the server handles SETSTAT commands for SFTP clients that send these commands even when they are not required. Valid values are DEFAULT and ENABLE_NO_OP."
  type        = string
  default     = null
}

################################################################################
# VPC Endpoint
################################################################################

variable "vpc_id" {
  description = "ID of the VPC to host the Transfer server endpoint. Required when endpoint_type is VPC."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs within the VPC where the Transfer server endpoint is placed. Required when endpoint_type is VPC. One subnet per Availability Zone is recommended for high availability."
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "When true and endpoint_type is VPC, a dedicated security group is created and attached to the Transfer server endpoint. Set to false to manage security groups externally via additional_security_group_ids."
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name for the managed security group. Defaults to var.name when not set."
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description for the managed security group."
  type        = string
  default     = "Transfer Family server security group"
}

variable "security_group_ingress_cidr_ipv4" {
  description = "List of IPv4 CIDRs allowed inbound to the Transfer server. Applied to SFTP (port 22), FTPS control (port 21), and FTPS passive data (ports 8192-8200) as determined by var.protocols."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "security_group_ingress_cidr_ipv6" {
  description = "List of IPv6 CIDRs allowed inbound to the Transfer server. Applied to the same ports as security_group_ingress_cidr_ipv4 based on var.protocols. Empty by default — add entries to support dual-stack or IPv6-only clients."
  type        = list(string)
  default     = []
}

variable "security_group_egress_cidr_ipv4" {
  description = "List of IPv4 CIDRs permitted for all outbound traffic from the managed security group."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "security_group_egress_cidr_ipv6" {
  description = "List of IPv6 CIDRs permitted for all outbound traffic from the managed security group. Empty by default."
  type        = list(string)
  default     = []
}

variable "security_group_ingress_source_sg_ids" {
  description = "List of security group IDs allowed inbound to the Transfer server. Creates ingress rules referencing these security groups as the source — one rule per protocol port per security group ID. Prefer this over CIDR-based rules for intra-VPC access where resources are identified by security group."
  type        = list(string)
  default     = []
}

variable "additional_security_group_ids" {
  description = "List of existing security group IDs to attach to the VPC endpoint in addition to the managed security group."
  type        = list(string)
  default     = []
}

variable "create_eips" {
  description = "When true, Elastic IP addresses are allocated and associated with the VPC endpoint to make the Transfer server reachable from the internet. The number of EIPs created is controlled by eip_count. Mutually exclusive with address_allocation_ids."
  type        = bool
  default     = false
}

variable "eip_count" {
  description = "Number of Elastic IPs to allocate when create_eips is true. Should match the number of subnets provided in subnet_ids for correct AZ mapping."
  type        = number
  default     = 1
}

variable "address_allocation_ids" {
  description = "List of existing Elastic IP allocation IDs to associate with the VPC endpoint. Use when pre-allocated EIPs must be reused (e.g., for IP allowlisting). Mutually exclusive with create_eips."
  type        = list(string)
  default     = []
}

variable "security_group_tags" {
  description = "Additional tags applied only to the managed security group. Merged with and overriding var.tags."
  type        = map(string)
  default     = {}
}

variable "eip_tags" {
  description = "Additional tags applied only to managed Elastic IP resources. Merged with and overriding var.tags."
  type        = map(string)
  default     = {}
}

################################################################################
# CloudWatch Logging
################################################################################

variable "create_log_group" {
  description = "When true, a CloudWatch log group is created and configured as the structured log destination for the Transfer server. Set to false and provide structured_log_destinations to use an existing log group."
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group. Defaults to /aws/transfer/<name> when not specified."
  type        = string
  default     = null
}

variable "log_group_retention_in_days" {
  description = "Number of days to retain Transfer server log events in CloudWatch. Set to 0 for indefinite retention."
  type        = number
  default     = 30
}

variable "log_group_kms_key_id" {
  description = "ARN of the KMS key used to encrypt CloudWatch log data at rest. When not specified, AWS-managed encryption is used."
  type        = string
  default     = null
}

variable "structured_log_destinations" {
  description = "List of CloudWatch log group ARNs to use as structured log destinations on the Transfer server. When create_log_group is true and this list is empty, the managed log group ARN is used automatically. Provide values here to use existing log groups or send logs to multiple destinations."
  type        = list(string)
  default     = []
}

variable "log_group_skip_destroy" {
  description = "When true, the CloudWatch log group is not deleted when terraform destroy is run. Set to true in production environments to preserve audit logs of all file transfer activity. Especially important in regulated environments (HIPAA, PCI DSS, SOC 2) with log retention obligations."
  type        = bool
  default     = false
}

variable "log_group_tags" {
  description = "Additional tags applied only to the managed CloudWatch log group. Merged with and overriding var.tags."
  type        = map(string)
  default     = {}
}

################################################################################
# IAM Logging Role
################################################################################

variable "create_logging_role" {
  description = "When true, an IAM role is created with the AWSTransferLoggingAccess managed policy and assigned as the server's logging role. Set to false and provide logging_role_arn to use an existing role."
  type        = bool
  default     = true
}

variable "logging_role_arn" {
  description = "ARN of an existing IAM role to use as the Transfer server logging role. When provided, the managed logging role is not created. The supplied role must have a trust policy that allows transfer.amazonaws.com to assume it."
  type        = string
  default     = null
}

variable "logging_role_name" {
  description = "Name of the managed IAM logging role. Defaults to <name>-transfer-logging when not specified."
  type        = string
  default     = null
}

variable "logging_role_permissions_boundary" {
  description = "ARN of the IAM permissions boundary policy to attach to the managed logging role. Required in AWS Organizations environments that enforce a permissions boundary on all IAM roles via SCPs or internal policy."
  type        = string
  default     = null
}

variable "logging_role_tags" {
  description = "Additional tags applied only to the managed IAM logging role. Merged with and overriding var.tags."
  type        = map(string)
  default     = {}
}

################################################################################
# Custom Hostname
################################################################################

variable "zone_id" {
  description = "Route 53 hosted zone ID in which to create a CNAME record pointing to the Transfer server endpoint. Both zone_id and hostname must be set to create the DNS record."
  type        = string
  default     = null
}

variable "hostname" {
  description = "Fully qualified domain name for the CNAME record that resolves to the Transfer server endpoint. Both zone_id and hostname must be set to create the DNS record."
  type        = string
  default     = null
}
