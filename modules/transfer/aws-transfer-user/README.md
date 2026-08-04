# aws-transfer-user

Creates an AWS Transfer Family user and optionally an IAM role with scoped S3 access. Use this module once per user after provisioning a Transfer server with the `aws-transfer` module.

## Usage

```hcl
module "user" {
  source  = "truemark/truemark/aws//modules/transfer/aws-transfer-user"
  version = ">=0"

  server_id = module.sftp.server_id
  user_name = "upload-user"

  create_role    = true
  s3_access_mode = "write_only"
  s3_bucket_arns = ["arn:aws:s3:::my-bucket"]
  s3_prefix_arns = ["arn:aws:s3:::my-bucket/*"]
  home_directory = "/my-bucket"

  ssh_public_keys = {
    primary = "ssh-ed25519 AAAA..."
  }

  tags = {
    "automation:id" = "my-sftp"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| server_id | ID of the Transfer server to attach this user to. | `string` | | yes |
| user_name | Username for the Transfer user (3–100 chars, `[a-zA-Z0-9_][a-zA-Z0-9._-]*`). | `string` | | yes |
| create_role | Create a managed IAM role for this user. | `bool` | `false` | no |
| role_arn | ARN of an existing IAM role. Required when `create_role` is false. | `string` | `null` | no |
| s3_access_mode | S3 access pattern: `read_write`, `write_only`, or `read_only`. | `string` | `"read_write"` | no |
| s3_bucket_arns | S3 bucket ARNs to grant `ListBucket` on. | `list(string)` | `[]` | no |
| s3_prefix_arns | S3 object ARNs to grant access on (controlled by `s3_access_mode`). | `list(string)` | `[]` | no |
| home_directory | Home directory path (e.g. `/my-bucket/users/alice`). | `string` | `null` | no |
| home_directory_type | `PATH` or `LOGICAL`. | `string` | `"PATH"` | no |
| home_directory_mappings | Virtual-to-real directory mappings (when `home_directory_type = LOGICAL`). | `list(object)` | `[]` | no |
| ssh_public_keys | Map of SSH public keys to associate with this user. | `map(string)` | `{}` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |
| create | Set to false to disable resource creation. | `bool` | `true` | no |

## Outputs

| Name | Description |
|---|---|
| role_arn | ARN of the IAM role in use by the Transfer user. |
| role_name | Name of the managed IAM role. |
| user_arn | ARN of the Transfer user. |
| user_name | Username of the Transfer user. |
| user_id | Unique identifier of the Transfer user (`server-id/username`). |
| ssh_key_ids | Map of SSH key resource IDs keyed by the caller-supplied map key. |
