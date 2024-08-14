# Google Cloud VPC Firewall

This module allows creation and management of different types of firewall rules for a single VPC network:

- custom rules via the `egress_rules` and `ingress_rules` variables
- optional predefined rules that simplify prototyping via the `default_rules_config` variable

The predefined rules are enabled by default and set to the ranges of the GCP health checkers for HTTP/HTTPS, and the IAP forwarders for SSH. See the relevant section below on how to configure or disable them.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Minimal open firewall](#minimal-open-firewall)
  - [Custom rules](#custom-rules)
  - [Controlling or turning off default rules](#controlling-or-turning-off-default-rules)
    - [Overriding default tags and ranges](#overriding-default-tags-and-ranges)
    - [Disabling predefined rules](#disabling-predefined-rules)
  - [Including source and destination ranges](#including-source-and-destination-ranges)
  - [Rules Factory](#rules-factory)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Examples

### Minimal open firewall

This is often useful for prototyping or testing infrastructure, allowing open ingress from the private range, enabling SSH to private addresses from IAP, and HTTP/HTTPS from the health checkers.

```hcl
module "firewall" {
  source     = "./fabric/modules/net-vpc-firewall"
  project_id = var.project_id
  network    = var.vpc.name
  default_rules_config = {
    admin_ranges = ["10.0.0.0/8"]
  }
}
# tftest modules=1 resources=4 inventory=basic.yaml e2e
```

### Custom rules

This is an example of how to define custom rules, with a sample rule allowing open ingress for the NTP protocol to instances with the `ntp-svc` tag.

Some implicit defaults are used in the rules variable types and can be controlled by explicitly setting specific attributes:

- action is controlled via the `deny` attribute which defaults to `true` for egress and `false` for ingress
- priority defaults to `1000`
- destination ranges (for egress) and source ranges (for ingress) default to `["0.0.0.0/0"]` if not explicitly set or set to `null`, to disable the behaviour set ranges to the empty list (`[]`)
- rules default to all protocols if not set

```hcl
module "firewall" {
  source     = "./fabric/modules/net-vpc-firewall"
  project_id = var.project_id
  network    = var.vpc.name
  default_rules_config = {
    admin_ranges = ["10.0.0.0/8"]
  }
  egress_rules = {
    # implicit deny action
    allow-egress-rfc1918 = {
      deny        = false
      description = "Allow egress to RFC 1918 ranges."
      destination_ranges = [
        "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"
      ]
    }
    allow-egress-tag = {
      deny        = false
      description = "Allow egress from a specific tag to 0/0."
      targets     = ["target-tag"]
    }
    deny-egress-all = {
      description = "Block egress."
    }
  }
  ingress_rules = {
    # implicit allow action
    allow-ingress-ntp = {
      description = "Allow NTP service based on tag."
      targets     = ["ntp-svc"]
      rules       = [{ protocol = "udp", ports = [123] }]
    }
    allow-ingress-tag = {
      description   = "Allow ingress from a specific tag."
      source_ranges = []
      sources       = ["client-tag"]
      targets       = ["target-tag"]
    }
  }
}
# tftest modules=1 resources=9 inventory=custom-rules.yaml e2e
```

### Controlling or turning off default rules

Predefined rules can be controlled or turned off via the `default_rules_config` variable.

#### Overriding default tags and ranges

Each protocol rule has a default set of tags and ranges:

- the health check range and the `http-server`/`https-server` tag for HTTP/HTTPS, matching tags set via GCP console flags on GCE instances
- the IAP forwarders range and `ssh` tag for SSH

Default tags and ranges can be overridden for each protocol, like shown here for SSH:

```hcl
module "firewall" {
  source     = "./fabric/modules/net-vpc-firewall"
  project_id = var.project_id
  network    = var.vpc.name
  default_rules_config = {
    ssh_ranges = ["10.0.0.0/8"]
    ssh_tags   = ["ssh-default"]
  }
}
# tftest modules=1 resources=3 inventory=custom-ssh-default-rule.yaml e2e
```

#### Disabling predefined rules

Default rules can be disabled individually by specifying an empty set of ranges:

```hcl
module "firewall" {
  source     = "./fabric/modules/net-vpc-firewall"
  project_id = var.project_id
  network    = var.vpc.name
  default_rules_config = {
    ssh_ranges = []
  }
}
# tftest modules=1 resources=2 inventory=no-ssh-default-rules.yaml e2e
```

Or the entire set of rules can be disabled via the `disabled` attribute:

```hcl
module "firewall" {
  source     = "./fabric/modules/net-vpc-firewall"
  project_id = var.project_id
  network    = var.vpc.name
  default_rules_config = {
    disabled = true
  }
}
# tftest modules=0 resources=0 inventory=no-default-rules.yaml e2e
```

### Including source and destination ranges

Custom rules now support including both source & destination ranges in ingress and egress rules:

```hcl
module "firewall" {
  source     = "./fabric/modules/net-vpc-firewall"
  project_id = var.project_id
  network    = var.vpc.name
  default_rules_config = {
    disabled = true
  }
  egress_rules = {
    deny-egress-source-destination-ranges = {
      description        = "Deny egress using source and destination ranges"
      source_ranges      = ["10.132.0.0/20", "10.138.0.0/20"]
      destination_ranges = ["172.16.0.0/12"]
    }
  }
  ingress_rules = {
    allow-ingress-source-destination-ranges = {
      description        = "Allow ingress using source and destination ranges"
      source_ranges      = ["172.16.0.0/12"]
      destination_ranges = ["10.132.0.0/20", "10.138.0.0/20"]
    }
  }
}
# tftest modules=1 resources=2 inventory=local-ranges.yaml e2e
```

### Rules Factory

The module includes a rules factory (see [Resource Factories](../../blueprints/factories/)) for the massive creation of rules leveraging YaML configuration files. Each configuration file can optionally contain more than one rule which a structure that reflects the `custom_rules` variable.

```hcl
module "firewall" {
  source     = "./fabric/modules/net-vpc-firewall"
  project_id = var.project_id
  network    = var.vpc.name
  factories_config = {
    rules_folder  = "configs/firewall/rules"
    cidr_tpl_file = "configs/firewall/cidrs.yaml"
  }
  default_rules_config = { disabled = true }
}
# tftest modules=1 resources=3 files=lbs,cidrs inventory=factory.yaml
```

```yaml
ingress:
  allow-healthchecks:
    description: Allow ingress from healthchecks.
    source_ranges:
      - healthchecks
    targets: ["lb-backends"]
    rules:
      - protocol: tcp
        ports:
          - 80
          - 443
  allow-service-1-to-service-2:
    description: Allow ingress from service-1 SA
    targets: ["service-2"]
    use_service_accounts: true
    sources:
      - service-1@project-id.iam.gserviceaccount.com
    rules:
      - protocol: tcp
        ports:
          - 80
          - 443
egress:
  block-telnet:
    description: block outbound telnet
    deny: true
    rules:
      - protocol: tcp
        ports:
          - 23

# tftest-file id=lbs path=configs/firewall/rules/load_balancers.yaml schema=firewall-rules.schema.json
```

```yaml
healthchecks:
  - 35.191.0.0/16
  - 130.211.0.0/22
  - 209.85.152.0/22
  - 209.85.204.0/22

# tftest-file id=cidrs path=configs/firewall/cidrs.yaml
```

Instead of using `factories_config.cidr_tpl_file` file, you can pass CIDR blocks directly in the `named_ranges` variable. This approach could be useful for dynamically generated CIDR blocks from outputs of other resources.

```hcl
module "firewall" {
  source     = "./fabric/modules/net-vpc-firewall"
  project_id = var.project_id
  network    = var.vpc.name
  factories_config = {
    rules_folder = "configs/firewall/rules"
  }
  default_rules_config = { disabled = true }
  named_ranges = {
    healthchecks = [
      "35.191.0.0/16",
      "130.211.0.0/22",
      "209.85.152.0/22",
      "209.85.204.0/22",
    ]
  }
}
# tftest modules=1 resources=3 files=lbs inventory=factory.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [network](variables.tf#L111) | Name of the network this set of firewall rules applies to. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L116) | Project id of the project that holds the network. | <code>string</code> | ✓ |  |
| [default_rules_config](variables.tf#L17) | Optionally created convenience rules. Set the 'disabled' attribute to true, or individual rule attributes to empty lists to disable. | <code title="object&#40;&#123;&#10;  admin_ranges &#61; optional&#40;list&#40;string&#41;&#41;&#10;  disabled     &#61; optional&#40;bool, false&#41;&#10;  http_ranges &#61; optional&#40;list&#40;string&#41;, &#91;&#10;    &#34;35.191.0.0&#47;16&#34;, &#34;130.211.0.0&#47;22&#34;, &#34;209.85.152.0&#47;22&#34;, &#34;209.85.204.0&#47;22&#34;&#93;&#10;  &#41;&#10;  http_tags &#61; optional&#40;list&#40;string&#41;, &#91;&#34;http-server&#34;&#93;&#41;&#10;  https_ranges &#61; optional&#40;list&#40;string&#41;, &#91;&#10;    &#34;35.191.0.0&#47;16&#34;, &#34;130.211.0.0&#47;22&#34;, &#34;209.85.152.0&#47;22&#34;, &#34;209.85.204.0&#47;22&#34;&#93;&#10;  &#41;&#10;  https_tags &#61; optional&#40;list&#40;string&#41;, &#91;&#34;https-server&#34;&#93;&#41;&#10;  ssh_ranges &#61; optional&#40;list&#40;string&#41;, &#91;&#34;35.235.240.0&#47;20&#34;&#93;&#41;&#10;  ssh_tags   &#61; optional&#40;list&#40;string&#41;, &#91;&#34;ssh&#34;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [egress_rules](variables.tf#L37) | List of egress rule definitions, default to deny action. Null destination ranges will be replaced with 0/0. | <code title="map&#40;object&#40;&#123;&#10;  deny               &#61; optional&#40;bool, true&#41;&#10;  description        &#61; optional&#40;string&#41;&#10;  destination_ranges &#61; optional&#40;list&#40;string&#41;&#41;&#10;  disabled           &#61; optional&#40;bool, false&#41;&#10;  enable_logging &#61; optional&#40;object&#40;&#123;&#10;    include_metadata &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  priority             &#61; optional&#40;number, 1000&#41;&#10;  source_ranges        &#61; optional&#40;list&#40;string&#41;&#41;&#10;  targets              &#61; optional&#40;list&#40;string&#41;&#41;&#10;  use_service_accounts &#61; optional&#40;bool, false&#41;&#10;  rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;    protocol &#61; string&#10;    ports    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#91;&#123; protocol &#61; &#34;all&#34; &#125;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [factories_config](variables.tf#L60) | Paths to data files and folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  cidr_tpl_file &#61; optional&#40;string&#41;&#10;  rules_folder  &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ingress_rules](variables.tf#L70) | List of ingress rule definitions, default to allow action. Null source ranges will be replaced with 0/0. | <code title="map&#40;object&#40;&#123;&#10;  deny               &#61; optional&#40;bool, false&#41;&#10;  description        &#61; optional&#40;string&#41;&#10;  destination_ranges &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41; &#35; empty list is needed as default to allow deletion after initial creation with a value. See https:&#47;&#47;github.com&#47;hashicorp&#47;terraform-provider-google&#47;issues&#47;14270&#10;  disabled           &#61; optional&#40;bool, false&#41;&#10;  enable_logging &#61; optional&#40;object&#40;&#123;&#10;    include_metadata &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  priority             &#61; optional&#40;number, 1000&#41;&#10;  source_ranges        &#61; optional&#40;list&#40;string&#41;&#41;&#10;  sources              &#61; optional&#40;list&#40;string&#41;&#41;&#10;  targets              &#61; optional&#40;list&#40;string&#41;&#41;&#10;  use_service_accounts &#61; optional&#40;bool, false&#41;&#10;  rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;    protocol &#61; string&#10;    ports    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#91;&#123; protocol &#61; &#34;all&#34; &#125;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [named_ranges](variables.tf#L94) | Define mapping of names to ranges that can be used in custom rules. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code title="&#123;&#10;  any            &#61; &#91;&#34;0.0.0.0&#47;0&#34;&#93;&#10;  dns-forwarders &#61; &#91;&#34;35.199.192.0&#47;19&#34;&#93;&#10;  health-checkers &#61; &#91;&#10;    &#34;35.191.0.0&#47;16&#34;, &#34;130.211.0.0&#47;22&#34;, &#34;209.85.152.0&#47;22&#34;, &#34;209.85.204.0&#47;22&#34;&#10;  &#93;&#10;  iap-forwarders        &#61; &#91;&#34;35.235.240.0&#47;20&#34;&#93;&#10;  private-googleapis    &#61; &#91;&#34;199.36.153.8&#47;30&#34;&#93;&#10;  restricted-googleapis &#61; &#91;&#34;199.36.153.4&#47;30&#34;&#93;&#10;  rfc1918               &#61; &#91;&#34;10.0.0.0&#47;8&#34;, &#34;172.16.0.0&#47;12&#34;, &#34;192.168.0.0&#47;16&#34;&#93;&#10;&#125;">&#123;&#8230;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [default_rules](outputs.tf#L17) | Default rule resources. |  |
| [rules](outputs.tf#L27) | Custom rule resources. |  |
<!-- END TFDOC -->
