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
  location                 = "global"
  threat_detector_provider = "INFOBLOX"
  labels = {
    app = "secure-dns"
  }
}
# tftest modules=1 resources=1
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L48) | Name of the DNS Threat Detector. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L59) | ID of the project where the resource stays. | <code>string</code> | ✓ |  |
| [context](variables.tf#L17) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [excluded_networks](variables.tf#L28) | List of network URLs to explicitly exclude from threat detector protection. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [labels](variables.tf#L35) | Set of label tags associated with the DNS Threat Detector. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [location](variables.tf#L42) | The location of the DNS Threat Detector. Currently only global is supported. | <code>string</code> |  | <code>null</code> |
| [prefix](variables.tf#L53) | Optional prefix applied to resource name. | <code>string</code> |  | <code>null</code> |
| [threat_detector_provider](variables.tf#L64) | DNS Threat Detection provider. Only supported value is INFOBLOX. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | The identifier of the DNS Threat Detector. |  |
| [name](outputs.tf#L22) | Name of the DNS Threat Detector. |  |
<!-- END TFDOC -->
