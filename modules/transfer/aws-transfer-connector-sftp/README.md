# aws-transfer-connector-sftp

Creates an AWS Transfer Family outbound SFTP connector for sending files to a remote SFTP server. Provisions the connector resource, a Secrets Manager secret for SSH credentials, and an IAM access role.

## Usage

```hcl
module "connector" {
  source  = "truemark/truemark/aws//modules/transfer/aws-transfer-connector-sftp"
  version = ">=0"

  name = "partner-outbound"
  url  = "sftp://sftp.partner.example.com"

  trusted_host_keys = [
    "ssh-ed25519 AAAA..."
  ]

  tags = {
    "automation:id" = "partner-outbound"
  }
}

# After apply, populate the secret with the SSH credentials before initiating transfers:
# {
#   "Username":   "upload-user",
#   "PrivateKey": "-----BEGIN OPENSSH PRIVATE KEY-----\n..."
# }
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| name | Name prefix for all resources. | `string` | | yes |
| url | Remote SFTP server URL (`sftp://hostname` or `sftp://hostname:port`). | `string` | | yes |
| trusted_host_keys | SSH host key fingerprints for the remote server. | `list(string)` | | yes |
| create_access_role | Create a managed IAM access role. | `bool` | `true` | no |
| access_role_arn | ARN of an existing IAM role. Required when `create_access_role` is false. | `string` | `null` | no |
| create_secret | Create a managed Secrets Manager secret for SSH credentials. | `bool` | `true` | no |
| secret_arn | ARN of an existing Secrets Manager secret. Required when `create_secret` is false. | `string` | `null` | no |
| secret_kms_key_id | KMS key ARN for secret encryption. | `string` | `null` | no |
| security_policy_name | Cryptographic security policy name. | `string` | `null` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |
| create | Set to false to disable resource creation. | `bool` | `true` | no |

## Outputs

| Name | Description |
|---|---|
| connector_id | Unique identifier of the Transfer connector. |
| connector_arn | ARN of the Transfer connector. |
| access_role_arn | ARN of the IAM access role in use by the connector. |
| access_role_name | Name of the managed IAM access role. |
| secret_arn | ARN of the Secrets Manager secret. Populate before initiating transfers. |
| secret_name | Name of the managed Secrets Manager secret. |
