# Google Apigee X Instance Module

This module allows managing a single Apigee X instance and its environment attachments.

## Examples

### Apigee X Evaluation Instance

```hcl
module "apigee-x-instance" {
  source             = "./modules/apigee-x-instance"
  name               = "my-us-instance"
  region             = "us-central1"
  ip_range           = "10.0.0.0/22"

  apigee_org_id      = "my-project"
  apigee_environments = [
    "eval1",
    "eval2"
  ]
}
# tftest modules=1 resources=3
```

### Apigee X Paid Instance

```hcl
module "apigee-x-instance" {
  source              = "./modules/apigee-x-instance"
  name                = "my-us-instance"
  region              = "us-central1"
  ip_range            = "10.0.0.0/22"
  disk_encryption_key = "my-disk-key"

  apigee_org_id       = "my-project"
  apigee_environments = [
    "dev1",
    "dev2",
    "test1",
    "test2"
  ]
}
# tftest modules=1 resources=5
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [apigee_org_id](variables.tf#L32) | Apigee Organization ID. | <code>string</code> | ✓ |  |
| [name](variables.tf#L49) | Apigee instance name. | <code>string</code> | ✓ |  |
| [region](variables.tf#L54) | Compute region. | <code>string</code> | ✓ |  |
| [apigee_envgroups](variables.tf#L17) | Apigee Environment Groups. | <code title="map&#40;object&#40;&#123;&#10;  environments &#61; list&#40;string&#41;&#10;  hostnames    &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [apigee_environments](variables.tf#L26) | Apigee Environment Names. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [disk_encryption_key](variables.tf#L43) | Customer Managed Encryption Key (CMEK) self link (e.g. `projects/foo/locations/us/keyRings/bar/cryptoKeys/baz`) used for disk and volume encryption (required for PAID Apigee Orgs only). | <code>string</code> |  | <code>null</code> |
| [ip_range](variables.tf#L37) | Customer-provided CIDR blocks of length 22 and 28 for the Apigee instance (e.g. `10.0.0.0/22,10.1.0.0/28`). | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [endpoint](outputs.tf#L17) | Internal endpoint of the Apigee instance. |  |
| [id](outputs.tf#L22) | Apigee instance ID. |  |
| [instance](outputs.tf#L27) | Apigee instance. |  |
| [port](outputs.tf#L32) | Port number of the internal endpoint of the Apigee instance. |  |
| [service_attachment](outputs.tf#L37) | Resource name of the service attachment created for this Apigee instance. |  |

<!-- END TFDOC -->
