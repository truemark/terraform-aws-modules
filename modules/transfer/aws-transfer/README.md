# terraform-aws-transfer

Terraform module for provisioning an [AWS Transfer Family](https://aws.amazon.com/aws-transfer-family/) server with full lifecycle management of its supporting infrastructure. Designed for production use and covers the most common Transfer Family configurations out of the box.

---

## Features

- **SFTP and FTPS** protocol support on a single server
- **PUBLIC and VPC** endpoint types — attach Elastic IPs to VPC endpoints for internet-accessible private endpoints
- **Three identity provider modes** — `SERVICE_MANAGED`, `AWS_LAMBDA`, and `AWS_DIRECTORY_SERVICE`
- **Managed CloudWatch log group** with configurable retention and optional KMS encryption
- **Managed IAM logging role** with the `AWSTransferLoggingAccess` policy pre-attached
- **Managed VPC security group** with ingress rules scoped to the enabled protocols (SFTP port 22, FTPS control port 21, FTPS passive ports 8192–8200) — supports IPv4 CIDRs, IPv6 CIDRs, and source security group references
- **Optional Elastic IP allocation** for internet-facing VPC endpoints
- **Optional Route 53 CNAME** for a custom hostname resolving to the server endpoint
- **Bring-your-own** overrides for IAM roles, log groups, security groups, and EIP allocation IDs
- **SFTP authentication method control** (`PUBLIC_KEY`, `PASSWORD`, `PUBLIC_KEY_OR_PASSWORD`, `PUBLIC_KEY_AND_PASSWORD`)
- **Protocol details** — passive IP for FTPS behind NAT, TLS session resumption mode, SETSTAT option
- **Custom host key** support for deterministic SSH fingerprints across reprovisioning
- **Conditional creation** via `create = false` — disables all resource creation without destroying the module block
- **S3 directory listing optimization** for large-bucket performance tuning
- **IAM permissions boundary** support on the managed logging role for Organizations environments
- **Log group `skip_destroy`** to protect audit logs from accidental deletion in production
- **Automatic `Name` tag** applied to all taggable resources
- **TrueMark automation component tags** applied automatically; suppressible via `suppress_tagging`

---

## Usage

### Minimal — Public SFTP with service-managed users

```hcl
module "sftp" {
  source  = "truemark/transfer/aws"
  version = "~> 0.1"

  name = "my-sftp"

  tags = {
    Environment = "production"
    Team        = "data-engineering"
  }
}
```

This creates:
- A public SFTP server with `SERVICE_MANAGED` identity
- A CloudWatch log group at `/aws/transfer/my-sftp` with 30-day retention
- An IAM logging role with `AWSTransferLoggingAccess`

---

### Full VPC — Private endpoint with EIPs, FTPS + SFTP, Lambda identity, custom hostname

```hcl
module "transfer" {
  source  = "truemark/transfer/aws"
  version = "~> 0.1"

  name = "partner-transfer"

  # Protocols
  protocols   = ["SFTP", "FTPS"]
  certificate = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
  passive_ip  = "203.0.113.10"  # NAT/EIP public IP for FTPS passive mode

  # VPC endpoint with internet access via Elastic IPs
  endpoint_type  = "VPC"
  vpc_id         = "vpc-0abc123def456"
  subnet_ids     = ["subnet-0aa111", "subnet-0bb222", "subnet-0cc333"]
  create_eips    = true
  eip_count      = 3  # one per subnet

  # Lambda-based custom authentication
  identity_provider_type = "AWS_LAMBDA"
  function_arn           = "arn:aws:lambda:us-east-1:123456789012:function:transfer-auth"
  invocation_role        = "arn:aws:iam::123456789012:role/TransferInvocationRole"

  # Custom hostname
  zone_id  = "Z1234567890ABC"
  hostname = "sftp.example.com"

  # Logging
  log_group_retention_in_days = 90
  log_group_kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  # Security — restrict inbound to known partner CIDRs (IPv4 and IPv6)
  security_group_ingress_cidr_ipv4 = ["203.0.113.0/24", "198.51.100.0/24"]
  security_group_ingress_cidr_ipv6 = ["2001:db8::/32"]

  # Intra-VPC access from a specific application tier — no CIDR maintenance needed
  security_group_ingress_source_sg_ids = ["sg-0abc123def456"]

  # Login banners
  pre_authentication_login_banner  = "Authorized access only. All activity is monitored."
  post_authentication_login_banner = "Welcome. You are connected to the partner SFTP gateway."

  tags = {
    Environment = "production"
    Team        = "integrations"
    CostCenter  = "data-platform"
  }
}

# Access the server endpoint in downstream resources
output "transfer_endpoint" {
  value = module.transfer.server_endpoint
}
```

---

### AWS Directory Service integration

```hcl
module "transfer_ad" {
  source  = "truemark/transfer/aws"
  version = "~> 0.1"

  name = "ad-sftp"

  identity_provider_type = "AWS_DIRECTORY_SERVICE"
  directory_id           = "d-9067654321"
  invocation_role        = "arn:aws:iam::123456789012:role/TransferDirectoryRole"

  tags = {
    Environment = "production"
  }
}
```

---

### Bring-your-own IAM role and log group

```hcl
module "transfer_byo" {
  source  = "truemark/transfer/aws"
  version = "~> 0.1"

  name = "managed-sftp"

  # Skip managed IAM and log group creation
  create_logging_role = false
  logging_role_arn    = "arn:aws:iam::123456789012:role/ExistingTransferLoggingRole"

  create_log_group            = false
  structured_log_destinations = ["arn:aws:logs:us-east-1:123456789012:log-group:/shared/transfer:*"]

  tags = {}
}
```

---

## Examples

| Directory | What it demonstrates |
|---|---|
| [examples/public-sftp](examples/public-sftp/) | Minimal public SFTP server with `SERVICE_MANAGED` identity and one managed user — the getting-started case |
| [examples/vpc-ftps](examples/vpc-ftps/) | VPC endpoint with SFTP + FTPS, Elastic IPs, scoped IPv4/IPv6 ingress CIDRs, source security group rules, and FTPS certificate |
| [examples/lambda-auth](examples/lambda-auth/) | `AWS_LAMBDA` identity provider with a custom Route 53 hostname — no Transfer-managed users; the Lambda controls authentication |

---

## Submodules

### `modules/access` — Directory Service Access Configuration

Provisions a single `aws_transfer_access` resource that maps an Active Directory security group to a home directory and IAM role on a `AWS_DIRECTORY_SERVICE` Transfer server. **This submodule is required when using Directory Service authentication** — without at least one access configuration the server will reject all logins even though the identity provider is correctly configured.

Call it once per AD group via `for_each`:

```hcl
module "sftp" {
  source  = "truemark/transfer/aws"
  version = "~> 0.1"

  name                   = "enterprise-sftp"
  identity_provider_type = "AWS_DIRECTORY_SERVICE"
  directory_id           = "d-9067654321"
  invocation_role        = "arn:aws:iam::123456789012:role/TransferDirectoryRole"
}

locals {
  ad_groups = {
    sftp-finance = {
      sid        = "S-1-5-21-1234567890-1234567890-1234567890-1101"
      role_arn   = aws_iam_role.finance_sftp.arn
      home_path  = "/finance-data/uploads"
    }
    sftp-operations = {
      sid        = "S-1-5-21-1234567890-1234567890-1234567890-1102"
      role_arn   = aws_iam_role.operations_sftp.arn
      home_path  = "/ops-data/uploads"
    }
  }
}

module "sftp_access" {
  source   = "truemark/transfer/aws//modules/access"
  version  = "~> 0.1"
  for_each = local.ad_groups

  server_id      = module.sftp.server_id
  external_id    = each.value.sid
  role_arn       = each.value.role_arn
  home_directory = each.value.home_path
}
```

**LOGICAL home directory** — present a clean virtual path regardless of the real S3 layout:

```hcl
module "sftp_access" {
  source  = "truemark/transfer/aws//modules/access"
  version = "~> 0.1"

  server_id           = module.sftp.server_id
  external_id         = "S-1-5-21-1234567890-1234567890-1234567890-1101"
  role_arn            = aws_iam_role.finance_sftp.arn
  home_directory_type = "LOGICAL"

  home_directory_mappings = [
    {
      entry  = "/"
      target = "/finance-bucket/uploads/finance"
    }
  ]
}
```

#### `modules/access` Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| server_id | ID of the `AWS_DIRECTORY_SERVICE` Transfer server. | `string` | — | yes |
| external_id | AD group SID this configuration applies to (e.g. `S-1-5-21-...`). | `string` | — | yes |
| role_arn | IAM role ARN assumed when group members access files. | `string` | — | yes |
| create | Gates resource creation. | `bool` | `true` | no |
| home_directory_type | `PATH` or `LOGICAL`. | `string` | `"PATH"` | no |
| home_directory | Absolute S3/EFS path for the home directory. Used with `PATH` type only. | `string` | `null` | no |
| home_directory_mappings | Virtual-to-real path mappings. Used with `LOGICAL` type only. | `list(object({entry=string,target=string}))` | `[]` | no |
| session_policy | JSON session policy to scope group members' effective permissions. | `string` | `null` | no |
| posix_profile | POSIX uid/gid for EFS-backed servers. | `object({uid=number,gid=number,secondary_gids=list(number)})` | `null` | no |

#### `modules/access` Outputs

| Name | Description |
|------|-------------|
| access_id | Unique identifier of the access configuration (`server-id/external-id`). |
| external_id | AD group SID this access configuration applies to. |

---

### `modules/connector-sftp` — Outbound SFTP Connector

Provisions an outbound `aws_transfer_connector` that pushes files to a remote SFTP server, together with the IAM access role and Secrets Manager secret it requires.

```hcl
module "connector" {
  source  = "truemark/transfer/aws//modules/connector-sftp"
  version = "~> 0.1"

  name = "acme-outbound"

  # Remote server
  url               = "sftp://sftp.partner-acme.com"
  trusted_host_keys = ["ssh-rsa AAAAB3NzaC1yc2E..."]

  tags = {
    Environment = "production"
    Partner     = "acme"
  }
}

# After apply, populate the secret with the SSH credentials:
#
#   aws secretsmanager put-secret-value \
#     --secret-id <module.connector.secret_arn> \
#     --secret-string '{"Username":"sftp-user","PrivateKey":"-----BEGIN OPENSSH PRIVATE KEY-----\n..."}'
#
# Then trigger a transfer:
#
#   aws transfer start-file-transfer \
#     --connector-id <module.connector.connector_id> \
#     --send-file-paths /my-bucket/reports/daily-report.csv
```

**Bring-your-own role and secret** — skip managed resource creation when they already exist:

```hcl
module "connector" {
  source  = "truemark/transfer/aws//modules/connector-sftp"
  version = "~> 0.1"

  name = "bank-outbound"

  url               = "sftp://sftp.bank.example.com:2222"
  trusted_host_keys = ["ecdsa-sha2-nistp256 AAAA..."]

  create_access_role = false
  access_role_arn    = "arn:aws:iam::123456789012:role/ExistingConnectorRole"

  create_secret = false
  secret_arn    = "arn:aws:secretsmanager:us-east-1:123456789012:secret:bank-sftp-key"

  logging_role_arn = "arn:aws:iam::123456789012:role/ExistingConnectorRole"
}
```

**Secret JSON format** — the Secrets Manager secret must contain one of the following JSON structures before the connector can authenticate:

```json
// Key-based authentication (recommended)
{
  "Username": "sftp-user",
  "PrivateKey": "-----BEGIN OPENSSH PRIVATE KEY-----\n...\n-----END OPENSSH PRIVATE KEY-----"
}

// Password-based authentication
{
  "Username": "sftp-user",
  "Password": "secret-password"
}
```

#### `modules/connector-sftp` Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for all resources. | `string` | — | yes |
| url | Remote SFTP server URL (`sftp://host` or `sftp://host:port`). | `string` | — | yes |
| trusted_host_keys | SSH host key fingerprints for the remote server. | `list(string)` | — | yes |
| create | Gates resource creation. | `bool` | `true` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |
| suppress_tagging | Suppress TrueMark component tags. | `bool` | `false` | no |
| security_policy_name | Cryptographic security policy for the outbound connection. | `string` | `null` | no |
| connector_tags | Additional tags for the connector resource only. | `map(string)` | `{}` | no |
| create_access_role | Create a managed IAM access role. | `bool` | `true` | no |
| access_role_arn | Existing IAM access role ARN. Skips managed role when provided. | `string` | `null` | no |
| access_role_name | Name of the managed IAM access role. Defaults to `<name>-sftp-connector`. | `string` | `null` | no |
| access_role_permissions_boundary | IAM permissions boundary ARN for the managed access role. | `string` | `null` | no |
| access_role_tags | Additional tags for the managed access role only. | `map(string)` | `{}` | no |
| logging_role_arn | IAM role ARN for connector CloudWatch logging. Defaults to the access role when null. | `string` | `null` | no |
| create_secret | Create a managed Secrets Manager secret for SSH credentials. | `bool` | `true` | no |
| secret_arn | Existing Secrets Manager secret ARN. Skips managed secret when provided. | `string` | `null` | no |
| secret_name | Name of the managed secret. Defaults to `<name>-sftp-connector`. | `string` | `null` | no |
| secret_description | Description for the managed secret. | `string` | `"SSH credentials for Transfer Family outbound SFTP connector"` | no |
| secret_kms_key_id | KMS key ARN for secret encryption. | `string` | `null` | no |
| secret_tags | Additional tags for the managed secret only. | `map(string)` | `{}` | no |

#### `modules/connector-sftp` Outputs

| Name | Description |
|------|-------------|
| connector_id | Unique identifier of the Transfer connector. |
| connector_arn | ARN of the Transfer connector. |
| access_role_arn | ARN of the IAM access role in use (managed or supplied). |
| access_role_name | Name of the managed IAM access role. Empty when BYO role is used. |
| secret_arn | ARN of the Secrets Manager secret (managed or supplied). Populate this before initiating transfers. |
| secret_name | Name of the managed Secrets Manager secret. Empty when BYO secret is used. |

---

### `modules/user` — Transfer User, IAM Role, and SSH Keys

Provisions a single `aws_transfer_user` and any number of associated SSH public keys. Optionally creates the IAM role and scoped S3 access policy for the user. Designed to be called once per user via `for_each`.

**Managed role with write-only drop-box access** (matches the CDK pattern — partners upload files but cannot read back):

```hcl
locals {
  customers = {
    acme = { bucket = "123456789012-data", public_key = "ssh-rsa AAAAB3..." }
    beta = { bucket = "987654321098-data", public_key = "ssh-ed25519 AAAAC3..." }
  }
}

module "sftp_users" {
  source   = "truemark/transfer/aws//modules/user"
  version  = "~> 0.1"
  for_each = local.customers

  server_id     = module.sftp.server_id
  user_name     = each.key
  create_role   = true
  s3_access_mode = "write_only"

  s3_bucket_arns = ["arn:aws:s3:::${each.value.bucket}"]
  s3_prefix_arns = ["arn:aws:s3:::${each.value.bucket}/*"]

  home_directory = "/${each.value.bucket}"

  ssh_public_keys = { primary = each.value.public_key }

  tags = { Environment = "production" }
}
```

This creates per-user IAM roles with `s3:PutObject` allowed and `s3:GetObject` explicitly denied. Each role is named `<user_name>-transfer` by default.

**Bring-your-own role** — provide a pre-created role ARN instead:

```hcl
module "sftp_users" {
  source   = "truemark/transfer/aws//modules/user"
  version  = "~> 0.1"
  for_each = local.sftp_users

  server_id      = module.sftp.server_id
  user_name      = each.key
  role_arn       = each.value.role_arn
  home_directory = each.value.home_directory

  ssh_public_keys = each.value.public_keys
}
```

The managed role's trust policy allows `transfer.amazonaws.com` to assume it. For defense-in-depth, scope the trust with an `aws:SourceArn` condition when using a BYO role — the condition must use the **user ARN pattern**, not the server ARN:

```hcl
data "aws_iam_policy_document" "user_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:transfer:${var.region}:${var.account_id}:user/${module.sftp.server_id}/*"]
    }
  }
}
```

**LOGICAL home directory** — maps a clean virtual path to a real S3 location:

```hcl
module "partner_user" {
  source  = "truemark/transfer/aws//modules/user"
  version = "~> 0.1"

  server_id           = module.sftp.server_id
  user_name           = "partner-acme"
  create_role         = true
  s3_access_mode      = "write_only"
  s3_bucket_arns      = ["arn:aws:s3:::acme-inbound"]
  s3_prefix_arns      = ["arn:aws:s3:::acme-inbound/uploads/acme/*"]
  home_directory_type = "LOGICAL"

  home_directory_mappings = [
    {
      entry  = "/"
      target = "/acme-inbound/uploads/acme"
    }
  ]

  ssh_public_keys = { primary = "ssh-rsa AAAAB3NzaC1yc2E..." }
}
```

**Session policy scoping** — when multiple users share one role, restrict each session to its own prefix:

```hcl
module "user" {
  source  = "truemark/transfer/aws//modules/user"
  version = "~> 0.1"

  server_id = module.sftp.server_id
  user_name = "alice"
  role_arn  = aws_iam_role.shared_sftp.arn

  session_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = "arn:aws:s3:::my-bucket/alice/*"
    }]
  })
}
```

#### `modules/user` Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| server_id | ID of the Transfer server to attach this user to. | `string` | — | yes |
| user_name | Transfer username. | `string` | — | yes |
| create | Gates resource creation. | `bool` | `true` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |
| suppress_tagging | Suppress TrueMark component tags. | `bool` | `false` | no |
| role_arn | ARN of an existing IAM role. Required when `create_role` is false. | `string` | `null` | no |
| create_role | Create a managed IAM role for this user. Mutually exclusive with `role_arn`. | `bool` | `false` | no |
| role_name | Name of the managed IAM role. Defaults to `<user_name>-transfer`. | `string` | `null` | no |
| role_permissions_boundary | IAM permissions boundary ARN for the managed role. | `string` | `null` | no |
| role_tags | Additional tags for the managed IAM role only. | `map(string)` | `{}` | no |
| s3_bucket_arns | S3 bucket ARNs granted `s3:ListBucket`. Used with `create_role = true`. | `list(string)` | `[]` | no |
| s3_prefix_arns | S3 object ARNs for read/write access. Used with `create_role = true`. | `list(string)` | `[]` | no |
| s3_access_mode | `read_write`, `write_only` (drop-box), or `read_only`. Used with `create_role = true`. | `string` | `"read_write"` | no |
| home_directory_type | `PATH` or `LOGICAL`. | `string` | `"PATH"` | no |
| home_directory | Absolute S3/EFS path for the home directory. Used with `PATH` type only. | `string` | `null` | no |
| home_directory_mappings | Virtual-to-real path mappings. Used with `LOGICAL` type only. | `list(object({entry=string,target=string}))` | `[]` | no |
| session_policy | JSON session policy to scope the user's effective permissions. | `string` | `null` | no |
| posix_profile | POSIX uid/gid for EFS-backed servers. | `object({uid=number,gid=number,secondary_gids=list(number)})` | `null` | no |
| ssh_public_keys | Map of SSH public keys keyed by a short stable identifier. | `map(string)` | `{}` | no |
| user_tags | Additional tags for the Transfer user resource only. | `map(string)` | `{}` | no |

#### `modules/user` Outputs

| Name | Description |
|------|-------------|
| role_arn | ARN of the IAM role in use (managed or supplied). |
| role_name | Name of the managed IAM role. Empty when BYO role is used. |
| user_arn | ARN of the Transfer user. |
| user_name | Username of the Transfer user. |
| user_id | Unique identifier of the Transfer user (`server-id/username`). |
| ssh_key_ids | Map of SSH key resource IDs keyed by the caller-supplied map key. |

---

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

---

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

---

## Resources

| Name | Type |
|------|------|
| aws_transfer_server.this | resource |
| aws_cloudwatch_log_group.this | resource |
| aws_iam_role.logging | resource |
| aws_iam_role_policy_attachment.logging | resource |
| aws_security_group.this | resource |
| aws_vpc_security_group_ingress_rule.this | resource |
| aws_vpc_security_group_ingress_rule.ipv6 | resource |
| aws_vpc_security_group_ingress_rule.source_sg | resource |
| aws_vpc_security_group_egress_rule.this | resource |
| aws_vpc_security_group_egress_rule.ipv6 | resource |
| aws_eip.this | resource |
| aws_route53_record.this | resource |
| aws_iam_policy_document.transfer_assume_role | data source |

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name used as the primary identifier for all resources. | `string` | — | yes |
| create | Gates all resource creation. Set to false to disable without destroying. | `bool` | `true` | no |
| tags | Map of tags applied to all resources. | `map(string)` | `{}` | no |
| suppress_tagging | When true, TrueMark automation component tags are not applied to any resources. | `bool` | `false` | no |
| endpoint_type | Network endpoint type. Valid values: `PUBLIC`, `VPC`. | `string` | `"PUBLIC"` | no |
| protocols | List of enabled protocols. Valid values: `SFTP`, `FTPS`. | `list(string)` | `["SFTP"]` | no |
| identity_provider_type | Authentication mechanism. Valid values: `SERVICE_MANAGED`, `AWS_LAMBDA`, `AWS_DIRECTORY_SERVICE`. | `string` | `"SERVICE_MANAGED"` | no |
| directory_id | AWS Directory Service directory ID. Required for `AWS_DIRECTORY_SERVICE`. | `string` | `null` | no |
| function_arn | Lambda function ARN for authentication. Required for `AWS_LAMBDA`. | `string` | `null` | no |
| invocation_role | IAM role ARN Transfer assumes when calling Lambda or Directory Service. | `string` | `null` | no |
| sftp_authentication_methods | SFTP auth methods. Valid values: `PUBLIC_KEY`, `PASSWORD`, `PUBLIC_KEY_OR_PASSWORD`, `PUBLIC_KEY_AND_PASSWORD`. | `string` | `null` | no |
| security_policy_name | Cryptographic security policy for TLS negotiation. | `string` | `"TransferSecurityPolicy-2024-01"` | no |
| pre_authentication_login_banner | Banner shown to clients before authentication. | `string` | `null` | no |
| post_authentication_login_banner | Banner shown to clients after authentication. | `string` | `null` | no |
| force_destroy | Delete all users before destroying the server. | `bool` | `false` | no |
| domain | Storage domain backing the server. Valid values: `S3`, `EFS`. | `string` | `"S3"` | no |
| host_key | Custom RSA/ECDSA/ED25519 private host key. Sensitive. | `string` | `null` | no |
| s3_directory_listing_optimization | S3 directory listing mode. Valid values: `ENABLED`, `DISABLED`. Only applies when `domain = "S3"`. | `string` | `"DISABLED"` | no |
| server_tags | Additional tags for the Transfer server resource only. | `map(string)` | `{}` | no |
| certificate | ACM certificate ARN. Required when `FTPS` is in `protocols`. | `string` | `null` | no |
| passive_ip | Passive IP/FQDN for FTPS behind NAT. | `string` | `null` | no |
| tls_session_resumption_mode | TLS session resumption for FTPS. Valid values: `DISABLED`, `ENABLED`, `ENFORCED`. | `string` | `null` | no |
| set_stat_option | SETSTAT command handling. Valid values: `DEFAULT`, `ENABLE_NO_OP`. | `string` | `null` | no |
| vpc_id | VPC ID for VPC endpoint. Required when `endpoint_type = "VPC"`. | `string` | `null` | no |
| subnet_ids | Subnet IDs for the VPC endpoint. Required when `endpoint_type = "VPC"`. | `list(string)` | `[]` | no |
| create_security_group | Create a managed security group for the VPC endpoint. | `bool` | `true` | no |
| security_group_name | Name of the managed security group. Defaults to `name`. | `string` | `null` | no |
| security_group_description | Description of the managed security group. | `string` | `"Transfer Family server security group"` | no |
| security_group_ingress_cidr_ipv4 | IPv4 CIDRs allowed inbound to the Transfer server. | `list(string)` | `["0.0.0.0/0"]` | no |
| security_group_ingress_cidr_ipv6 | IPv6 CIDRs allowed inbound to the Transfer server. Applied to the same ports as IPv4 rules. | `list(string)` | `[]` | no |
| security_group_egress_cidr_ipv4 | IPv4 CIDRs permitted for all outbound traffic. | `list(string)` | `["0.0.0.0/0"]` | no |
| security_group_egress_cidr_ipv6 | IPv6 CIDRs permitted for all outbound traffic. | `list(string)` | `[]` | no |
| security_group_ingress_source_sg_ids | Security group IDs allowed inbound. Creates one ingress rule per protocol port per source security group. | `list(string)` | `[]` | no |
| additional_security_group_ids | Additional security group IDs to attach to the VPC endpoint. | `list(string)` | `[]` | no |
| create_eips | Allocate Elastic IPs for the VPC endpoint. Mutually exclusive with `address_allocation_ids`. | `bool` | `false` | no |
| eip_count | Number of Elastic IPs to allocate. Should match `length(subnet_ids)`. | `number` | `1` | no |
| address_allocation_ids | Existing EIP allocation IDs. Mutually exclusive with `create_eips`. | `list(string)` | `[]` | no |
| security_group_tags | Additional tags for the managed security group only. | `map(string)` | `{}` | no |
| eip_tags | Additional tags for managed Elastic IP resources only. | `map(string)` | `{}` | no |
| create_log_group | Create a managed CloudWatch log group. | `bool` | `true` | no |
| log_group_name | CloudWatch log group name. Defaults to `/aws/transfer/<name>`. | `string` | `null` | no |
| log_group_retention_in_days | Log retention in days. Set to `0` for indefinite retention. | `number` | `30` | no |
| log_group_kms_key_id | KMS key ARN for log group encryption at rest. | `string` | `null` | no |
| log_group_skip_destroy | When true, the log group is not deleted on `terraform destroy`. Set to `true` in production. | `bool` | `false` | no |
| structured_log_destinations | CloudWatch log group ARNs to override the managed log group destination. | `list(string)` | `[]` | no |
| log_group_tags | Additional tags for the managed log group only. | `map(string)` | `{}` | no |
| create_logging_role | Create a managed IAM logging role. | `bool` | `true` | no |
| logging_role_arn | Existing IAM logging role ARN. Skips managed role creation when provided. | `string` | `null` | no |
| logging_role_name | Name of the managed IAM logging role. Defaults to `<name>-transfer-logging`. | `string` | `null` | no |
| logging_role_permissions_boundary | ARN of the IAM permissions boundary to attach to the managed logging role. | `string` | `null` | no |
| logging_role_tags | Additional tags for the managed IAM logging role only. | `map(string)` | `{}` | no |
| zone_id | Route 53 hosted zone ID for the custom hostname CNAME. | `string` | `null` | no |
| hostname | FQDN for the Route 53 CNAME record pointing to the server endpoint. | `string` | `null` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| server_id | Unique identifier of the Transfer server. |
| server_arn | ARN of the Transfer server. |
| server_endpoint | DNS hostname of the Transfer server endpoint. |
| server_host_key_fingerprint | MD5 fingerprint of the server host key. |
| log_group_id | Identifier of the managed CloudWatch log group. |
| log_group_name | Name of the managed CloudWatch log group. |
| log_group_arn | ARN of the managed CloudWatch log group. |
| logging_role_id | Identifier of the managed IAM logging role. |
| logging_role_name | Name of the managed IAM logging role. |
| logging_role_arn | ARN of the IAM logging role in use (managed or supplied). |
| security_group_id | ID of the managed VPC security group. |
| security_group_arn | ARN of the managed VPC security group. |
| security_group_name | Name of the managed VPC security group. |
| eip_ids | List of managed Elastic IP resource IDs. |
| eip_allocation_ids | List of EIP allocation IDs associated with the VPC endpoint. |
| eip_public_ips | List of public IP addresses of the managed Elastic IPs. |
| route53_record_id | Identifier of the Route 53 CNAME record. |
| route53_record_fqdn | FQDN of the Route 53 CNAME record. |

---

## Notes

### Identity Provider

| Type | Required Variables | Description |
|------|--------------------|-------------|
| `SERVICE_MANAGED` | — | AWS manages users natively via the Transfer console or API. Use `modules/user` to provision users. |
| `AWS_LAMBDA` | `function_arn`, `invocation_role` | Transfer calls a Lambda function to authenticate each connection attempt. The Lambda receives the username, password, and server ID and must return session policies and a home directory mapping. |
| `AWS_DIRECTORY_SERVICE` | `directory_id`, `invocation_role` | Transfer authenticates users against an AWS Managed Microsoft AD directory. **You must also create at least one access configuration via `modules/access`** — without it the server rejects all logins even when the identity provider is correctly wired up. |

The `invocation_role` must have a trust policy allowing `transfer.amazonaws.com` to assume it.

---

### VPC Endpoint

When `endpoint_type = "VPC"`, Transfer creates an interface VPC endpoint inside the specified subnets. The server is only reachable through that VPC unless Elastic IPs are attached.

**Security group ports by protocol:**

| Protocol | Port(s) | Purpose |
|----------|---------|---------|
| SFTP | 22 | Control + data |
| FTPS | 21 | Control channel |
| FTPS | 8192–8200 | Passive data channel |

The managed security group automatically opens only the ports required by `var.protocols`.

**Ingress rule types:**

The module supports three ingress rule types that can be combined:

- `security_group_ingress_cidr_ipv4` — IPv4 CIDR-based rules (default: `0.0.0.0/0`)
- `security_group_ingress_cidr_ipv6` — IPv6 CIDR-based rules for dual-stack or IPv6-only clients (default: none)
- `security_group_ingress_source_sg_ids` — source security group references for intra-VPC access (default: none)

Each type creates one rule per applicable protocol port, so a 3-protocol server with 2 CIDRs and 1 source security group produces `(3 ports × 2 CIDRs) + (3 ports × 1 SG) = 9` ingress rules.

Prefer source security group rules over CIDR rules for intra-VPC access — they track resource identity rather than IP addresses, which can drift.

**Elastic IPs:**

To make a VPC endpoint internet-accessible, set `create_eips = true` and `eip_count` equal to the number of subnets. Alternatively, supply pre-allocated EIP allocation IDs via `address_allocation_ids` — useful when partner systems allowlist specific IPs.

Combining `create_eips = true` with `address_allocation_ids` is not supported; set only one.

---

### FTPS

FTPS requires:

1. An ACM certificate ARN supplied via `certificate`. The certificate must be in the same AWS region as the Transfer server.
2. `"FTPS"` included in `var.protocols`.

For servers behind a NAT gateway or a non-AWS load balancer, set `passive_ip` to the public-facing IP or hostname so FTPS clients can establish passive data connections correctly.

For VPC endpoints, ensure the security group allows ports 21 and 8192–8200 from the expected client CIDRs. The managed security group handles this automatically.

---

### Security Policy

The `security_policy_name` variable controls which ciphers, key exchange algorithms, and protocol versions the server accepts. The default (`TransferSecurityPolicy-2024-01`) offers broad client compatibility. Choose a more restrictive policy when FIPS compliance or post-quantum key exchange is required.

| Policy name | FIPS 140-2 | Post-quantum KEX | Notes |
|---|---|---|---|
| `TransferSecurityPolicy-2024-01` | No | No | Default. Broadest client compatibility. |
| `TransferSecurityPolicy-2022-03` | No | No | Older baseline; prefer 2024-01 for new deployments. |
| `TransferSecurityPolicy-FIPS-2024-05` | Yes | No | Use in FedRAMP, DoD, or HIPAA environments requiring FIPS-validated cryptography. |
| `TransferSecurityPolicy-FIPS-2020-06` | Yes | No | Older FIPS policy; prefer FIPS-2024-05 for new deployments. |
| `TransferSecurityPolicy-PQ-SSH-FIPS-Experimental-2023-04` | Yes | Yes | Adds `mlkem768x25519-sha256` hybrid key exchange. Requires OpenSSH 9.0+ or another client with ML-KEM support. Experimental — AWS may update or remove it. |

**Post-quantum background:** OpenSSH 8.x and later clients emit a warning when they connect to a server that does not offer a post-quantum key exchange algorithm:

```
connection is not using a post-quantum key exchange algorithm — this session
may be vulnerable to store-now-decrypt-later attacks
```

This warning is advisory. If your threat model includes adversaries recording encrypted sessions today to decrypt them once quantum computers become viable (a concern for government, defense, and long-lived sensitive data), enable the experimental PQ policy:

```hcl
module "sftp" {
  # ...
  security_policy_name = "TransferSecurityPolicy-PQ-SSH-FIPS-Experimental-2023-04"
}
```

For the current full list of available policies, see the [AWS Transfer Family documentation](https://docs.aws.amazon.com/transfer/latest/userguide/security-policies.html).

---

### S3 Directory Listing Optimization

By default, AWS Transfer uses `ListObjects` for directory listings, which scans all object keys under a prefix before returning results. For S3 buckets where a single upload prefix accumulates thousands of objects before downstream processing, this causes SFTP clients to time out or stall on `ls`.

Set `s3_directory_listing_optimization = "ENABLED"` to switch to `ListObjectsV2` with delimiter-based pagination, which returns only the immediate children of a prefix rather than a full recursive scan:

```hcl
module "sftp" {
  # ...
  s3_directory_listing_optimization = "ENABLED"  # reduces ls latency for large prefixes
}
```

This setting has no effect on buckets with modest object counts and only applies when `domain = "S3"` (the default). It is silently ignored when `domain = "EFS"`.

---

### CloudWatch Log Group — Production Safety

Set `log_group_skip_destroy = true` in production to prevent Terraform from deleting the log group when the server is destroyed. This preserves the audit trail of all file transfer activity for post-incident forensics and regulatory retention requirements.

```hcl
module "sftp" {
  # ...
  log_group_skip_destroy = true  # preserve transfer audit logs
}
```

---

### Tagging

The root module and both submodules (`modules/user`, `modules/connector-sftp`) automatically apply a `Name` tag and three TrueMark automation component tags to all taggable resources:

| Tag | Value |
|-----|-------|
| `truemark:automation:component-id` | `terraform-aws-transfer` |
| `truemark:automation:component-url` | `https://github.com/truemark/terraform-aws-transfer` |
| `truemark:automation:component-vendor` | `truemark` |

Set `suppress_tagging = true` on any module to skip the component tags for that module's resources. The variable is available at the same level in all three modules and acts independently — suppressing tags in `modules/user` does not affect the root module or `modules/connector-sftp`. The `Name` tag is always applied regardless of this setting.

Tag precedence (highest wins): inline resource-specific tags → `var.<resource>_tags` → `local.name_tag` → `var.tags` → component tags.

---

## License

BSD 3-Clause. See [LICENSE.txt](LICENSE.txt).
