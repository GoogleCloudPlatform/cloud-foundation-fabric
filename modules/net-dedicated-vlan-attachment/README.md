# VLAN Attachment module

This module allows for the provisioning of [VLAN Attachments](https://cloud.google.com/network-connectivity/docs/interconnect/how-to/dedicated/creating-vlan-attachments?hl=it) created from [Dedicated Interconnect](https://cloud.google.com/network-connectivity/docs/interconnect/concepts/dedicated-overview?hl=en) connections.

## Examples

### Single VLAN Attachment (No SLA)

```hcl
resource "google_compute_router" "interconnect-router" {
  name    = "interconnect-router"
  network = "mynet"
  project = "myproject"
  region  = "europe-west8"
  bgp {
    advertise_mode    = "CUSTOM"
    asn               = 64514
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = "10.255.255.0/24"
    }
    advertised_ip_ranges {
      range = "192.168.255.0/24"
    }
  }
}

module "example-va" {
  source       = "./fabric/modules/net-dedicated-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west8"
  name         = "vlan-attachment"
  bandwidth    = "BPS_10G"
  bgp_range    = "169.254.0.0/30"
  description  = "Example vlan attachment"
  interconnect = "interconnect-a"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = google_compute_router.interconnect-router.id
  }
  vlan_tag = 12345
}
# tftest modules=1 resources=4
```

### Two VLAN Attachments on a single region (99.9% SLA)

```hcl
resource "google_compute_router" "interconnect-router" {
  name    = "interconnect-router"
  network = "mynet"
  project = "myproject"
  region  = "europe-west8"
  bgp {
    asn               = 64514
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = "10.255.255.0/24"
    }
    advertised_ip_ranges {
      range = "192.168.255.0/24"
    }
  }
}

module "example-va-a" {
  source       = "./fabric/modules/net-dedicated-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west8"
  name         = "vlan-attachment-a"
  bandwidth    = "BPS_10G"
  bgp_range    = "169.254.0.0/30"
  description  = "interconnect-a vlan attachment 0"
  interconnect = "interconnect-a"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = google_compute_router.interconnect-router.id
  }
  vlan_tag = 1001
}

module "example-va-b" {
  source       = "./fabric/modules/net-dedicated-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west8"
  name         = "vlan-attachment-b"
  bandwidth    = "BPS_10G"
  bgp_range    = "169.254.0.4/30"
  description  = "interconnect-b vlan attachment 0"
  interconnect = "interconnect-b"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = google_compute_router.interconnect-router.id
  }
  vlan_tag = 1002
}
# tftest modules=2 resources=7
```

### Four VLAN Attachments on two regions (99.99% SLA)

```hcl

resource "google_compute_router" "interconnect-router-ew8" {
  name    = "interconnect-router-ew8"
  network = "mynet"
  project = "myproject"
  region  = "europe-west8"
  bgp {
    asn               = 64514
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = "10.255.255.0/24"
    }
    advertised_ip_ranges {
      range = "192.168.255.0/24"
    }
  }
}

resource "google_compute_router" "interconnect-router-ew12" {
  name    = "interconnect-router-ew12"
  network = "mynet"
  project = "myproject"
  region  = "europe-west12"
  bgp {
    asn               = 64514
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = "10.255.255.0/24"
    }
    advertised_ip_ranges {
      range = "192.168.255.0/24"
    }
  }
}

module "example-va-a-ew8" {
  source       = "./fabric/modules/net-dedicated-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west8"
  name         = "vlan-attachment-a-ew8"
  bandwidth    = "BPS_10G"
  bgp_range    = "169.254.0.0/30"
  description  = "interconnect-a-ew8 vlan attachment 0"
  interconnect = "interconnect-a-ew8"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = google_compute_router.interconnect-router-ew8.id
  }
  vlan_tag = 1001
}

module "example-va-b-ew8" {
  source       = "./fabric/modules/net-dedicated-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west8"
  name         = "vlan-attachment-b-ew8"
  bandwidth    = "BPS_10G"
  bgp_range    = "169.254.0.4/30"
  description  = "interconnect-b-ew8 vlan attachment 0"
  interconnect = "interconnect-b-ew8"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = google_compute_router.interconnect-router-ew8.id
  }
  vlan_tag = 1002
}

module "example-va-a-ew12" {
  source       = "./fabric/modules/net-dedicated-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west12"
  name         = "vlan-attachment-a-ew12"
  bandwidth    = "BPS_10G"
  bgp_range    = "169.254.1.0/30"
  description  = "interconnect-a-ew12 vlan attachment 0"
  interconnect = "interconnect-a-ew12"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = google_compute_router.interconnect-router-ew12.id
  }
  vlan_tag = 1003
}

module "example-va-b-ew12" {
  source       = "./fabric/modules/net-dedicated-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west12"
  name         = "vlan-attachment-b-ew12"
  bandwidth    = "BPS_10G"
  bgp_range    = "169.254.1.4/30"
  description  = "interconnect-b-ew12 vlan attachment 0"
  interconnect = "interconnect-b-ew12"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = google_compute_router.interconnect-router-ew12.id
  }
  vlan_tag = 1004
}
# tftest modules=4 resources=14
```

### IPSec over Interconnect enabled setup

Refer to the [HA VPN over Interconnect Blueprint](../../blueprints/networking/ha-vpn-over-interconnect/) for an all-encompassing example.

```hcl
resource "google_compute_router" "encrypted-interconnect-underlay-router-ew8" {
  name                          = "encrypted-interconnect-underlay-router-ew8"
  project                       = "myproject"
  network                       = "mynet"
  region                        = "europe-west8"
  encrypted_interconnect_router = true
  bgp {
    advertise_mode = "DEFAULT"
    asn            = 64514
  }
}

module "example-va-a" {
  source       = "./fabric/modules/net-dedicated-vlan-attachment"
  project_id   = "myproject"
  network      = "mynet"
  region       = "europe-west8"
  name         = "encrypted-vlan-attachment-a"
  bandwidth    = "BPS_10G"
  bgp_range    = "169.254.0.0/30"
  description  = "example-va-a vlan attachment"
  interconnect = "interconnect-a"
  peer_asn     = "65001"
  router_config = {
    create = false
    name   = google_compute_router.encrypted-interconnect-underlay-router-ew8.id
  }
  vlan_tag              = 1001
  vpn_gateways_ip_range = "10.255.255.0/29" # Allows for up to 8 tunnels
}

module "example-va-b" {
  source       = "./fabric/modules/net-dedicated-vlan-attachment"
  project_id   = "myproject"
  network      = "mynet"
  region       = "europe-west8"
  name         = "encrypted-vlan-attachment-b"
  bandwidth    = "BPS_10G"
  bgp_range    = "169.254.0.4/30"
  description  = "example-va-b vlan attachment"
  interconnect = "interconnect-b"
  peer_asn     = "65001"
  router_config = {
    create = false
    name   = google_compute_router.encrypted-interconnect-underlay-router-ew8.id
  }
  vlan_tag              = 1002
  vpn_gateways_ip_range = "10.255.255.8/29" # Allows for up to 8 tunnels
}
# tftest modules=2 resources=9
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [description](variables.tf#L36) | VLAN attachment description. | <code>string</code> | ✓ |  |
| [interconnect](variables.tf#L41) | The identifier of the interconnect the VLAN attachment binds to. | <code>string</code> | ✓ |  |
| [name](variables.tf#L58) | The common resources name, used after resource type prefix and suffix. | <code>string</code> | ✓ |  |
| [network](variables.tf#L63) | The VPC name to which resources are associated to. | <code>string</code> | ✓ |  |
| [peer_asn](variables.tf#L68) | The on-premises underlay router ASN. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L73) | The project id where resources are created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L78) | The region where resources are created. | <code>string</code> | ✓ |  |
| [router_config](variables.tf#L83) | Cloud Router configuration for the VPN. If you want to reuse an existing router, set create to false and use name to specify the desired router. | <code title="object&#40;&#123;&#10;  create    &#61; optional&#40;bool, true&#41;&#10;  asn       &#61; optional&#40;number, 65001&#41;&#10;  name      &#61; optional&#40;string, &#34;router&#34;&#41;&#10;  keepalive &#61; optional&#40;number&#41;&#10;  custom_advertise &#61; optional&#40;object&#40;&#123;&#10;    all_subnets &#61; bool&#10;    ip_ranges   &#61; map&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  bfd &#61; optional&#40;object&#40;&#123;&#10;    session_initialization_mode &#61; optional&#40;string, &#34;ACTIVE&#34;&#41;&#10;    min_receive_interval        &#61; optional&#40;number&#41;&#10;    min_transmit_interval       &#61; optional&#40;number&#41;&#10;    multiplier                  &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [vlan_tag](variables.tf#L104) | The VLAN id to be used for this VLAN attachment. | <code>number</code> | ✓ |  |
| [admin_enabled](variables.tf#L17) | Whether the VLAN attachment is enabled. | <code>bool</code> |  | <code>true</code> |
| [bandwidth](variables.tf#L23) | The bandwidth assigned to the VLAN attachment (e.g. BPS_10G). | <code>string</code> |  | <code>&#34;BPS_10G&#34;</code> |
| [bgp_range](variables.tf#L30) | The underlay link-local IP range (in CIDR notation). | <code>string</code> |  | <code>&#34;169.254.128.0&#47;29&#34;</code> |
| [ipsec_gateway_ip_ranges](variables.tf#L46) | IPSec Gateway IP Ranges. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [mtu](variables.tf#L52) | The MTU associated to the VLAN attachment (1440 / 1500). | <code>number</code> |  | <code>1500</code> |
| [vpn_gateways_ip_range](variables.tf#L109) | The IP range (cidr notation) to be used for the GCP VPN gateways. If null IPSec over Interconnect is not enabled. | <code>string</code> |  | <code>null</code> |

<!-- END TFDOC -->
