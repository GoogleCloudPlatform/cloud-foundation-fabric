# Google Apigee Organization Module

This module allows managing a single Apigee organization and its environments and environmentgroups.

## Examples

### Apigee X Evaluation Organization

```hcl
module "apigee-organization" {
  source     = "./modules/apigee-organization"
  project_id = "my-project"
  analytics_region = "us-central1"
  runtime_type = "CLOUD"
  authorized_network = "my-vpc"
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

### Apigee X Paid Organization

```hcl
module "apigee-organization" {
  source     = "./modules/apigee-organization"
  project_id = "my-project"
  analytics_region = "us-central1"
  runtime_type = "CLOUD"
  authorized_network = "my-vpc"
  database_encryption_key = "my-data-key"
  apigee_environments = [
    "dev1",
    "dev2",
    "test1",
    "test2"
  ]
  apigee_envgroups = {
    dev = {
      environments = [
        "dev1",
        "dev2"
      ]
      hostnames    = [
        "dev.api.example.com"
      ]
    }
    test = {
      environments = [
        "test1",
        "test2"
      ]
      hostnames    = [
        "test.api.example.com"
      ]
    }
  }
}
# tftest:modules=1:resources=11
```

### Apigee hybrid Organization

```hcl
module "apigee-organization" {
  source     = "./modules/apigee-organization"
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
