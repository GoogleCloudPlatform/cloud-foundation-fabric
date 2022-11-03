# Google Cloud VPC Firewall

This module allows creation and management of different types of firewall rules for a single VPC network:

- blanket ingress rules based on IP ranges that allow all traffic via the `admin_ranges` variable
- simplified tag-based ingress rules for the HTTP, HTTPS and SSH protocols via the `xxx_source_ranges` variables; HTTP and HTTPS tags match those set by the console via the "Allow HTTP(S) traffic" instance flags
- custom rules via the `custom_rules` variables

The simplified tag-based rules are enabled by default, set to the ranges of the GCP health checkers for HTTP/HTTPS, and the IAP forwarders for SSH. To disable them set the corresponding variables to empty lists.

## Examples

### Minimal open firewall

This is often useful for prototyping or testing infrastructure, allowing open ingress from the private range, enabling SSH to private addresses from IAP, and HTTP/HTTPS from the health checkers.

```hcl
module "firewall" {
  source     = "./fabric/modules/net-vpc-firewall"
  project_id = "my-project"
  network    = "my-network"
  default_rules_config = {
    admin_ranges = ["10.0.0.0/8"]
  }
}
# tftest modules=1 resources=4
```

### Custom rules

This is an example of how to define custom rules, with a sample rule allowing open ingress for the NTP protocol to instances with the `ntp-svc` tag.

```hcl
module "firewall" {
  source     = "./fabric/modules/net-vpc-firewall"
  project_id = "my-project"
  network    = "my-network"
  default_rules_config = {
    admin_ranges = ["10.0.0.0/8"]
  }
  custom_rules = {
    ntp-svc = {
      description = "NTP service."
      ranges      = ["0.0.0.0/0"]
      targets     = ["ntp-svc"]
      rules       = [{ protocol = "udp", ports = [123] }]
    }
  }
}
# tftest modules=1 resources=5
```

### No predefined rules

If you don't want any predefined rules set `admin_ranges`, `http_source_ranges`, `https_source_ranges` and `ssh_source_ranges` to an empty list.

```hcl
module "firewall" {
  source     = "./fabric/modules/net-vpc-firewall"
  project_id = "my-project"
  network    = "my-network"
  default_rules_config = {
    http_ranges  = []
    https_ranges = []
    ssh_ranges   = []
  }
  custom_rules = {
    allow-https = {
      description = "Allow HTTPS from internal networks."
      ranges      = ["rfc1918"]
      rules       = [{ protocol = "tcp", ports = [443] }]
    }
  }
}
# tftest modules=1 resources=1
```

### Rules Factory

The module includes a rules factory (see [Resource Factories](../../blueprints/factories/)) for the massive creation of rules leveraging YaML configuration files. Each configuration file can optionally contain more than one rule which a structure that reflects the `custom_rules` variable.

```hcl
module "firewall" {
  source           = "./fabric/modules/net-vpc-firewall"
  project_id       = "my-project"
  network          = "my-network"
  factories_config = {

  }
  data_folder        = "config/firewall"
  cidr_template_file = "config/cidr_template.yaml"
}
# tftest skip
```

```yaml
# ./config/firewall/load_balancers.yaml
allow-healthchecks:
  description: Allow ingress from healthchecks.
  ranges:
    - healthchecks
  targets: ["lb-backends"]
  rules:
    - protocol: tcp
      ports:
        - 80
        - 443
```

```yaml
# ./config/cidr_template.yaml
healthchecks:
  - 35.191.0.0/16
  - 130.211.0.0/22
  - 209.85.152.0/22
  - 209.85.204.0/22

```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [network](variables.tf#L85) | Name of the network this set of firewall rules applies to. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L90) | Project id of the project that holds the network. | <code>string</code> | ✓ |  |
| [custom_rules](variables.tf#L17) | List of custom rule definitions (refer to variables file for syntax). | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string&#41;&#10;  disabled    &#61; optional&#40;bool, false&#41;&#10;  enable_logging &#61; optional&#40;object&#40;&#123;&#10;    include_metadata &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  is_egress            &#61; optional&#40;bool, false&#41;&#10;  is_deny              &#61; optional&#40;bool, false&#41;&#10;  priority             &#61; optional&#40;number, 1000&#41;&#10;  ranges               &#61; optional&#40;list&#40;string&#41;&#41;&#10;  sources              &#61; optional&#40;list&#40;string&#41;&#41;&#10;  targets              &#61; optional&#40;list&#40;string&#41;&#41;&#10;  use_service_accounts &#61; optional&#40;bool, false&#41;&#10;  rules &#61; list&#40;object&#40;&#123;&#10;    protocol &#61; string&#10;    ports    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [default_rules_config](variables.tf#L40) | Optionally created convenience rules. Set the variable or individual members to null to disable. | <code title="object&#40;&#123;&#10;  admin_ranges &#61; optional&#40;list&#40;string&#41;&#41;&#10;  http_ranges &#61; optional&#40;list&#40;string&#41;, &#91;&#10;    &#34;35.191.0.0&#47;16&#34;, &#34;130.211.0.0&#47;22&#34;, &#34;209.85.152.0&#47;22&#34;, &#34;209.85.204.0&#47;22&#34;&#93;&#10;  &#41;&#10;  http_tags &#61; optional&#40;list&#40;string&#41;, &#91;&#34;http-server&#34;&#93;&#41;&#10;  https_ranges &#61; optional&#40;list&#40;string&#41;, &#91;&#10;    &#34;35.191.0.0&#47;16&#34;, &#34;130.211.0.0&#47;22&#34;, &#34;209.85.152.0&#47;22&#34;, &#34;209.85.204.0&#47;22&#34;&#93;&#10;  &#41;&#10;  https_tags &#61; optional&#40;list&#40;string&#41;, &#91;&#34;https-server&#34;&#93;&#41;&#10;  ssh_ranges &#61; optional&#40;list&#40;string&#41;, &#91;&#34;35.235.240.0&#47;20&#34;&#93;&#41;&#10;  ssh_tags   &#61; optional&#40;list&#40;string&#41;, &#91;&#34;ssh&#34;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [factories_config](variables.tf#L59) | Paths to data files and folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  cidr_tpl_file &#61; optional&#40;string&#41;&#10;  rules_folder  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [named_ranges](variables.tf#L68) | Define mapping of names to ranges that can be used in custom rules. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code title="&#123;&#10;  any            &#61; &#91;&#34;0.0.0.0&#47;0&#34;&#93;&#10;  dns-forwarders &#61; &#91;&#34;35.199.192.0&#47;19&#34;&#93;&#10;  health-checkers &#61; &#91;&#10;    &#34;35.191.0.0&#47;16&#34;, &#34;130.211.0.0&#47;22&#34;, &#34;209.85.152.0&#47;22&#34;, &#34;209.85.204.0&#47;22&#34;&#10;  &#93;&#10;  iap-forwarders        &#61; &#91;&#34;35.235.240.0&#47;20&#34;&#93;&#10;  private-googleapis    &#61; &#91;&#34;199.36.153.8&#47;30&#34;&#93;&#10;  restricted-googleapis &#61; &#91;&#34;199.36.153.4&#47;30&#34;&#93;&#10;  rfc1918               &#61; &#91;&#34;10.0.0.0&#47;8&#34;, &#34;172.16.0.0&#47;12&#34;, &#34;192.168.0.0&#47;16&#34;&#93;&#10;&#125;">&#123;&#8230;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [default_rules](outputs.tf#L17) | Default rule resources. |  |
| [rules](outputs.tf#L27) | Custom rule resources. |  |

<!-- END TFDOC -->
