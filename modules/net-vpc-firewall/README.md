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
  source               = "./modules/net-vpc-firewall"
  project_id           = "my-project"
  network              = "my-network"
  admin_ranges         = ["10.0.0.0/8"]
}
# tftest modules=1 resources=4
```

### Custom rules

This is an example of how to define custom rules, with a sample rule allowing open ingress for the NTP protocol to instances with the `ntp-svc` tag.

```hcl
module "firewall" {
  source       = "./modules/net-vpc-firewall"
  project_id   = "my-project"
  network      = "my-network"
  admin_ranges = ["10.0.0.0/8"]
  custom_rules = {
    ntp-svc = {
      description          = "NTP service."
      direction            = "INGRESS"
      action               = "allow"
      sources              = []
      ranges               = ["0.0.0.0/0"]
      targets              = ["ntp-svc"]
      use_service_accounts = false
      rules                = [{ protocol = "udp", ports = [123] }]
      extra_attributes     = {}
    }
  }
}
# tftest modules=1 resources=5
```

### No predefined rules

If you don't want any predefined rules set `admin_ranges`, `http_source_ranges`, `https_source_ranges` and `ssh_source_ranges` to an empty list.

```hcl
module "firewall" {
  source              = "./modules/net-vpc-firewall"
  project_id          = "my-project"
  network             = "my-network"
  admin_ranges        = []
  http_source_ranges  = []
  https_source_ranges = []
  ssh_source_ranges   = []
  custom_rules = {
    allow-https = {
      description          = "Allow HTTPS from internal networks."
      direction            = "INGRESS"
      action               = "allow"
      sources              = []
      ranges               = ["rfc1918"]
      targets              = []
      use_service_accounts = false
      rules                = [{ protocol = "tcp", ports = [443] }]
      extra_attributes     = {}
    }
  }
}
# tftest modules=1 resources=1
```


### Rules Factory
The module includes a rules factory (see [Resource Factories](../../examples/factories/)) for the massive creation of rules leveraging YaML configuration files. Each configuration file can optionally contain more than one rule which a structure that reflects the `custom_rules` variable.

```hcl
module "firewall" {
  source             = "./modules/net-vpc-firewall"
  project_id         = "my-project"
  network            = "my-network"
  data_folder        = "config/firewall"
  cidr_template_file = "config/cidr_template.yaml"
}
# tftest skip
```

```yaml
# ./config/firewall/load_balancers.yaml
allow-healthchecks:
  description: Allow ingress from healthchecks.
  direction: INGRESS
  action: allow
  sources: []
  ranges:
    - $healthchecks
  targets: ["lb-backends"]
  use_service_accounts: false
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
| [network](variables.tf#L80) | Name of the network this set of firewall rules applies to. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L85) | Project id of the project that holds the network. | <code>string</code> | ✓ |  |
| [admin_ranges](variables.tf#L17) | IP CIDR ranges that have complete access to all subnets. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [cidr_template_file](variables.tf#L23) | Path for optional file containing name->cidr_list map to be used by the rules factory. | <code>string</code> |  | <code>null</code> |
| [custom_rules](variables.tf#L29) | List of custom rule definitions (refer to variables file for syntax). | <code title="map&#40;object&#40;&#123;&#10;  description          &#61; string&#10;  direction            &#61; string&#10;  action               &#61; string &#35; &#40;allow&#124;deny&#41;&#10;  ranges               &#61; list&#40;string&#41;&#10;  sources              &#61; list&#40;string&#41;&#10;  targets              &#61; list&#40;string&#41;&#10;  use_service_accounts &#61; bool&#10;  rules &#61; list&#40;object&#40;&#123;&#10;    protocol &#61; string&#10;    ports    &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  extra_attributes &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_folder](variables.tf#L48) | Path for optional folder containing firewall rules defined as YaML objects used by the rules factory. | <code>string</code> |  | <code>null</code> |
| [http_source_ranges](variables.tf#L54) | List of IP CIDR ranges for tag-based HTTP rule, defaults to the health checkers ranges. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#34;35.191.0.0&#47;16&#34;, &#34;130.211.0.0&#47;22&#34;, &#34;209.85.152.0&#47;22&#34;, &#34;209.85.204.0&#47;22&#34;&#93;</code> |
| [https_source_ranges](variables.tf#L60) | List of IP CIDR ranges for tag-based HTTPS rule, defaults to the health checkers ranges. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#34;35.191.0.0&#47;16&#34;, &#34;130.211.0.0&#47;22&#34;, &#34;209.85.152.0&#47;22&#34;, &#34;209.85.204.0&#47;22&#34;&#93;</code> |
| [named_ranges](variables.tf#L66) | Names that can be used of valid values for the `ranges` field of `custom_rules`. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code title="&#123;&#10;  any                   &#61; &#91;&#34;0.0.0.0&#47;0&#34;&#93;&#10;  dns-forwarders        &#61; &#91;&#34;35.199.192.0&#47;19&#34;&#93;&#10;  health-checkers       &#61; &#91;&#34;35.191.0.0&#47;16&#34;, &#34;130.211.0.0&#47;22&#34;, &#34;209.85.152.0&#47;22&#34;, &#34;209.85.204.0&#47;22&#34;&#93;&#10;  iap-forwarders        &#61; &#91;&#34;35.235.240.0&#47;20&#34;&#93;&#10;  private-googleapis    &#61; &#91;&#34;199.36.153.8&#47;30&#34;&#93;&#10;  restricted-googleapis &#61; &#91;&#34;199.36.153.4&#47;30&#34;&#93;&#10;  rfc1918               &#61; &#91;&#34;10.0.0.0&#47;8&#34;, &#34;172.16.0.0&#47;12&#34;, &#34;192.168.0.0&#47;16&#34;&#93;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [ssh_source_ranges](variables.tf#L90) | List of IP CIDR ranges for tag-based SSH rule, defaults to the IAP forwarders range. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#34;35.235.240.0&#47;20&#34;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [admin_ranges](outputs.tf#L17) | Admin ranges data. |  |
| [custom_egress_allow_rules](outputs.tf#L26) | Custom egress rules with allow blocks. |  |
| [custom_egress_deny_rules](outputs.tf#L34) | Custom egress rules with allow blocks. |  |
| [custom_ingress_allow_rules](outputs.tf#L42) | Custom ingress rules with allow blocks. |  |
| [custom_ingress_deny_rules](outputs.tf#L50) | Custom ingress rules with deny blocks. |  |
| [rules](outputs.tf#L58) | All google_compute_firewall resources created. |  |

<!-- END TFDOC -->
