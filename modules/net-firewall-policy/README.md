# Firewall Policies

This module allows creation and management of two different firewall policy types:

- a [hierarchical policy](https://cloud.google.com/firewall/docs/firewall-policies) in a folder or organization, or
- a [global](https://cloud.google.com/vpc/docs/network-firewall-policies) or [regional](https://cloud.google.com/vpc/docs/regional-firewall-policies) network policy

The module also manages policy rules via code or a factory, and optional policy attachments. The interface deviates slightly from the [`net-vpc-firewall`](../net-vpc-firewall/) module since the underlying resources and API objects are different.

The module also makes fewer assumptions about implicit defaults, only using one to set `match.layer4_configs` to `[{ protocol = "all" }]` if no explicit set of protocols and ports has been specified.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Hierarchical Policy](#hierarchical-policy)
  - [Global Network policy](#global-network-policy)
  - [Regional Network policy](#regional-network-policy)
  - [Factory](#factory)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Examples

### Hierarchical Policy

```hcl
module "firewall-policy" {
  source    = "./fabric/modules/net-firewall-policy"
  name      = "test-1"
  parent_id = "folders/1234567890"
  attachments = {
    test = "folders/4567890123"
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
# tftest modules=1 resources=6 inventory=hierarchical.yaml
```

### Global Network policy

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = "my-project"
  name       = "my-network"
}

module "firewall-policy" {
  source    = "./fabric/modules/net-firewall-policy"
  name      = "test-1"
  parent_id = "my-project"
  region    = "global"
  attachments = {
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
# tftest modules=2 resources=9 inventory=global-net.yaml
```

### Regional Network policy

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = "my-project"
  name       = "my-network"
}

module "firewall-policy" {
  source    = "./fabric/modules/net-firewall-policy"
  name      = "test-1"
  parent_id = "my-project"
  region    = "europe-west8"
  attachments = {
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
  }
}
# tftest modules=2 resources=7 inventory=regional-net.yaml
```

### Factory

Similarly to other modules, a rules factory (see [Resource Factories](../../blueprints/factories/)) is also included here to allow route management via descriptive configuration files.

Factory configuration is via three optional attributes in the `rules_factory_config` variable:

- `cidr_file_path` specifying the path to a mapping of logical names to CIDR ranges, used for source and destination ranges in rules when available
- `egress_rules_file_path` specifying the path to the egress rules file
- `ingress_rules_file_path` specifying the path to the ingress rules file

Factory rules are merged with rules declared in code, with the latter taking precedence where both use the same key.

This is an example of a simple factory:

```hcl
module "firewall-policy" {
  source    = "./fabric/modules/net-firewall-policy"
  name      = "test-1"
  parent_id = "folders/1234567890"
  attachments = {
    test = "folders/4567890123"
  }
  ingress_rules = {
    ssh = {
      priority = 1002
      match = {
        source_ranges  = ["10.0.0.0/8"]
        layer4_configs = [{ protocol = "tcp", ports = ["22"] }]
      }
    }
  }
  rules_factory_config = {
    cidr_file_path          = "configs/cidrs.yaml"
    egress_rules_file_path  = "configs/egress.yaml"
    ingress_rules_file_path = "configs/ingress.yaml"
  }
}
# tftest modules=1 resources=5 files=cidrs,egress,ingress inventory=factory.yaml
```

```yaml
# tftest-file id=cidrs path=configs/cidrs.yaml
rfc1918:
  - 10.0.0.0/8
  - 172.16.0.0/12
  - 192.168.0.0/24
```

```yaml
# tftest-file id=egress path=configs/egress.yaml
smtp:
  priority: 900
  match:
   destination_ranges:
   - rfc1918
   layer4_configs:
   - protocol: tcp
     ports:
     - 25
```

```yaml
# tftest-file id=ingress path=configs/ingress.yaml
icmp:
  priority: 1000
  match:
   source_ranges:
   - 10.0.0.0/8
   layer4_configs:
   - protocol: icmp
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L100) | Policy name. | <code>string</code> | ✓ |  |
| [parent_id](variables.tf#L106) | Parent node where the policy will be created, `folders/nnn` or `organizations/nnn` for hierarchical policy, project id for a network policy. | <code>string</code> | ✓ |  |
| [attachments](variables.tf#L17) | Ids of the resources to which this policy will be attached, in descriptive name => self link format. Specify folders or organization for hierarchical policy, VPCs for network policy. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L24) | Policy description. | <code>string</code> |  | <code>null</code> |
| [egress_rules](variables.tf#L30) | List of egress rule definitions, action can be 'allow', 'deny', 'goto_next'. The match.layer4configs map is in protocol => optional [ports] format. | <code title="map&#40;object&#40;&#123;&#10;  priority                &#61; number&#10;  action                  &#61; optional&#40;string, &#34;deny&#34;&#41;&#10;  description             &#61; optional&#40;string&#41;&#10;  disabled                &#61; optional&#40;bool, false&#41;&#10;  enable_logging          &#61; optional&#40;bool&#41;&#10;  target_service_accounts &#61; optional&#40;list&#40;string&#41;&#41;&#10;  target_tags             &#61; optional&#40;list&#40;string&#41;&#41;&#10;  match &#61; object&#40;&#123;&#10;    address_groups       &#61; optional&#40;list&#40;string&#41;&#41;&#10;    fqdns                &#61; optional&#40;list&#40;string&#41;&#41;&#10;    region_codes         &#61; optional&#40;list&#40;string&#41;&#41;&#10;    threat_intelligences &#61; optional&#40;list&#40;string&#41;&#41;&#10;    destination_ranges   &#61; optional&#40;list&#40;string&#41;&#41;&#10;    source_ranges        &#61; optional&#40;list&#40;string&#41;&#41;&#10;    source_tags          &#61; optional&#40;list&#40;string&#41;&#41;&#10;    layer4_configs &#61; optional&#40;list&#40;object&#40;&#123;&#10;      protocol &#61; optional&#40;string, &#34;all&#34;&#41;&#10;      ports    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;, &#91;&#123;&#125;&#93;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ingress_rules](variables.tf#L65) | List of ingress rule definitions, action can be 'allow', 'deny', 'goto_next'. | <code title="map&#40;object&#40;&#123;&#10;  priority                &#61; number&#10;  action                  &#61; optional&#40;string, &#34;allow&#34;&#41;&#10;  description             &#61; optional&#40;string&#41;&#10;  disabled                &#61; optional&#40;bool, false&#41;&#10;  enable_logging          &#61; optional&#40;bool&#41;&#10;  target_service_accounts &#61; optional&#40;list&#40;string&#41;&#41;&#10;  target_tags             &#61; optional&#40;list&#40;string&#41;&#41;&#10;  match &#61; object&#40;&#123;&#10;    address_groups       &#61; optional&#40;list&#40;string&#41;&#41;&#10;    fqdns                &#61; optional&#40;list&#40;string&#41;&#41;&#10;    region_codes         &#61; optional&#40;list&#40;string&#41;&#41;&#10;    threat_intelligences &#61; optional&#40;list&#40;string&#41;&#41;&#10;    destination_ranges   &#61; optional&#40;list&#40;string&#41;&#41;&#10;    source_ranges        &#61; optional&#40;list&#40;string&#41;&#41;&#10;    source_tags          &#61; optional&#40;list&#40;string&#41;&#41;&#10;    layer4_configs &#61; optional&#40;list&#40;object&#40;&#123;&#10;      protocol &#61; optional&#40;string, &#34;all&#34;&#41;&#10;      ports    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;, &#91;&#123;&#125;&#93;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [region](variables.tf#L112) | Policy region. Leave null for hierarchical policy, set to 'global' for a global network policy. | <code>string</code> |  | <code>null</code> |
| [rules_factory_config](variables.tf#L118) | Configuration for the optional rules factory. | <code title="object&#40;&#123;&#10;  cidr_file_path          &#61; optional&#40;string&#41;&#10;  egress_rules_file_path  &#61; optional&#40;string&#41;&#10;  ingress_rules_file_path &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified firewall policy id. |  |
<!-- END TFDOC -->
