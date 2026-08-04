# TrueMark AWS Terraform Modules

A public Terraform Registry module repository for TrueMark AWS modules.

The public registry address for this repository is expected to be:

```hcl
truemark/truemark/aws
```

Transfer modules are organized under `modules/transfer/` and examples mirror that layout under `examples/transfer/`.

## Usage

```hcl
module "aws_transfer" {
  source  = "truemark/truemark/aws//modules/transfer/aws-transfer"
  version = "1.0.0"

  # inputs...
}
```

## Transfer Modules

| Module | Path | Example |
|---|---|---|
| [AWS Transfer](./modules/transfer/aws-transfer/README.md) | `transfer/aws-transfer` | [Example](./examples/transfer/public-sftp) |
| [AWS Transfer User](./modules/transfer/aws-transfer-user/README.md) | `transfer/aws-transfer-user` | [Example](./examples/transfer/public-sftp) |
| [AWS Transfer Access](./modules/transfer/aws-transfer-access/README.md) | `transfer/aws-transfer-access` |  |
| [AWS Transfer Connector SFTP](./modules/transfer/aws-transfer-connector-sftp/README.md) | `transfer/aws-transfer-connector-sftp` |  |

## Ownership

See `CODEOWNERS` or `.github/CODEOWNERS` for example path-based ownership by team.

## Related Links

- [TrueMark](https://truemark.io)
