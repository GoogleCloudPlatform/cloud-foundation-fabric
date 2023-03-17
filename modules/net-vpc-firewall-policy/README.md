# Google Cloud Network Firewall Policies

This module allows creation and management of a [global](https://cloud.google.com/vpc/docs/network-firewall-policies) or [regional](https://cloud.google.com/vpc/docs/regional-firewall-policies) network firewall policy, including its associations and rules.

The module interface deviates slightly from the [`net-vpc-firewall`](../net-vpc-firewall/) module since the underlying resources and API objects are different.

It also makes fewer assumptions about implicit defaults, only using one to set `match.layer4_configs` to `[{ protocol = "all" }]` if no explicit set of protocols and ports has been specified.

A factory implementation will be added in a subsequent release.

## Example

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = "my-project"
  name       = "my-network"
}

module "firewall-policy" {
  source     = "./fabric/modules/net-vpc-firewall-policy"
  name       = "test-1"
  project_id = "my-project"
  # specify a region to create and manage a regional policy
  # region     = "europe-west8"
  target_vpcs = {
    my-vpc = module.vpc.self_link
  }
  egress_rules = {
    smtp = {
      priority = 900
      match = {
        destination_ranges = ["0.0.0.0/0"]
        layer4_configs     = [{ protocol = "tcp", ports = ["25"] }]
      }
    }
  }
  ingress_rules = {
    icmp = {
      priority = 1000
      match = {
        source_ranges  = ["0.0.0.0/0"]
        layer4_configs = [{ protocol = "icmp" }]
      }
    }
    mgmt = {
      priority = 1001
      match = {
        source_ranges = ["10.1.1.0/24"]
      }
    }
    ssh = {
      priority = 1002
      match = {
        source_ranges = ["10.0.0.0/8"]
        # source_tags    = ["tagValues/123456"]
        layer4_configs = [{ protocol = "tcp", ports = ["22"] }]
      }
    }
  }
}
# tftest modules=2 resources=7
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L98) | Policy name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L104) | Project id of the project that holds the network. | <code>string</code> | ✓ |  |
| [description](variables.tf#L17) | Policy description. | <code>string</code> |  | <code>null</code> |
| [egress_rules](variables.tf#L23) | List of egress rule definitions, action can be 'allow', 'deny', 'goto_next'. The match.layer4configs map is in protocol => optional [ports] format. | <code title="map&#40;object&#40;&#123;&#10;  priority                &#61; number&#10;  action                  &#61; optional&#40;string, &#34;deny&#34;&#41;&#10;  description             &#61; optional&#40;string&#41;&#10;  disabled                &#61; optional&#40;bool, false&#41;&#10;  enable_logging          &#61; optional&#40;bool&#41;&#10;  target_service_accounts &#61; optional&#40;list&#40;string&#41;&#41;&#10;  target_tags             &#61; optional&#40;list&#40;string&#41;&#41;&#10;  match &#61; object&#40;&#123;&#10;    destination_ranges &#61; optional&#40;list&#40;string&#41;&#41;&#10;    source_ranges      &#61; optional&#40;list&#40;string&#41;&#41;&#10;    source_tags        &#61; optional&#40;list&#40;string&#41;&#41;&#10;    layer4_configs &#61; optional&#40;list&#40;object&#40;&#123;&#10;      protocol &#61; optional&#40;string, &#34;all&#34;&#41;&#10;      ports    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;, &#91;&#123;&#125;&#93;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ingress_rules](variables.tf#L60) | List of ingress rule definitions, action can be 'allow', 'deny', 'goto_next'. | <code title="map&#40;object&#40;&#123;&#10;  priority                &#61; number&#10;  action                  &#61; optional&#40;string, &#34;allow&#34;&#41;&#10;  description             &#61; optional&#40;string&#41;&#10;  disabled                &#61; optional&#40;bool, false&#41;&#10;  enable_logging          &#61; optional&#40;bool&#41;&#10;  target_service_accounts &#61; optional&#40;list&#40;string&#41;&#41;&#10;  target_tags             &#61; optional&#40;list&#40;string&#41;&#41;&#10;  match &#61; object&#40;&#123;&#10;    destination_ranges &#61; optional&#40;list&#40;string&#41;&#41;&#10;    source_ranges      &#61; optional&#40;list&#40;string&#41;&#41;&#10;    source_tags        &#61; optional&#40;list&#40;string&#41;&#41;&#10;    layer4_configs &#61; optional&#40;list&#40;object&#40;&#123;&#10;      protocol &#61; optional&#40;string, &#34;all&#34;&#41;&#10;      ports    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;, &#91;&#123;&#125;&#93;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [region](variables.tf#L110) | Policy region. Leave null for global policy. | <code>string</code> |  | <code>null</code> |
| [target_vpcs](variables.tf#L116) | VPC ids to which this policy will be attached, in descriptive name => self link format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |

<!-- END TFDOC -->
