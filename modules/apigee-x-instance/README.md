# Google Apigee X Instance Module

This module allows managing a single Apigee X instance and its environment attachments.

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

### Apigee X Paid Instance

```hcl
module "apigee-x-instance" {
  source              = "./modules/apigee-x-instance"
  name                = "my-us-instance"
  region              = "us-central1"
  cidr_mask           = 16
  disk_encryption_key = "my-disk-key"

  apigee_org_id       = "my-project"
  apigee_environments = [
    "dev1",
    "dev2",
    "test1",
    "test2"
  ]
}
# tftest:modules=1:resources=5
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| apigee_org_id | Apigee Organization ID | <code title="">string</code> | ✓ |  |
| cidr_mask | CIDR mask for the Apigee instance | <code title="number&#10;validation &#123;&#10;condition     &#61; contains&#40;&#91;16, 20, 22&#93;, var.cidr_mask&#41;&#10;error_message &#61; &#34;Invalid CIDR mask; Allowed values for cidr_mask: &#91;16, 20, 22&#93;.&#34;&#10;&#125;">number</code> | ✓ |  |
| name | Apigee instance name. | <code title="">string</code> | ✓ |  |
| region | Compute region. | <code title="">string</code> | ✓ |  |
| *apigee_envgroups* | Apigee Environment Groups. | <code title="map&#40;object&#40;&#123;&#10;environments &#61; list&#40;string&#41;&#10;hostnames    &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *apigee_environments* | Apigee Environment Names. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *disk_encryption_key* | Customer Managed Encryption Key (CMEK) self link (e.g. `projects/foo/locations/us/keyRings/bar/cryptoKeys/baz`) used for disk and volume encryption (required for PAID Apigee Orgs only). | <code title="">string</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| endpoint | Internal endpoint of the Apigee instance. |  |
| id | Apigee instance ID. |  |
| instance | Apigee instance. |  |
| port | Port number of the internal endpoint of the Apigee instance. |  |
<!-- END TFDOC -->
