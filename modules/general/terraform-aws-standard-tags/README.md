# Standard Tags

This terraform module produces a map of tags following the tagging strategy document
at https://doc.clickup.com/45017321/d/h/1axu79-4090/66320c3fa686fba.

The equivalent AWS CDK construct is located at 
https://github.com/truemark/cdk/blob/main/packages/truemark-cdk-lib/aws-tags/lib/standard-tags.ts

## Usage

```hcl
module "tags" {
  source  = "truemark/truemark/aws//modules/general/terraform-aws-standard-tags"
  version = "1.0.1"

  cost_center = {
    business_unit_name = "example-bu"
    project_name       = "example-project"
  }

  team = {
    name = "example-team"
  }
}

output "tags" {
  value = module.tags.tags
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_automation"></a> [automation](#input\_automation) | Automation tags | <pre>object({<br>    id  = string<br>    url = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_automation_component"></a> [automation\_component](#input\_automation_component) | Automation component tags | <pre>object({<br>    id     = string<br>    url    = optional(string)<br>    vendor = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_cost_center"></a> [cost\_center](#input\_cost_center) | Cost center tags | <pre>object({<br>    business_unit_name = string<br>    business_unit_id   = optional(string)<br>    project_name       = string<br>    project_id         = optional(string)<br>    environment        = optional(string)<br>    contact_name       = optional(string)<br>    contact_email      = optional(string)<br>    contact_phone      = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_security"></a> [security](#input\_security) | Security tags | <pre>object({<br>    data_classification = string<br>    data_sensitivity    = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_team"></a> [team](#input\_team) | Team tags | <pre>object({<br>    name          = string<br>    id            = optional(string)<br>    contact_name  = optional(string)<br>    contact_email = optional(string)<br>    contact_phone = optional(string)<br>    business_unit = optional(string)<br>    department    = optional(string)<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tags"></a> [tags](#output\_tags) | Tags |
<!-- END_TF_DOCS -->
