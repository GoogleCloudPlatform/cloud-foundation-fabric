# DNS Threat Detector Module

This module implements configuration for Cloud DNS Threat Detector (DNS Armour) at the project level.

## Example

```hcl
module "threat-detector" {
  source     = "./fabric/modules/dns-threat-detector"
  project_id = "my-project"
  name       = "threat-detector-default"
  excluded_networks = [
    "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/my-vpc"
  ]
}
# tftest modules=1 resources=1
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L35) | Name of the DNS Threat Detector. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L46) | ID of the project where the resource stays. | <code>string</code> | ✓ |  |
| [context](variables.tf#L17) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [excluded_networks](variables.tf#L28) | List of network URLs to explicitly exclude from threat detector protection. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [prefix](variables.tf#L40) | Optional prefix applied to resource name. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | The identifier of the DNS Threat Detector. |  |
| [name](outputs.tf#L22) | Name of the DNS Threat Detector. |  |
<!-- END TFDOC -->
