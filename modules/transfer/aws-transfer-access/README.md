# aws-transfer-access

Maps an Active Directory group (identified by SID) to an IAM role and home directory on an AWS Transfer Family server that uses `AWS_DIRECTORY_SERVICE` as its identity provider. Use one instance of this module per AD group.

## Usage

```hcl
module "access" {
  source  = "truemark/truemark/aws//modules/transfer/aws-transfer-access"
  version = ">=0"

  server_id   = module.sftp.server_id
  external_id = "S-1-5-21-1234567890-0987654321-123456789-1001"
  role_arn    = aws_iam_role.sftp_access.arn

  home_directory_type = "LOGICAL"
  home_directory_mappings = [
    {
      entry  = "/"
      target = "/my-bucket/partners/acme"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| server_id | ID of the Transfer server (must use `AWS_DIRECTORY_SERVICE`). | `string` | | yes |
| external_id | AD group SID this access configuration applies to. | `string` | | yes |
| role_arn | ARN of the IAM role Transfer assumes for members of this group. | `string` | | yes |
| home_directory_type | `PATH` or `LOGICAL`. | `string` | `"PATH"` | no |
| home_directory | Static home directory path (when `home_directory_type = PATH`). | `string` | `null` | no |
| home_directory_mappings | Virtual-to-real directory mappings (when `home_directory_type = LOGICAL`). | `list(object)` | `[]` | no |
| session_policy | JSON IAM session policy to scope effective permissions at connect time. | `string` | `null` | no |
| posix_profile | POSIX uid/gid for EFS-backed servers. | `object` | `null` | no |
| create | Set to false to disable resource creation. | `bool` | `true` | no |

## Outputs

| Name | Description |
|---|---|
| access_id | Unique identifier of the access configuration (`server-id/external-id`). |
| external_id | AD group SID this access configuration applies to. |
