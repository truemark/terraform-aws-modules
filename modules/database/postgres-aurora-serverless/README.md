# AWS RDS Aurora PostgreSQL Serverless

This terraform module creates an [Aurora Serverless v1](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless.html) PostgreSQL cluster. This module extends the functionality of the module
"terraform-aws-modules/rds-aurora/aws" providing PostgreSQL Serverless specific defaults, including automatic scaling and auto-pause capacity settings.

Note: Aurora Serverless v1 only supports PostgreSQL up to version 10.14/11.13. For newer PostgreSQL engine versions, use the `postgres-aurora-serverless-v2` module instead.

## Quick Links
 * [AWS Terraform Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
 * [Aurora Serverless v1](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless.html)

## Example Usage
```
module "db" {
  source                    = "truemark/database/aws//modules/postgres-aurora-serverless"
  version                   = "0.0.1"

  auto_pause                = true
  database_name             = "dbname"
  deletion_protection       = true
  engine_version            = "10.14"
  family                    = "aurora-postgresql10"
  max_capacity              = 16
  min_capacity              = 2
  name                      = "dbname"
  seconds_until_auto_pause  = 300
  subnets                   = ["subnet-061343678", "subnet-87654321"]
  vpc_id                    = "vpc-01234acffb5bd8"
}
```
## Parameters
The following parameters are supported:

* allowed_cidr_blocks
* apply_immediately
* auto_pause
* backup_policy
* backup_retention_period
* cluster_tags
* copy_tags_to_snapshot
* create_cluster
* create_security_group
* database_name
* db_parameter_group_name
* db_parameter_group_tags
* db_parameters
* deletion_protection
* enable_http_endpoint
* engine_version
* family
* kms_key_id
* master_password
* master_password_secret_name_prefix
* master_username
* max_capacity
* min_capacity
* name
* password_secret_tags
* preferred_backup_window
* preferred_maintenance_window
* rds_cluster_parameter_group_name
* rds_cluster_parameter_group_tags
* rds_cluster_parameters
* seconds_until_auto_pause
* security_group_tags
* share
* share_tags
* skip_final_snapshot
* snapshot_identifier
* store_master_password_as_secret
* subnets
* tags
* timeout_action
* vpc_id
