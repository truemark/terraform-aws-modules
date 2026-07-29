# TrueMark AWS Terraform Modules

A public Terraform Registry module repository for TrueMark AWS modules.

The public registry address for this repository is expected to be:

```hcl
truemark/truemark/aws
```

Database modules are organized under `modules/database/` and examples mirror that layout under `examples/database/`.

## Usage

```hcl
module "rds_mysql" {
  source  = "truemark/truemark/aws//modules/database/rds-mysql"
  version = "1.0.0"

  # inputs...
}
```

## Database Modules

| Module | Path | Example |
|---|---|---|
| [Database Prometheus Alerts](./modules/database/database-prometheus-alerts/README.md) | `database-prometheus-alerts` | [Example](./examples/database/database-prometheus-alerts) |
| [Rds Aurora Alarms](./modules/database/rds-aurora-alarms/README.md) | `rds-aurora-alarms` | [Example](./examples/database/rds-aurora-alarms) |
| [Rds Aurora Mysql](./modules/database/rds-aurora-mysql/README.md) | `rds-aurora-mysql` | [Example](./examples/database/rds-aurora-mysql) |
| [Rds Aurora Mysql Serverless V2](./modules/database/rds-aurora-mysql-serverless-v2/README.md) | `rds-aurora-mysql-serverless-v2` | [Example](./examples/database/rds-aurora-mysql-serverless-v2) |
| [Rds Aurora Postgres](./modules/database/rds-aurora-postgres/README.md) | `rds-aurora-postgres` | [Example](./examples/database/rds-aurora-postgres) |
| [Rds Aurora Postgres Serverless](./modules/database/rds-aurora-postgres-serverless/README.md) | `rds-aurora-postgres-serverless` | [Example](./examples/database/rds-aurora-postgres-serverless) |
| [Rds Aurora Postgres Serverless V2](./modules/database/rds-aurora-postgres-serverless-v2/README.md) | `rds-aurora-postgres-serverless-v2` | [Example](./examples/database/rds-aurora-postgres-serverless-v2) |
| [Rds Custom Mssql](./modules/database/rds-custom-mssql/README.md) | `rds-custom-mssql` | [Example](./examples/database/rds-custom-mssql) |
| [Rds Custom Oracle](./modules/database/rds-custom-oracle/README.md) | `rds-custom-oracle` | [Example](./examples/database/rds-custom-oracle) |
| [Rds Mssql](./modules/database/rds-mssql/README.md) | `rds-mssql` | [Example](./examples/database/rds-mssql) |
| [Rds Mssql Alarms](./modules/database/rds-mssql-alarms/README.md) | `rds-mssql-alarms` | [Example](./examples/database/rds-mssql-alarms) |
| [Rds Mysql](./modules/database/rds-mysql/README.md) | `rds-mysql` | [Example](./examples/database/rds-mysql) |
| [Rds Oracle](./modules/database/rds-oracle/README.md) | `rds-oracle` | [Example](./examples/database/rds-oracle) |
| [Rds Oracle Alarms](./modules/database/rds-oracle-alarms/README.md) | `rds-oracle-alarms` | [Example](./examples/database/rds-oracle-alarms) |
| [Rds Postgres](./modules/database/rds-postgres/README.md) | `rds-postgres` | [Example](./examples/database/rds-postgres) |
| [Rds Postgres Alarms](./modules/database/rds-postgres-alarms/README.md) | `rds-postgres-alarms` | [Example](./examples/database/rds-postgres-alarms) |
| [Rds Proxy](./modules/database/rds-proxy/README.md) | `rds-proxy` | [Example](./examples/database/rds-proxy) |
| [Rds Secret](./modules/database/rds-secret/README.md) | `rds-secret` | [Example](./examples/database/rds-secret) |
| [Redshift Cluster](./modules/database/redshift-cluster/README.md) | `redshift-cluster` |  |
| [Redshift Serverless](./modules/database/redshift-serverless/README.md) | `redshift-serverless` |  |

## Ownership

See `CODEOWNERS` or `.github/CODEOWNERS` for example path-based ownership by team.

## Related Links

- [TrueMark](https://truemark.io)
