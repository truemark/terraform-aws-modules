# AWS Redshift Serverless

This terraform module provisions an [Amazon Redshift Serverless](https://docs.aws.amazon.com/redshift/latest/mgmt/serverless-whatis.html)
namespace and workgroup, along with a dedicated security group, IAM service role, and a Secrets Manager secret holding the generated admin
password. Like the `redshift` module, this manages the underlying resources directly rather than wrapping a community module.

## Known Limitations
* This module declares its own `provider "aws"` block scoped to `var.region`. The other submodules in this repo inherit the provider from the
  calling root module instead, so composing this module alongside others in the same root may require extra provider configuration.
* The IAM role (`RedshiftServerlessRole`) name is hardcoded rather than derived from `namespace_name`. Creating more than one deployment with
  this module in the same AWS account will fail on the IAM role name collision. (The security group and secret names are correctly namespaced.)
* There is no `tags` input variable. None of the resources created by this module (namespace, workgroup, IAM role, security group, secret) are tagged.
* The Secrets Manager secret is created with `recovery_window_in_days = 0`, so it is deleted immediately with no recovery grace period if destroyed.

## Quick Links
 * [AWS Terraform Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
 * [Amazon Redshift Serverless Documentation](https://docs.aws.amazon.com/redshift/latest/mgmt/serverless-whatis.html)

## Example Usage
```
module "db" {
  source               = "truemark/database/aws//modules/redshift-serverless"
  version              = "0.0.1"

  base_capacity        = 32
  database_name        = "analytics"
  namespace_name       = "analytics-namespace"
  region               = "us-west-2"
  subnet_ids           = ["subnet-061343678", "subnet-87654321"]
  vpc_id               = "vpc-01234acffb5bd8"
  workgroup_name       = "analytics-workgroup"
}
```
## Parameters
The following parameters are supported:

* admin_user
* base_capacity
* database_name
* enhanced_vpc_routing
* namespace_name
* publicly_accessible
* region
* subnet_ids
* vpc_id
* workgroup_name
