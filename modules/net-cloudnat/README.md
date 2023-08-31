# Cloud NAT Module

Simple Cloud NAT management, with optional router creation.

<!-- BEGIN TOC -->
- [Basic Example](#basic-example)
- [Reserved IPs and custom rules](#reserved-ips-and-custom-rules)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Basic Example

```hcl
module "nat" {
  source         = "./fabric/modules/net-cloudnat"
  project_id     = "my-project"
  region         = "europe-west1"
  name           = "default"
  router_network = "my-vpc"
}
# tftest modules=1 resources=2
```

## Reserved IPs and custom rules

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = "my-project"
  external_addresses = {
    a1 = { region = "europe-west1" }
    a2 = { region = "europe-west1" }
    a3 = { region = "europe-west1" }
  }
}

module "nat" {
  source         = "./fabric/modules/net-cloudnat"
  project_id     = "my-project"
  region         = "europe-west1"
  name           = "nat"
  router_network = "my-vpc"
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
# tftest modules=2 resources=5 inventory=rules.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L63) | Name of the Cloud NAT resource. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L68) | Project where resources will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L73) | Region where resources will be created. | <code>string</code> | ✓ |  |
| [addresses](variables.tf#L17) | Optional list of external address self links. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [config_port_allocation](variables.tf#L23) | Configuration for how to assign ports to virtual machines. min_ports_per_vm and max_ports_per_vm have no effect unless enable_dynamic_port_allocation is set to 'true'. | <code title="object&#40;&#123;&#10;  enable_endpoint_independent_mapping &#61; optional&#40;bool, true&#41;&#10;  enable_dynamic_port_allocation      &#61; optional&#40;bool, false&#41;&#10;  min_ports_per_vm                    &#61; optional&#40;number, 64&#41;&#10;  max_ports_per_vm                    &#61; optional&#40;number, 65536&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [config_source_subnets](variables.tf#L39) | Subnetwork configuration (ALL_SUBNETWORKS_ALL_IP_RANGES, ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES, LIST_OF_SUBNETWORKS). | <code>string</code> |  | <code>&#34;ALL_SUBNETWORKS_ALL_IP_RANGES&#34;</code> |
| [config_timeouts](variables.tf#L45) | Timeout configurations. | <code title="object&#40;&#123;&#10;  icmp            &#61; optional&#40;number, 30&#41;&#10;  tcp_established &#61; optional&#40;number, 1200&#41;&#10;  tcp_transitory  &#61; optional&#40;number, 30&#41;&#10;  udp             &#61; optional&#40;number, 30&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_filter](variables.tf#L57) | Enables logging if not null, value is one of 'ERRORS_ONLY', 'TRANSLATIONS_ONLY', 'ALL'. | <code>string</code> |  | <code>null</code> |
| [router_asn](variables.tf#L78) | Router ASN used for auto-created router. | <code>number</code> |  | <code>null</code> |
| [router_create](variables.tf#L84) | Create router. | <code>bool</code> |  | <code>true</code> |
| [router_name](variables.tf#L90) | Router name, leave blank if router will be created to use auto generated name. | <code>string</code> |  | <code>null</code> |
| [router_network](variables.tf#L96) | Name of the VPC used for auto-created router. | <code>string</code> |  | <code>null</code> |
| [rules](variables.tf#L102) | List of rules associated with this NAT. | <code title="list&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string&#41;,&#10;  match       &#61; string&#10;  source_ips  &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |
| [subnetworks](variables.tf#L113) | Subnetworks to NAT, only used when config_source_subnets equals LIST_OF_SUBNETWORKS. | <code title="list&#40;object&#40;&#123;&#10;  self_link            &#61; string,&#10;  config_source_ranges &#61; list&#40;string&#41;&#10;  secondary_ranges     &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |

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
