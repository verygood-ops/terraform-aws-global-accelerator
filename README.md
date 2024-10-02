# AWS Global Accelerator Terraform module

This is a Terraform opinionated module that creates AWS Global Accelerator resources. The motivation for updating this module was the open issue https://github.com/terraform-aws-modules/terraform-aws-global-accelerator/issues/3.

We have added the necessary changes to create any number of endpoint groups per listener, and on top of that, we have refactored the module to satisfy the input structure we want to follow as part of the CRDR project.

## Usage

```hcl
terraform {
  source = "github.com/verygood-ops/terraform-aws-global-accelerator?ref=INFRA-9844"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

generate "backend" {
  path      = "_terragrunt_generated_backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      backend "s3" {}
    }
  EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

inputs = {
  name = "hello-world-secrets-and-values"
  endpoint_groups = {
    "us-west-2" = {
      endpoints = [
        {
          endpoint_id = "arn:aws:elasticloadbalancing:us-west-2:883127560329:loadbalancer/net/hello-world-secrets-and-values/087e6c08cdd9ebf2"
          weight      = 60
        },
        {
          endpoint_id = "arn:aws:elasticloadbalancing:us-west-2:883127560329:loadbalancer/net/hello-world-secrets-and-values-0/1f4051e54f007844"
          weight      = 40
        },
      ]
      traffic_dial_percentage        = 100
      health_check_port              = 5555
      health_check_protocol          = "HTTP"
      health_check_path              = "/health"
      health_check_interval_seconds  = 10
      threshold_count                = 3
    },
    "us-east-2" = {
      endpoints               = []
      traffic_dial_percentage = 0
    }
  }

  listener_ports = {
    80 = 8080,
  }


  infra_environment      = local.account_vars.locals.infra_environment
  data_environment       = local.account_vars.locals.data_environment
  deployment_environment = "vault"

  product = "internal"
  service = "demo"
  tenant  = "NONE"
  team    = "team-infrastructure"
}
```

## Examples

Examples codified under the [`examples`](https://github.com/terraform-aws-modules/terraform-aws-global-accelerator/tree/master/examples) are intended to give users references for how to use the module(s) as well as testing/validating changes to the source code of the module. If contributing to the project, please be sure to make any appropriate updates to the relevant examples to allow maintainers to test your changes and to keep the examples up to date for users. Thank you!

- [Complete](https://github.com/terraform-aws-modules/terraform-aws-global-accelerator/tree/master/examples/complete)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.61 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.61 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_globalaccelerator_accelerator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/globalaccelerator_accelerator) | resource |
| [aws_globalaccelerator_endpoint_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/globalaccelerator_endpoint_group) | resource |
| [aws_globalaccelerator_listener.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/globalaccelerator_listener) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create"></a> [create](#input\_create) | Controls if resources should be created (affects nearly all resources) | `bool` | `true` | no |
| <a name="input_create_listeners"></a> [create\_listeners](#input\_create\_listeners) | Controls if listeners should be created (affects only listeners) | `bool` | `true` | no |
| <a name="input_data_environment"></a> [data\_environment](#input\_data\_environment) | VGS data environment: sandbox\|live etc | `string` | n/a | yes |
| <a name="input_deployment_environment"></a> [deployment\_environment](#input\_deployment\_environment) | VGS deployment environment: vault\|genpop | `string` | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Indicates whether the accelerator is enabled. Defaults to `true`. Valid values: `true`, `false` | `bool` | `true` | no |
| <a name="input_endpoint_groups"></a> [endpoint\_groups](#input\_endpoint\_groups) | Map of endpoint groups configurations | <pre>map(object({<br>    endpoints = list(object({<br>      endpoint_id                    = string<br>      weight                         = number<br>      client_ip_preservation_enabled = optional(bool, true)<br>      health_check_port              = optional(number)<br>      health_check_protocol          = optional(string)<br>      health_check_path              = optional(string)<br>      health_check_interval_seconds  = optional(number)<br>      threshold_count                = optional(number)<br>    }))<br>    traffic_dial_percentage       = number<br>    health_check_port             = optional(number)<br>    health_check_protocol         = optional(string)<br>    health_check_path             = optional(string)<br>    health_check_interval_seconds = optional(number)<br>    threshold_count               = optional(number)<br>  }))</pre> | n/a | yes |
| <a name="input_endpoint_groups_timeouts"></a> [endpoint\_groups\_timeouts](#input\_endpoint\_groups\_timeouts) | Create, update, and delete timeout configurations for the endpoint groups | `map(string)` | `{}` | no |
| <a name="input_flow_logs_enabled"></a> [flow\_logs\_enabled](#input\_flow\_logs\_enabled) | Indicates whether flow logs are enabled. Defaults to `false` | `bool` | `false` | no |
| <a name="input_flow_logs_s3_bucket"></a> [flow\_logs\_s3\_bucket](#input\_flow\_logs\_s3\_bucket) | The name of the Amazon S3 bucket for the flow logs. Required if `flow_logs_enabled` is `true` | `string` | `null` | no |
| <a name="input_flow_logs_s3_prefix"></a> [flow\_logs\_s3\_prefix](#input\_flow\_logs\_s3\_prefix) | The prefix for the location in the Amazon S3 bucket for the flow logs. Required if `flow_logs_enabled` is `true` | `string` | `null` | no |
| <a name="input_infra_environment"></a> [infra\_environment](#input\_infra\_environment) | VGS infra environment: dev\|prod etc | `string` | n/a | yes |
| <a name="input_ip_address_type"></a> [ip\_address\_type](#input\_ip\_address\_type) | The value for the address type. Defaults to `IPV4`. Valid values: `IPV4`, `DUAL_STACK` | `string` | `"IPV4"` | no |
| <a name="input_ip_addresses"></a> [ip\_addresses](#input\_ip\_addresses) | The IP addresses to use for BYOIP accelerators. If not specified, the service assigns IP addresses. Valid values: 1 or 2 IPv4 addresses | `list(string)` | `[]` | no |
| <a name="input_listener_ports"></a> [listener\_ports](#input\_listener\_ports) | Map of listener ports (from\_port to to\_port) | `map(number)` | n/a | yes |
| <a name="input_listeners_timeouts"></a> [listeners\_timeouts](#input\_listeners\_timeouts) | Create, update, and delete timeout configurations for the listeners | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the accelerator | `string` | `""` | no |
| <a name="input_product"></a> [product](#input\_product) | n/a | `string` | n/a | yes |
| <a name="input_service"></a> [service](#input\_service) | n/a | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_team"></a> [team](#input\_team) | n/a | `string` | n/a | yes |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | The DNS name of the accelerator |
| <a name="output_dual_stack_dns_name"></a> [dual\_stack\_dns\_name](#output\_dual\_stack\_dns\_name) | The DNS name that Global Accelerator creates that points to a dual-stack accelerator's four static IP addresses: two IPv4 addresses and two IPv6 addresses |
| <a name="output_endpoint_groups"></a> [endpoint\_groups](#output\_endpoint\_groups) | Map of endpoints created and their associated attributes |
| <a name="output_hosted_zone_id"></a> [hosted\_zone\_id](#output\_hosted\_zone\_id) | The Global Accelerator Route 53 zone ID that can be used to route an Alias Resource Record Set to the Global Accelerator |
| <a name="output_id"></a> [id](#output\_id) | The Amazon Resource Name (ARN) of the accelerator |
| <a name="output_ip_sets"></a> [ip\_sets](#output\_ip\_sets) | IP address set associated with the accelerator |
| <a name="output_listeners"></a> [listeners](#output\_listeners) | Map of listeners created and their associated attributes |
<!-- END_TF_DOCS -->
