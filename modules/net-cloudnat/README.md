# Cloud NAT Module

Simple Cloud NAT management, with optional router creation.

<!-- BEGIN TOC -->
- [Basic Example](#basic-example)
- [Subnetwork configuration](#subnetwork-configuration)
- [Reserved IPs and custom rules](#reserved-ips-and-custom-rules)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Basic Example

```hcl
module "nat" {
  source         = "./fabric/modules/net-cloudnat"
  project_id     = var.project_id
  region         = var.region
  name           = "default"
  router_network = var.vpc.self_link
}
# tftest modules=1 resources=2 e2e
```

## Subnetwork configuration

Subnetwork configuration is defined via the `config_source_subnetworks` variable:

- the default is to configure all ranges for all subnets
- to only configure primary ranges set `config_source_subnetworks.primary_ranges_only` to `true`
- to specify a list of subnets set `config_source_subnetworks.all` to `false` and provide a list of subnets in `config_source_subnetworks.subnetworks`

When specifying subnets the default for IP ranges is to consider all ranges (primary and secondaries). More control can be obtained via the `all` subnetwork attribute: when set to `false` only the primary subnet range is considered, unless secondary ranges are specified via the `secondary_ranges` attribute.

```hcl
module "nat" {
  source         = "./fabric/modules/net-cloudnat"
  project_id     = var.project_id
  region         = var.region
  name           = "default"
  router_network = var.vpc.self_link
  config_source_subnetworks = {
    all = false
    subnetworks = [
      {
        # all ip ranges
        self_link = "projects/${var.project_id}/regions/${var.region}/subnetworks/net-0"
      },
      {
        # primary range only
        self_link  = "projects/${var.project_id}/regions/${var.region}/subnetworks/net-1"
        all_ranges = false
      },
      {
        # both primary and specified secondary ranges
        self_link        = "projects/${var.project_id}/regions/${var.region}/subnetworks/net-2"
        all_ranges       = false
        secondary_ranges = ["pods"]
      }
    ]
  }
}
# tftest modules=1 resources=2
```

## Reserved IPs and custom rules

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  external_addresses = {
    a1 = { region = var.region }
    a2 = { region = var.region }
    a3 = { region = var.region }
  }
}

module "nat" {
  source         = "./fabric/modules/net-cloudnat"
  project_id     = var.project_id
  region         = var.region
  name           = "nat"
  router_network = var.vpc.self_link
  addresses = [
    module.addresses.external_addresses["a1"].self_link,
    module.addresses.external_addresses["a3"].self_link
  ]
  config_port_allocation = {
    enable_endpoint_independent_mapping = false
  }
  rules = [
    {
      description = "rule1"
      match       = "destination.ip == '8.8.8.8'"
      source_ips = [
        module.addresses.external_addresses["a2"].self_link
      ]
    }
  ]
}
# tftest modules=2 resources=5 inventory=rules.yaml e2e
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L77) | Name of the Cloud NAT resource. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L82) | Project where resources will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L87) | Region where resources will be created. | <code>string</code> | ✓ |  |
| [addresses](variables.tf#L17) | Optional list of external address self links. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [config_port_allocation](variables.tf#L23) | Configuration for how to assign ports to virtual machines. min_ports_per_vm and max_ports_per_vm have no effect unless enable_dynamic_port_allocation is set to 'true'. | <code title="object&#40;&#123;&#10;  enable_endpoint_independent_mapping &#61; optional&#40;bool, true&#41;&#10;  enable_dynamic_port_allocation      &#61; optional&#40;bool, false&#41;&#10;  min_ports_per_vm                    &#61; optional&#40;number, 64&#41;&#10;  max_ports_per_vm                    &#61; optional&#40;number, 65536&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [config_source_subnetworks](variables.tf#L39) | Subnetwork configuration. | <code title="object&#40;&#123;&#10;  all                 &#61; optional&#40;bool, true&#41;&#10;  primary_ranges_only &#61; optional&#40;bool&#41;&#10;  subnetworks &#61; optional&#40;list&#40;object&#40;&#123;&#10;    self_link        &#61; string&#10;    all_ranges       &#61; optional&#40;bool, true&#41;&#10;    secondary_ranges &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [config_timeouts](variables.tf#L58) | Timeout configurations. | <code title="object&#40;&#123;&#10;  icmp            &#61; optional&#40;number, 30&#41;&#10;  tcp_established &#61; optional&#40;number, 1200&#41;&#10;  tcp_time_wait   &#61; optional&#40;number, 120&#41;&#10;  tcp_transitory  &#61; optional&#40;number, 30&#41;&#10;  udp             &#61; optional&#40;number, 30&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_filter](variables.tf#L71) | Enables logging if not null, value is one of 'ERRORS_ONLY', 'TRANSLATIONS_ONLY', 'ALL'. | <code>string</code> |  | <code>null</code> |
| [router_asn](variables.tf#L92) | Router ASN used for auto-created router. | <code>number</code> |  | <code>null</code> |
| [router_create](variables.tf#L98) | Create router. | <code>bool</code> |  | <code>true</code> |
| [router_name](variables.tf#L104) | Router name, leave blank if router will be created to use auto generated name. | <code>string</code> |  | <code>null</code> |
| [router_network](variables.tf#L110) | Name of the VPC used for auto-created router. | <code>string</code> |  | <code>null</code> |
| [rules](variables.tf#L116) | List of rules associated with this NAT. | <code title="list&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string&#41;,&#10;  match       &#61; string&#10;  source_ips  &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified NAT (router) id. |  |
| [name](outputs.tf#L22) | Name of the Cloud NAT. |  |
| [nat_ip_allocate_option](outputs.tf#L27) | NAT IP allocation mode. |  |
| [region](outputs.tf#L32) | Cloud NAT region. |  |
| [router](outputs.tf#L37) | Cloud NAT router resources (if auto created). |  |
| [router_name](outputs.tf#L46) | Cloud NAT router name. |  |
<!-- END TFDOC -->
