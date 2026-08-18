# RDS Custom for SQL Server

This terraform module creates an [RDS Custom](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/working-with-custom-sqlserver.html) instance with SQL Server compatibility. This module extends the functionality of the module
"terraform-aws-modules/rds/aws" providing RDS Custom for SQL Server specific defaults.

Unlike the standard `mssql` module, this module:
* Does not support `manage_master_user_password` (not supported by RDS Custom) and instead can generate a random master password and store it in Secrets Manager via `store_master_password_as_secret`.
* Does not create a DB option group (`create_db_option_group` is forced to `false`).
* Requires a `custom_iam_instance_profile` for the underlying EC2 instance that hosts the database.
* Creates and manages its own dedicated security group (rather than accepting `vpc_security_group_ids`) with ingress rules for SQL Server (1433/1434), SQL Server Browser (1120), RDP (3389), SSH (22), and HTTPS/WinRM (443).

## Quick Links
 * [AWS Terraform Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
 * [Working with RDS Custom for SQL Server](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/working-with-custom-sqlserver.html)

## Example Usage
```
module "db" {
  source                      = "truemark/database/aws//modules/mssql-custom"
  version                     = "0.0.1"

  allocated_storage           = 100
  custom_iam_instance_profile = "AWSRDSCustomInstanceProfileForRdsCustomInstance"
  engine_version              = "15.00.4249.2.v1"
  instance_name               = "instance-name"
  instance_type               = "db.r6i.large"
  ingress_cidrs               = ["10.0.0.0/8"]
  kms_key_id                  = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-a123-456a-a12b-a123b4cd56ef"
  subnet_ids                  = ["subnet-061343678", "subnet-87654321"]
  vpc_id                      = "vpc-01234acffb5bd8"
}
```
## Parameters
The following parameters are supported:

* allocated_storage
* apply_immediately
* auto_minor_version_upgrade
* backup_policy
* backup_retention_period
* ca_cert_identifier
* copy_tags_to_snapshot
* create_db_parameter_group
* create_db_subnet_group
* custom_iam_instance_profile
* db_instance_create_timeout
* db_instance_delete_timeout
* db_instance_update_timeout
* db_options
* db_subnet_group_name
* deletion_protection
* egress_cidrs
* engine
* engine_version
* family
* ingress_cidrs
* instance_name
* instance_type
* kms_key_id
* major_engine_version
* master_iops
* master_username
* password
* preferred_backup_window
* preferred_maintenance_window
* random_password_length
* skip_final_snapshot
* snapshot_identifier
* storage_type
* store_master_password_as_secret
* subnet_ids
* tags
* vpc_id
