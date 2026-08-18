# AWS Redshift

This terraform module provisions a native [Amazon Redshift](https://docs.aws.amazon.com/redshift/latest/mgmt/welcome.html) cluster, along with a
dedicated security group, IAM service role, and a Secrets Manager secret holding the generated master password. Unlike the other database submodules
in this repo, this module manages the `aws_redshift_cluster` resource directly rather than wrapping a community module.

## Known Limitations
* This module declares its own `provider "aws"` block scoped to `var.region`. The other submodules in this repo inherit the provider from the
  calling root module instead, so composing this module alongside others in the same root may require extra provider configuration.
* The security group (`redshift-sg`) and IAM role (`RedshiftServiceRole`) names are hardcoded rather than derived from `cluster_identifier`.
  Creating more than one cluster with this module in the same AWS account will fail on the IAM role name collision.
* Resource tags are hardcoded (`Environment = "dev"`, `Project = "redshift-cluster"`). There is currently no `tags` input variable.
* `admin_user`, `allow_version_upgrade`, `cluster_type`, `engine_version`, and `publicly_accessible` are declared as input variables but are not
  currently wired into the `aws_redshift_cluster` resource. `cluster_type` is derived from `number_of_nodes` instead, and `publicly_accessible`
  is hardcoded to `false`.

## Quick Links
 * [AWS Terraform Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
 * [Amazon Redshift Documentation](https://docs.aws.amazon.com/redshift/latest/mgmt/welcome.html)

## Example Usage
```
module "db" {
  source              = "truemark/database/aws//modules/redshift"
  version             = "0.0.1"

  cluster_identifier  = "analytics-cluster"
  database_name       = "analytics"
  master_username     = "admin"
  node_type           = "ra3.large"
  number_of_nodes     = 2
  region              = "us-west-2"
  skip_final_snapshot = false
  subnet_ids          = ["subnet-061343678", "subnet-87654321"]
  vpc_id              = "vpc-01234acffb5bd8"
}
```
## Parameters
The following parameters are supported:

* admin_user
* allow_version_upgrade
* cluster_identifier
* cluster_type
* database_name
* engine_version
* master_username
* node_type
* number_of_nodes
* port
* publicly_accessible
* region
* skip_final_snapshot
* subnet_group_name
* subnet_ids
* vpc_id
