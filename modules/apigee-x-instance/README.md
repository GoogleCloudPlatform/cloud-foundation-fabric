# Google Apigee X Instance Module

This module allows managing a single Apigee X instance and its environment attachments.

## TODO

- [ ] N/A

## Examples

### Apigee X Evaluation Instance

```hcl
module "apigee-x-instance" {
  source             = "./modules/apigee-x-instance"
  name               = "my-us-instance"
  region             = "us-central1"
  cidr_mask          = 22

  apigee_org_id      = "my-project"
  apigee_environments = [
    "eval1",
    "eval2"
  ]
}
# tftest:modules=1:resources=3
```

<!-- BEGIN TFDOC -->
<!-- END TFDOC -->
