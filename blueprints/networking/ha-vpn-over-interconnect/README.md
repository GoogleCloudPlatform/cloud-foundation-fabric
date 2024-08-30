# HA VPN over Interconnect

This blueprint creates a complete HA VPN over Interconnect setup, which leverages IPSec to encrypt all traffic transiting through purposely-created VLAN Attachments.

This blueprint supports Dedicated Interconnect and Partner Interconnect.

In case of Partner Interconnect only partial apply is possible at first, which creates the VLAN Attachments. Only once the partner connection is established it is possible to deploy HA VPN Gateway and all dependant resources. 

## Managed resources and services

This blueprint creates two distinct sets of resources:

- Underlay
  - A Cloud Router dedicated to the underlay networking, which exchanges and routes the VPN gateways ranges
  - Two VLAN Attachments, each created from a distinct Dedicated Interconnect connected to two different EADs in the same Metro
- Overlay
  - A Cloud Router dedicated to the overlay networking, which exchanges and routes the overlay traffic (i.e. traffic from/to onprem)
  - VPN gateways and tunnels according to the provided configuration.

## Prerequisites

A single pre-existing project and a VPC is used in this blueprint to keep variables and complexity to a minimum.

The provided project needs a valid billing account and the Compute APIs enabled.

The two Dedicated Interconnect connections should already exist, either in the same project or in any other project belonging to the same GCP Organization.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [network](variables.tf#L18) | The VPC name to which resources are associated to. | <code>string</code> | ✓ |  |
| [overlay_config](variables.tf#L24) | Configuration for the overlay resources. | <code title="object&#40;&#123;&#10;  gcp_bgp &#61; object&#40;&#123;&#10;    asn       &#61; number&#10;    name      &#61; optional&#40;string&#41;&#10;    keepalive &#61; optional&#40;number&#41;&#10;    custom_advertise &#61; optional&#40;object&#40;&#123;&#10;      all_subnets &#61; bool&#10;      ip_ranges   &#61; map&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#10;  onprem_vpn_gateway_interfaces &#61; list&#40;string&#41;&#10;  gateways &#61; map&#40;map&#40;object&#40;&#123;&#10;    bgp_peer &#61; object&#40;&#123;&#10;      address        &#61; string&#10;      asn            &#61; number&#10;      route_priority &#61; optional&#40;number, 1000&#41;&#10;      custom_advertise &#61; optional&#40;object&#40;&#123;&#10;        all_subnets          &#61; bool&#10;        all_vpc_subnets      &#61; bool&#10;        all_peer_vpc_subnets &#61; bool&#10;        ip_ranges            &#61; map&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#10;    bgp_session_range               &#61; string&#10;    ike_version                     &#61; optional&#40;number, 2&#41;&#10;    peer_external_gateway_interface &#61; optional&#40;number&#41;&#10;    peer_gateway                    &#61; optional&#40;string, &#34;default&#34;&#41;&#10;    router                          &#61; optional&#40;string&#41;&#10;    shared_secret                   &#61; optional&#40;string&#41;&#10;    vpn_gateway_interface           &#61; number&#10;    &#125;&#41;&#41;&#10;  &#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L63) | The project id. | <code>string</code> | ✓ |  |
| [region](variables.tf#L68) | GCP Region. | <code>string</code> | ✓ |  |
| [underlay_config](variables.tf#L73) | Configuration for the underlay resources. | <code title="object&#40;&#123;&#10;  attachments &#61; map&#40;object&#40;&#123;&#10;    bandwidth              &#61; optional&#40;string, &#34;BPS_10G&#34;&#41;&#10;    base_name              &#61; optional&#40;string, &#34;encrypted-vlan-attachment&#34;&#41;&#10;    bgp_range              &#61; string&#10;    interconnect_self_link &#61; string&#10;    onprem_asn             &#61; number&#10;    vlan_tag               &#61; number&#10;    vpn_gateways_ip_range  &#61; string&#10;  &#125;&#41;&#41;&#10;  gcp_bgp &#61; object&#40;&#123;&#10;    asn &#61; number&#10;  &#125;&#41;&#10;  interconnect_type &#61; optional&#40;string, &#34;DEDICATED&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [underlay](outputs.tf#L17) | Setup for the underlay connection. |  |
<!-- END TFDOC -->
## Test

```hcl
module "test" {
  source     = "./fabric/blueprints/networking/ha-vpn-over-interconnect"
  network    = "mynet"
  project_id = "myproject"
  region     = "europe-west8"

  overlay_config = {
    gcp_bgp = {
      asn = 65102
      custom_advertise = {
        all_subnets = true
        ip_ranges = {
          "10.0.0.0/8" = "default"
        }
      }
    }
    onprem_vpn_gateway_interfaces = ["172.16.0.1", "172.16.0.2"]
    gateways = {
      a = {
        remote-0 = {
          bgp_peer = {
            address = "169.254.1.2"
            asn     = 64514
          }
          bgp_session_range               = "169.254.1.1/30"
          peer_external_gateway_interface = 0
          shared_secret                   = "foobar"
          vpn_gateway_interface           = 0
        }
        remote-1 = {
          bgp_peer = {
            address = "169.254.1.6"
            asn     = 64514
          }
          bgp_session_range               = "169.254.1.5/30"
          peer_external_gateway_interface = 0
          shared_secret                   = "foobar"
          vpn_gateway_interface           = 1
        }
        remote-2 = {
          bgp_peer = {
            address = "169.254.1.10"
            asn     = 64514
          }
          bgp_session_range               = "169.254.1.9/30"
          peer_external_gateway_interface = 1
          shared_secret                   = "foobar"
          vpn_gateway_interface           = 0
        }
        remote-3 = {
          bgp_peer = {
            address = "169.254.1.14"
            asn     = 64514
          }
          bgp_session_range               = "169.254.1.13/30"
          peer_external_gateway_interface = 1
          shared_secret                   = "foobar"
          vpn_gateway_interface           = 1
        }
      }
      b = {
        remote-0 = {
          bgp_peer = {
            address = "169.254.2.2"
            asn     = 64514
          }
          bgp_session_range               = "169.254.2.1/30"
          peer_external_gateway_interface = 0
          shared_secret                   = "foobar"
          vpn_gateway_interface           = 0
        }
        remote-1 = {
          bgp_peer = {
            address = "169.254.2.6"
            asn     = 64514
          }
          bgp_session_range               = "169.254.2.5/30"
          peer_external_gateway_interface = 0
          shared_secret                   = "foobar"
          vpn_gateway_interface           = 1
        }
        remote-2 = {
          bgp_peer = {
            address = "169.254.2.10"
            asn     = 64514
          }
          bgp_session_range               = "169.254.2.9/30"
          peer_external_gateway_interface = 1
          shared_secret                   = "foobar"
          vpn_gateway_interface           = 0
        }
        remote-3 = {
          bgp_peer = {
            address = "169.254.2.14"
            asn     = 64514
          }
          bgp_session_range               = "169.254.2.13/30"
          peer_external_gateway_interface = 1
          shared_secret                   = "foobar"
          vpn_gateway_interface           = 1
        }
      }
    }
  }

  underlay_config = {
    attachments = {
      "a" = {
        bgp_range              = "169.254.255.0/29"
        interconnect_self_link = "https://www.googleapis.com/compute/v1/projects/myproject/global/interconnects/interconnect-zone1"
        onprem_asn             = 65001
        vlan_tag               = 1001
        vpn_gateways_ip_range  = "10.255.255.0/29"
      }
      "b" = {
        bgp_range              = "169.254.255.8/29"
        interconnect_self_link = "https://www.googleapis.com/compute/v1/projects/myproject/global/interconnects/interconnect-zone2"
        onprem_asn             = 65001
        vlan_tag               = 1002
        vpn_gateways_ip_range  = "10.255.255.8/29"
      }
    }
    gcp_bgp = {
      asn = 65002
    }
  }
}
# tftest modules=5 resources=39
```
