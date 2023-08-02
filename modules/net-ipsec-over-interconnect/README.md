# VLAN Attachment module

This module allows for the provisioning of [HA VPN over Interconnect](https://cloud.google.com/network-connectivity/docs/interconnect/concepts/ha-vpn-interconnect?hl=it). Specifically, this module creates a VPN gateway, a configurable number of tunnels, and all the resources required to established IPSec and BGP with the peer routers.

The required pair of encrypted VLAN Attachments can be created leveraging the [net-vlan-attachment](../net-vlan-attachment/) module, as shown in the [IoIC Blueprint](../../blueprints/networking/ha-vpn-over-interconnect/).

## Examples

### Single region setup

```hcl
resource "google_compute_router" "encrypted-interconnect-overlay-router" {
  name    = "encrypted-interconnect-overlay-router"
  project = "myproject"
  network = "mynet"
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

resource "google_compute_external_vpn_gateway" "default" {
  name        = "peer-vpn-gateway"
  project     = "myproject"
  description = "Peer IPSec over Interconnect VPN gateway"
  interface {
    id         = 0
    ip_address = "10.0.0.1"
  }
  interface {
    id         = 1
    ip_address = "10.0.0.2"
  }
}

module "vpngw-a" {
  source     = "./fabric/modules/net-ipsec-over-interconnect"
  project_id = "myproject"
  network    = "mynet"
  region     = "europe-west8"
  name       = "vpngw-a"
  interconnect_attachments = {
    a = "attach-01"
    b = "attach-02"
  }
  peer_gateway_config = {
    create = false
    id     = google_compute_external_vpn_gateway.default.id
  }
  router_config = {
    create = false
    name   = google_compute_router.encrypted-interconnect-overlay-router.name
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.1/30"
      shared_secret         = "foobar"
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.1.6"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.5/30"
      shared_secret         = "foobar"
      vpn_gateway_interface = 1
    }
    remote-2 = {
      bgp_peer = {
        address = "169.254.1.10"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.9/30"
      shared_secret         = "foobar"
      vpn_gateway_interface = 0
    }
    remote-3 = {
      bgp_peer = {
        address = "169.254.1.14"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.13/30"
      shared_secret         = "foobar"
      vpn_gateway_interface = 1
    }
  }
}
# tftest modules=1 resources=16
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [interconnect_attachments](variables.tf#L17) | VLAN attachments used by the VPN Gateway. | <code title="object&#40;&#123;&#10;  a &#61; string&#10;  b &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L25) | Common name to identify the VPN Gateway. | <code>string</code> | ✓ |  |
| [network](variables.tf#L30) | The VPC name to which resources are associated to. | <code>string</code> | ✓ |  |
| [peer_gateway_config](variables.tf#L35) | IP addresses for the external peer gateway. | <code title="object&#40;&#123;&#10;  create      &#61; optional&#40;bool, false&#41;&#10;  description &#61; optional&#40;string, &#34;Terraform managed IPSec over Interconnect VPN gateway&#34;&#41;&#10;  name        &#61; optional&#40;string, null&#41;&#10;  id          &#61; optional&#40;string, null&#41;&#10;  interfaces  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L54) | The project id. | <code>string</code> | ✓ |  |
| [region](variables.tf#L59) | GCP Region. | <code>string</code> | ✓ |  |
| [router_config](variables.tf#L64) | Cloud Router configuration for the VPN. If you want to reuse an existing router, set create to false and use name to specify the desired router. | <code title="object&#40;&#123;&#10;  create    &#61; optional&#40;bool, true&#41;&#10;  asn       &#61; optional&#40;number&#41;&#10;  name      &#61; optional&#40;string&#41;&#10;  keepalive &#61; optional&#40;number&#41;&#10;  custom_advertise &#61; optional&#40;object&#40;&#123;&#10;    all_subnets &#61; bool&#10;    ip_ranges   &#61; map&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [tunnels](variables.tf#L79) | VPN tunnel configurations. | <code title="map&#40;object&#40;&#123;&#10;  bgp_peer &#61; object&#40;&#123;&#10;    address        &#61; string&#10;    asn            &#61; number&#10;    route_priority &#61; optional&#40;number, 1000&#41;&#10;    custom_advertise &#61; optional&#40;object&#40;&#123;&#10;      all_subnets          &#61; bool&#10;      all_vpc_subnets      &#61; bool&#10;      all_peer_vpc_subnets &#61; bool&#10;      ip_ranges            &#61; map&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#10;  bgp_session_range               &#61; string&#10;  ike_version                     &#61; optional&#40;number, 2&#41;&#10;  peer_external_gateway_interface &#61; optional&#40;number&#41;&#10;  peer_gateway_id                 &#61; optional&#40;string, &#34;default&#34;&#41;&#10;  router                          &#61; optional&#40;string&#41;&#10;  shared_secret                   &#61; optional&#40;string&#41;&#10;  vpn_gateway_interface           &#61; number&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [bgp_peers](outputs.tf#L18) | BGP peer resources. |  |
| [external_gateway](outputs.tf#L25) | External VPN gateway resource. |  |
| [id](outputs.tf#L30) | Fully qualified VPN gateway id. |  |
| [random_secret](outputs.tf#L35) | Generated secret. |  |
| [router](outputs.tf#L40) | Router resource (only if auto-created). |  |
| [router_name](outputs.tf#L45) | Router name. |  |
| [self_link](outputs.tf#L50) | HA VPN gateway self link. |  |
| [tunnels](outputs.tf#L55) | VPN tunnel resources. |  |
<!-- END TFDOC -->
