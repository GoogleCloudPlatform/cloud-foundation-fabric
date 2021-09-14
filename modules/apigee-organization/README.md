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
|---|---|:---: |:---:|:---:|
| analytics_region | Analytics Region for the Apigee Organization (immutable). See https://cloud.google.com/apigee/docs/api-platform/get-started/install-cli. | <code title="">string</code> | ✓ |  |
| project_id | Project ID to host this Apigee organization (will also become the Apigee Org name). | <code title="">string</code> | ✓ |  |
| runtime_type | None | <code title="string&#10;validation &#123;&#10;condition     &#61; contains&#40;&#91;&#34;CLOUD&#34;, &#34;HYBRID&#34;&#93;, var.runtime_type&#41;&#10;error_message &#61; &#34;Allowed values for runtime_type &#92;&#34;CLOUD&#92;&#34; or &#92;&#34;HYBRID&#92;&#34;.&#34;&#10;&#125;">string</code> | ✓ |  |
| *apigee_envgroups* | Apigee Environment Groups. | <code title="map&#40;object&#40;&#123;&#10;environments &#61; list&#40;string&#41;&#10;hostnames    &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *apigee_environments* | Apigee Environment Names. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *authorized_network* | VPC network self link (requires service network peering enabled (Used in Apigee X only). | <code title="">string</code> |  | <code title="">null</code> |
| *database_encryption_key* | Cloud KMS key self link (e.g. `projects/foo/locations/us/keyRings/bar/cryptoKeys/baz`) used for encrypting the data that is stored and replicated across runtime instances (immutable, used in Apigee X only). | <code title="">string</code> |  | <code title="">null</code> |
| *description* | Description of the Apigee Organization. | <code title="">string</code> |  | <code title="">Apigee Organization created by tf module</code> |
| *display_name* | Display Name of the Apigee Organization. | <code title="">string</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| org | Apigee Organization. |  |
| org_ca_certificate | Apigee organization CA certificate. |  |
| org_id | Apigee Organization ID. |  |
| subscription_type | Apigee subscription type. |  |
<!-- END TFDOC -->
