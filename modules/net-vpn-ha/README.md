# Cloud VPN HA Module
This module makes it easy to deploy either GCP-to-GCP or GCP-to-On-prem [Cloud HA VPN](https://cloud.google.com/vpn/docs/concepts/overview#ha-vpn).

## Examples

### GCP to GCP
```hcl
module "vpn_ha-1" {
  source           = "./modules/net-vpn-ha"
  project_id       = "<PROJECT_ID>"
  region           = "europe-west4"
  network          = "https://www.googleapis.com/compute/v1/projects/<PROJECT_ID>/global/networks/network-1"
  name             = "net1-to-net-2"
  peer_gcp_gateway = module.vpn_ha-2.self_link
  router_asn       = 64514
  router_advertise_config = {
    groups = ["ALL_SUBNETS"]
    ip_ranges = {
      "10.0.0.0/8" = "default"
    }
    mode = "CUSTOM"
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.1.2/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = ""
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.2/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = ""
      vpn_gateway_interface           = 1
    }
  }
}

module "vpn_ha-2" {
  source           = "./modules/net-vpn-ha"
  project_id       = "<PROJECT_ID>"
  region           = "europe-west4"
  network          = "https://www.googleapis.com/compute/v1/projects/<PROJECT_ID>/global/networks/local-network"
  name             = "net2-to-net1"
  router_asn       = 64513
  peer_gcp_gateway = module.vpn_ha-1.self_link
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.1.1/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = module.vpn_ha-1.random_secret
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.1/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = module.vpn_ha-1.random_secret
      vpn_gateway_interface           = 1
    }
  }
}
# tftest:modules=2:resources=18
```

### GCP to on-prem

```hcl
module "vpn_ha" {
  source     = "./modules/net-vpn-ha"
  project_id = var.project_id
  region     = var.region
  network    = var.vpc.self_link
  name       = "mynet-to-onprem"
  peer_external_gateway = {
    redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
    interfaces = [{
      id         = 0
      ip_address = "8.8.8.8" # on-prem router ip address
    }]
  }
  router_asn = 64514
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.1.2/30"
      ike_version                     = 2
      peer_external_gateway_interface = 0
      router                          = null
      shared_secret                   = "mySecret"
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.2/30"
      ike_version                     = 2
      peer_external_gateway_interface = 0
      router                          = null
      shared_secret                   = "mySecret"
      vpn_gateway_interface           = 1
    }
  }
}
# tftest:modules=1:resources=10
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| name | VPN Gateway name (if an existing VPN Gateway is not used), and prefix used for dependent resources. | <code title="">string</code> | ✓ |  |
| network | VPC used for the gateway and routes. | <code title="">string</code> | ✓ |  |
| project_id | Project where resources will be created. | <code title="">string</code> | ✓ |  |
| region | Region used for resources. | <code title="">string</code> | ✓ |  |
| *peer_external_gateway* | Configuration of an external VPN gateway to which this VPN is connected. | <code title="object&#40;&#123;&#10;redundancy_type &#61; string&#10;interfaces &#61; list&#40;object&#40;&#123;&#10;id         &#61; number&#10;ip_address &#61; string&#10;&#125;&#41;&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *peer_gcp_gateway* | Self Link URL of the peer side HA GCP VPN gateway to which this VPN tunnel is connected. | <code title="">string</code> |  | <code title="">null</code> |
| *route_priority* | Route priority, defaults to 1000. | <code title="">number</code> |  | <code title="">1000</code> |
| *router_advertise_config* | Router custom advertisement configuration, ip_ranges is a map of address ranges and descriptions. | <code title="object&#40;&#123;&#10;groups    &#61; list&#40;string&#41;&#10;ip_ranges &#61; map&#40;string&#41;&#10;mode      &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *router_asn* | Router ASN used for auto-created router. | <code title="">number</code> |  | <code title="">64514</code> |
| *router_create* | Create router. | <code title="">bool</code> |  | <code title="">true</code> |
| *router_name* | Router name used for auto created router, or to specify an existing router to use if `router_create` is set to `true`. Leave blank to use VPN name for auto created router. | <code title="">string</code> |  | <code title=""></code> |
| *tunnels* | VPN tunnel configurations, bgp_peer_options is usually null. | <code title="map&#40;object&#40;&#123;&#10;bgp_peer &#61; object&#40;&#123;&#10;address &#61; string&#10;asn     &#61; number&#10;&#125;&#41;&#10;bgp_peer_options &#61; object&#40;&#123;&#10;advertise_groups    &#61; list&#40;string&#41;&#10;advertise_ip_ranges &#61; map&#40;string&#41;&#10;advertise_mode      &#61; string&#10;route_priority      &#61; number&#10;&#125;&#41;&#10;bgp_session_range               &#61; string&#10;ike_version                     &#61; number&#10;peer_external_gateway_interface &#61; number&#10;router                          &#61; string&#10;shared_secret                   &#61; string&#10;vpn_gateway_interface           &#61; number&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *vpn_gateway* | HA VPN Gateway Self Link for using an existing HA VPN Gateway, leave empty if `vpn_gateway_create` is set to `true`. | <code title="">string</code> |  | <code title="">null</code> |
| *vpn_gateway_create* | Create HA VPN Gateway. | <code title="">bool</code> |  | <code title="">true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| bgp_peers | BGP peer resources. |  |
| external_gateway | External VPN gateway resource. |  |
| gateway | VPN gateway resource (only if auto-created). |  |
| name | VPN gateway name (only if auto-created).  |  |
| random_secret | Generated secret. |  |
| router | Router resource (only if auto-created). |  |
| router_name | Router name. |  |
| self_link | HA VPN gateway self link. |  |
| tunnel_names | VPN tunnel names. |  |
| tunnel_self_links | VPN tunnel self links. |  |
| tunnels | VPN tunnel resources. |  |
<!-- END TFDOC -->
