# Cloud HA VPN Module

This module makes it easy to deploy either GCP-to-GCP or GCP-to-On-prem [Cloud HA VPN](https://cloud.google.com/network-connectivity/docs/vpn/concepts/overview#ha-vpn).

## Examples

### GCP to GCP

```hcl
module "vpn-1" {
  source     = "./fabric/modules/net-vpn-ha"
  project_id = var.project_id
  region     = "europe-west4"
  network    = var.vpc1.self_link
  name       = "net1-to-net-2"
  peer_gateways = {
    default = { gcp = module.vpn-2.self_link }
  }
  router_config = {
    asn = 64514
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        "10.0.0.0/8" = "default"
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.1.2/30"
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.2.2/30"
      vpn_gateway_interface = 1
    }
  }
}

module "vpn-2" {
  source        = "./fabric/modules/net-vpn-ha"
  project_id    = var.project_id
  region        = "europe-west4"
  network       = var.vpc2.self_link
  name          = "net2-to-net1"
  router_config = { asn = 64513 }
  peer_gateways = {
    default = { gcp = module.vpn-1.self_link }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.1/30"
      shared_secret         = module.vpn-1.shared_secrets["remote-0"]
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.2.1/30"
      shared_secret         = module.vpn-1.shared_secrets["remote-1"]
      vpn_gateway_interface = 1
    }
  }
}
# tftest modules=2 resources=22 inventory=gcp-to-gcp.yaml
```

Note: When using the `for_each` meta-argument you might experience a Cycle Error due to the multiple `net-vpn-ha` modules referencing each other. To fix this you can create the [google_compute_ha_vpn_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ha_vpn_gateway) resources separately and reference them in the `net-vpn-ha` module via the `vpn_gateway` and `peer_gcp_gateway` variables.

### GCP to on-prem

```hcl
module "vpn_ha" {
  source     = "./fabric/modules/net-vpn-ha"
  project_id = var.project_id
  region     = var.region
  network    = var.vpc.self_link
  name       = "mynet-to-onprem"
  peer_gateways = {
    default = {
      external = {
        redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
        interfaces      = ["8.8.8.8"] # on-prem router ip address
      }
    }
  }
  router_config = { asn = 64514 }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
        # BFD is optional
        bfd = {
          min_receive_interval        = 1000
          min_transmit_interval       = 1000
          multiplier                  = 5
          session_initialization_mode = "ACTIVE"
        }
        # MD5 Authentication is optional
        md5_authentication_key = {
          name = "foo"
          key  = "bar"
        }
      }
      bgp_session_range               = "169.254.1.2/30"
      peer_external_gateway_interface = 0
      shared_secret                   = "mySecret"
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
        # BFD is optional
        bfd = {
          min_receive_interval        = 1000
          min_transmit_interval       = 1000
          multiplier                  = 5
          session_initialization_mode = "ACTIVE"
        }
        # MD5 Authentication is optional
        md5_authentication_key = {
          name = "foo"
          key  = "bar"
        }
      }
      bgp_session_range               = "169.254.2.2/30"
      peer_external_gateway_interface = 0
      shared_secret                   = "mySecret"
      vpn_gateway_interface           = 1
    }
  }
}
# tftest modules=1 resources=12 inventory=gcp-to-onprem.yaml
```

### IPv6 (dual-stack)

You can optionally set your HA VPN gateway (and BGP sessions) to carry both IPv4 and IPv6 traffic. IPv6 only is not supported.

```hcl
module "vpn_ha" {
  source     = "./fabric/modules/net-vpn-ha"
  project_id = var.project_id
  region     = var.region
  name       = "mynet-to-onprem"
  network    = var.vpc.self_link
  peer_gateways = {
    default = {
      external = {
        redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
        interfaces      = ["8.8.8.8"] # on-prem router ip address
      }
    }
  }
  router_config = { asn = 64514 }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
        ipv6    = {}
      }
      bgp_session_range               = "169.254.1.2/30"
      peer_external_gateway_interface = 0
      shared_secret                   = "mySecret"
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
        ipv6 = {
          nexthop_address      = "2600:2d00:0:2::1"
          peer_nexthop_address = "2600:2d00:0:3::1"
        }
      }
      bgp_session_range               = "169.254.2.2/30"
      peer_external_gateway_interface = 0
      shared_secret                   = "mySecret"
      vpn_gateway_interface           = 1
    }
  }
  vpn_gateway_create = {
    stack_type = "IPV4_IPV6"
  }
}
# tftest modules=1 resources=12 intentory=ipv6.yaml
```

You can optionally avoid to specify MD5 keys and the module will automatically generate them for you.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L17) | VPN Gateway name (if an existing VPN Gateway is not used), and prefix used for dependent resources. | <code>string</code> | ✓ |  |
| [network](variables.tf#L22) | VPC used for the gateway and routes. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L48) | Project where resources will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L53) | Region used for resources. | <code>string</code> | ✓ |  |
| [router_config](variables.tf#L58) | Cloud Router configuration for the VPN. If you want to reuse an existing router, set create to false and use name to specify the desired router. | <code title="object&#40;&#123;&#10;  asn    &#61; optional&#40;number&#41;&#10;  create &#61; optional&#40;bool, true&#41;&#10;  custom_advertise &#61; optional&#40;object&#40;&#123;&#10;    all_subnets &#61; bool&#10;    ip_ranges   &#61; map&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  keepalive     &#61; optional&#40;number&#41;&#10;  name          &#61; optional&#40;string&#41;&#10;  override_name &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [peer_gateways](variables.tf#L27) | Configuration of the (external or GCP) peer gateway. | <code title="map&#40;object&#40;&#123;&#10;  external &#61; optional&#40;object&#40;&#123;&#10;    redundancy_type &#61; string&#10;    interfaces      &#61; list&#40;string&#41;&#10;    description     &#61; optional&#40;string, &#34;Terraform managed external VPN gateway&#34;&#41;&#10;    name            &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  gcp &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [tunnels](variables.tf#L74) | VPN tunnel configurations. | <code title="map&#40;object&#40;&#123;&#10;  bgp_peer &#61; object&#40;&#123;&#10;    address        &#61; string&#10;    asn            &#61; number&#10;    route_priority &#61; optional&#40;number, 1000&#41;&#10;    custom_advertise &#61; optional&#40;object&#40;&#123;&#10;      all_subnets &#61; bool&#10;      ip_ranges   &#61; map&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    md5_authentication_key &#61; optional&#40;object&#40;&#123;&#10;      name &#61; string&#10;      key  &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    ipv6 &#61; optional&#40;object&#40;&#123;&#10;      nexthop_address      &#61; optional&#40;string&#41;&#10;      peer_nexthop_address &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    name &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#10;  bgp_session_range               &#61; string&#10;  ike_version                     &#61; optional&#40;number, 2&#41;&#10;  name                            &#61; optional&#40;string&#41;&#10;  peer_external_gateway_interface &#61; optional&#40;number&#41;&#10;  peer_router_interface_name      &#61; optional&#40;string&#41;&#10;  peer_gateway                    &#61; optional&#40;string, &#34;default&#34;&#41;&#10;  router                          &#61; optional&#40;string&#41;&#10;  shared_secret                   &#61; optional&#40;string&#41;&#10;  vpn_gateway_interface           &#61; number&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [vpn_gateway](variables.tf#L111) | HA VPN Gateway Self Link for using an existing HA VPN Gateway. Ignored if `vpn_gateway_create` is set to `true`. | <code>string</code> |  | <code>null</code> |
| [vpn_gateway_create](variables.tf#L117) | Create HA VPN Gateway. Set to null to avoid creation. | <code title="object&#40;&#123;&#10;  description &#61; optional&#40;string, &#34;Terraform managed external VPN gateway&#34;&#41;&#10;  ipv6        &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [bgp_peers](outputs.tf#L18) | BGP peer resources. |  |
| [external_gateway](outputs.tf#L25) | External VPN gateway resource. |  |
| [gateway](outputs.tf#L30) | VPN gateway resource (only if auto-created). |  |
| [id](outputs.tf#L35) | Fully qualified VPN gateway id. |  |
| [md5_keys](outputs.tf#L42) | BGP tunnels MD5 keys. |  |
| [name](outputs.tf#L53) | VPN gateway name (only if auto-created). |  |
| [random_secret](outputs.tf#L58) | Generated secret. |  |
| [router](outputs.tf#L63) | Router resource (only if auto-created). |  |
| [router_name](outputs.tf#L68) | Router name. |  |
| [self_link](outputs.tf#L73) | HA VPN gateway self link. |  |
| [shared_secrets](outputs.tf#L78) | IPSEC tunnels shared secrets. |  |
| [tunnel_names](outputs.tf#L86) | VPN tunnel names. |  |
| [tunnel_self_links](outputs.tf#L94) | VPN tunnel self links. |  |
| [tunnels](outputs.tf#L102) | VPN tunnel resources. |  |
<!-- END TFDOC -->
