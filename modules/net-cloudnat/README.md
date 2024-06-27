# Cloud NAT Module

Simple Cloud NAT management, with optional router creation.

<!-- BEGIN TOC -->
- [Basic Example](#basic-example)
- [Subnetwork configuration](#subnetwork-configuration)
- [Reserved IPs and custom rules](#reserved-ips-and-custom-rules)
- [Hybrid NAT](#hybrid-nat)
- [NAT for Proxy net or Secure Web Proxy](#nat-for-proxy-net-or-secure-web-proxy)
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
        self_link     = "projects/${var.project_id}/regions/${var.region}/subnetworks/net-1"
        all_ranges    = false
        primary_range = true
      },
      {
        # both primary and specified secondary ranges
        self_link        = "projects/${var.project_id}/regions/${var.region}/subnetworks/net-2"
        all_ranges       = false
        primary_range    = true
        secondary_ranges = ["pods"]
      },
      {
        # secondary range only
        self_link        = "projects/${var.project_id}/regions/${var.region}/subnetworks/net-3"
        all_ranges       = false
        primary_range    = false
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
## Hybrid NAT
```hcl
module "vpc1" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "vpc1"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "vpc1-subnet"
      region        = var.region
    }
  ]
  subnets_private_nat = [
    {
      ip_cidr_range = "192.168.15.0/24"
      name          = "vpc1-nat"
      region        = var.region
    }
  ]
}

module "vpc1-nat" {
  source         = "./fabric/modules/net-cloudnat"
  project_id     = var.project_id
  region         = var.region
  name           = "vpc1-nat"
  type           = "PRIVATE"
  router_network = module.vpc1.id
  config_source_subnetworks = {
    all = false
    subnetworks = [
      {
        self_link = module.vpc1.subnet_ids["${var.region}/vpc1-subnet"]
      }
    ]
  }
  config_port_allocation = {
    enable_endpoint_independent_mapping = false
    enable_dynamic_port_allocation      = true
  }
  rules = [
    {
      description = "private nat"
      match       = "nexthop.is_hybrid"
      source_ranges = [
        module.vpc1.subnets_private_nat["${var.region}/vpc1-nat"].id
      ]
    }
  ]
}
# tftest modules=2 resources=7 inventory=hybrid.yaml
```

## NAT for Proxy net or Secure Web Proxy
By default NAT is provided only for VMs (`ENDPOINT_TYPE_VM`). You can also define endpoint type for managed proxy (`ENDPOINT_TYPE_MANAGED_PROXY_LB`) or Secure Web Proxy (`ENDPOINT_TYPE_SWG`). Currently only one `endpoint_type` can be provided per NAT instance.

```hcl
module "nat" {
  source         = "./fabric/modules/net-cloudnat"
  project_id     = var.project_id
  region         = var.region
  name           = "default"
  endpoint_types = ["ENDPOINT_TYPE_MANAGED_PROXY_LB"]
  router_network = var.vpc.self_link
}
# tftest modules=1 resources=2 inventory=proxy-net-nat.yaml e2e
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L107) | Name of the Cloud NAT resource. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L112) | Project where resources will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L117) | Region where resources will be created. | <code>string</code> | ✓ |  |
| [addresses](variables.tf#L17) | Optional list of external address self links. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [config_port_allocation](variables.tf#L23) | Configuration for how to assign ports to virtual machines. min_ports_per_vm and max_ports_per_vm have no effect unless enable_dynamic_port_allocation is set to 'true'. | <code title="object&#40;&#123;&#10;  enable_endpoint_independent_mapping &#61; optional&#40;bool, true&#41;&#10;  enable_dynamic_port_allocation      &#61; optional&#40;bool, false&#41;&#10;  min_ports_per_vm                    &#61; optional&#40;number&#41;&#10;  max_ports_per_vm                    &#61; optional&#40;number, 65536&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [config_source_subnetworks](variables.tf#L39) | Subnetwork configuration. | <code title="object&#40;&#123;&#10;  all                 &#61; optional&#40;bool, true&#41;&#10;  primary_ranges_only &#61; optional&#40;bool&#41;&#10;  subnetworks &#61; optional&#40;list&#40;object&#40;&#123;&#10;    self_link        &#61; string&#10;    all_ranges       &#61; optional&#40;bool, true&#41;&#10;    primary_range    &#61; optional&#40;bool, false&#41;&#10;    secondary_ranges &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [config_timeouts](variables.tf#L69) | Timeout configurations. | <code title="object&#40;&#123;&#10;  icmp            &#61; optional&#40;number&#41;&#10;  tcp_established &#61; optional&#40;number&#41;&#10;  tcp_time_wait   &#61; optional&#40;number&#41;&#10;  tcp_transitory  &#61; optional&#40;number&#41;&#10;  udp             &#61; optional&#40;number&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [endpoint_types](variables.tf#L82) | Specifies the endpoint Types supported by the NAT Gateway. Supported values include: ENDPOINT_TYPE_VM, ENDPOINT_TYPE_SWG, ENDPOINT_TYPE_MANAGED_PROXY_LB. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [logging_filter](variables.tf#L101) | Enables logging if not null, value is one of 'ERRORS_ONLY', 'TRANSLATIONS_ONLY', 'ALL'. | <code>string</code> |  | <code>null</code> |
| [router_asn](variables.tf#L122) | Router ASN used for auto-created router. | <code>number</code> |  | <code>null</code> |
| [router_create](variables.tf#L128) | Create router. | <code>bool</code> |  | <code>true</code> |
| [router_name](variables.tf#L134) | Router name, leave blank if router will be created to use auto generated name. | <code>string</code> |  | <code>null</code> |
| [router_network](variables.tf#L140) | Name of the VPC used for auto-created router. | <code>string</code> |  | <code>null</code> |
| [rules](variables.tf#L146) | List of rules associated with this NAT. | <code title="list&#40;object&#40;&#123;&#10;  description   &#61; optional&#40;string&#41;&#10;  match         &#61; string&#10;  source_ips    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  source_ranges &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |
| [type](variables.tf#L166) | Whether this Cloud NAT is used for public or private IP translation. One of 'PUBLIC' or 'PRIVATE'. | <code>string</code> |  | <code>&#34;PUBLIC&#34;</code> |

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
