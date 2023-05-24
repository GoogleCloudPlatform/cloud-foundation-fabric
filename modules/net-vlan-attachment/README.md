# VLAN Attachment module

This module allows for the provisioning of [VLAN Attachments](https://cloud.google.com/network-connectivity/docs/interconnect/how-to/dedicated/creating-vlan-attachments?hl=it) created from [Dedicated Interconnect](https://cloud.google.com/network-connectivity/docs/interconnect/concepts/dedicated-overview?hl=en) connections.

## Examples

### Single VLAN Attachment (No SLA)

```hcl
resource "google_compute_router" "interconnect-router" {
  name    = "interconnect-router"
  network = "mynet"
  project = "myproject"
  region  = "europe-west1"
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

module "example-va" {
  source       = "../cloud-foundation-fabric/modules/net-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west1"
  name         = "vlan-attachment"
  bandwidth    = "BPS_10G"
  bgp_cidr     = "169.254.0.0/30" 
  description  = "Example vlan attachment"
  interconnect = "interconnect-a"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = "interconnect-router"
  }
  vlan_tag              = 12345
}
```

### Two VLAN Attachments on a single region (99.9% SLA)

```hcl

resource "google_compute_router" "interconnect-router" {
  name    = "interconnect-router"
  network = "mynet"
  project = "myproject"
  region  = "europe-west1"
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
  source       = "../cloud-foundation-fabric/modules/net-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west1"
  name         = "vlan-attachment-a"
  bandwidth    = "BPS_10G"
  bgp_cidr     = "169.254.0.0/30" 
  description  = "interconnect-a vlan attachment 0"
  interconnect = "interconnect-a"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = "interconnect-router"
  }
  vlan_tag              = 1001
}

module "example-va-b" {
  source       = "../cloud-foundation-fabric/modules/net-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west1"
  name         = "vlan-attachment-b"
  bandwidth    = "BPS_10G"
  bgp_cidr     = "169.254.0.4/30" 
  description  = "interconnect-b vlan attachment 0"
  interconnect = "interconnect-b"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = "interconnect-router"
  }
  vlan_tag              = 1002
}
```

### Four VLAN Attachments on two regions (99.99% SLA)

```hcl

resource "google_compute_router" "interconnect-router-ew1" {
  name    = "interconnect-router-ew1"
  network = "mynet"
  project = "myproject"
  region  = "europe-west1"
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

resource "google_compute_router" "interconnect-router-ew3" {
  name    = "interconnect-router-ew3"
  network = "mynet"
  project = "myproject"
  region  = "europe-west3"
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

module "example-va-a-ew1" {
  source       = "../cloud-foundation-fabric/modules/net-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west1"
  name         = "vlan-attachment-a-ew1"
  bandwidth    = "BPS_10G"
  bgp_cidr     = "169.254.0.0/30" 
  description  = "interconnect-a-ew1 vlan attachment 0"
  interconnect = "interconnect-a-ew1"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = "interconnect-router-ew1"
  }
  vlan_tag              = 1001
}

module "example-va-b-ew1" {
  source       = "../cloud-foundation-fabric/modules/net-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west1"
  name         = "vlan-attachment-b-ew1"
  bandwidth    = "BPS_10G"
  bgp_cidr     = "169.254.0.4/30" 
  description  = "interconnect-b-ew1 vlan attachment 0"
  interconnect = "interconnect-b-ew1"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = "interconnect-router-ew1"
  }
  vlan_tag              = 1002
}


module "example-va-a-ew3" {
  source       = "../cloud-foundation-fabric/modules/net-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west3"
  name         = "vlan-attachment-a-ew3"
  bandwidth    = "BPS_10G"
  bgp_cidr     = "169.254.1.0/30" 
  description  = "interconnect-a-ew3 vlan attachment 0"
  interconnect = "interconnect-a-ew3"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = "interconnect-router-ew3"
  }
  vlan_tag              = 1003
}

module "example-va-b-ew3" {
  source       = "../cloud-foundation-fabric/modules/net-vlan-attachment"
  network      = "mynet"
  project_id   = "myproject"
  region       = "europe-west3"
  name         = "vlan-attachment-b-ew3"
  bandwidth    = "BPS_10G"
  bgp_cidr     = "169.254.1.4/30" 
  description  = "interconnect-b-ew3 vlan attachment 0"
  interconnect = "interconnect-b-ew3"
  peer_asn     = "65000"
  router_config = {
    create = false
    name   = "interconnect-router-ew3"
  }
  vlan_tag              = 1004
}
```

### IPSec over Interconnect enabled setup

Refer to the [net-ipsec-over-interconnect](../net-ipsec-over-interconnect/) module docs.

<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [description](variables.tf#L42) | VLAN attachment description. | <code>string</code> | ✓ |  |
| [interconnect](variables.tf#L47) | The identifier of the interconnect the VLAN attachment binds to. | <code>string</code> | ✓ |  |
| [name](variables.tf#L58) | The common resources name, used after resource type prefix and suffix. | <code>string</code> | ✓ |  |
| [network](variables.tf#L63) | The VPC name to which resources are associated to. | <code>string</code> | ✓ |  |
| [peer_asn](variables.tf#L68) | The on-premises underlay router ASN. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L73) | The project id where resources are created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L78) | The region where resources are created. | <code>string</code> | ✓ |  |
| [router_config](variables.tf#L83) | Cloud Router configuration for the VPN. If you want to reuse an existing router, set create to false and use name to specify the desired router. | <code title="object&#40;&#123;&#10;  create    &#61; optional&#40;bool, true&#41;&#10;  asn       &#61; optional&#40;number&#41;&#10;  name      &#61; optional&#40;string&#41;&#10;  keepalive &#61; optional&#40;number&#41;&#10;  custom_advertise &#61; optional&#40;object&#40;&#123;&#10;    all_subnets &#61; bool&#10;    ip_ranges   &#61; map&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [vlan_tag](variables.tf#L98) | The VLAN id to be used for this VLAN attachment. | <code>number</code> | ✓ |  |
| [admin_enabled](variables.tf#L17) | Whether the VLAN attachment is enabled. | <code>bool</code> |  | <code>true</code> |
| [bandwidth](variables.tf#L29) | The bandwidth assigned to the VLAN attachment (e.g. BPS_10G). | <code>string</code> |  | <code>&#34;BPS_10G&#34;</code> |
| [bgp_cidr](variables.tf#L36) | The underlay link-local IP range (in CIDR notation). | <code>string</code> |  | <code>&#34;169.254.0.0&#47;30&#34;</code> |
| [ipsec_gateway_ip_ranges](variables.tf#L23) | IPSec Gateway IP Ranges. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [mtu](variables.tf#L52) | The MTU associated to the VLAN attachemnt (1440 / 1500). | <code>number</code> |  | <code>1500</code> |
| [vpn_gateways_ip_range](variables.tf#L103) | The IP range (cidr notation) to be used for the GCP VPN gateways. If null IPSec over Interconnect is not enabled. | <code>string</code> |  | <code>null</code> |

<!-- END TFDOC -->
