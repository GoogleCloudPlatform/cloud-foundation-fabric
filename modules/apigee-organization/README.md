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

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| analytics_region | Analytics Region for the Apigee Organization (immutable). See https://cloud.google.com/apigee/docs/api-platform/get-started/install-cli. | <code>string</code> | ✓ |  |
| project_id | Project ID to host this Apigee organization (will also become the Apigee Org name). | <code>string</code> | ✓ |  |
| runtime_type | Apigee runtime type. Must be `CLOUD` or `HYBRID`. | <code>string</code> | ✓ |  |
| apigee_envgroups | Apigee Environment Groups. | <code title="map&#40;object&#40;&#123;&#10;  environments &#61; list&#40;string&#41;&#10;  hostnames    &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| apigee_environments | Apigee Environment Names. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| authorized_network | VPC network self link (requires service network peering enabled (Used in Apigee X only). | <code>string</code> |  | <code>null</code> |
| database_encryption_key | Cloud KMS key self link (e.g. `projects/foo/locations/us/keyRings/bar/cryptoKeys/baz`) used for encrypting the data that is stored and replicated across runtime instances (immutable, used in Apigee X only). | <code>string</code> |  | <code>null</code> |
| description | Description of the Apigee Organization. | <code>string</code> |  | <code>&#34;Apigee Organization created by tf module&#34;</code> |
| display_name | Display Name of the Apigee Organization. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| envs | Apigee Environments. |  |
| org | Apigee Organization. |  |
| org_ca_certificate | Apigee organization CA certificate. |  |
| org_id | Apigee Organization ID. |  |
| subscription_type | Apigee subscription type. |  |

<!-- END TFDOC -->

