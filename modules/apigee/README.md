# Apigee Module

This module allows managing a single Apigee organization and its environments and environmentgrous.

## TODO

- [ ] N/A

## Examples

### Apigee X Evaluation Organization

```hcl
module "apigee" {
  source     = "./modules/apigee"
  project_id = "my-project"
  analytics_region = "us-central1"
  runtime_type = "CLOUD"
  peering_network = "my-vpc"
  peering_range = "10.0.0.0/16"
  apigee_environments = [
    "eval1",
    "eval2"
  ]
  apigee_envgroups = {
    eval = {
      environments = [
        "eval1",
        "eval2"
      ]
      hostnames    = [
        "eval.api.example.com"
      ]
    }
  }
}
# tftest:modules=1:resources=10
```

### Apigee hybrid Evaluation Organization

```hcl
module "apigee" {
  source     = "./modules/apigee"
  project_id = "my-project"
  analytics_region = "us-central1"
  runtime_type = "HYBRID"
  apigee_environments = [
    "eval1",
    "eval2"
  ]
  apigee_envgroups = {
    eval = {
      environments = [
        "eval1",
        "eval2"
      ]
      hostnames    = [
        "eval.api.example.com"
      ]
    }
  }
}
# tftest:modules=1:resources=6
```

<!-- BEGIN TFDOC -->
<!-- END TFDOC -->
