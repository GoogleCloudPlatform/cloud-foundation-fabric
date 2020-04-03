# Cloud VPN Dynamic Module

## Example

This example shows how to configure a single VPN tunnel using a couple of extra features

-  custom advertisement on the tunnel's BGP session; if custom advertisement is not needed, simply set the `bgp_peer_options` attribute to `null`
- internally generated shared secret, which can be fetched from the module's `random_secret` output for reuse; a predefined secret can be used instead by assigning it to the `shared_secret` attribute

```hcl
module "vpn-dynamic" {
  source          = "./modules/net-vpn-dynamic"
  project_id      = "my-project"
  region          = "europe-west1"
  network         = "my-vpc"
  name            = "gateway-1"
  tunnels = {
    remote-1 = {
      bgp_peer = {
        address = "169.254.139.134"
        asn     = 64513
      }
      bgp_session_range = "169.254.139.133/30"
      ike_version       = 2
      peer_ip           = var.remote_vpn_gateway.address
      shared_secret     = null
      bgp_peer_options = {
        advertise_groups = ["ALL_SUBNETS"]
        advertise_ip_ranges = {
          "192.168.0.0/24" = "Advertised range description"
        }
        advertise_mode = "CUSTOM"
        route_priority = 1000
      }
    }
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| name | VPN gateway name, and prefix used for dependent resources. | <code title="">string</code> | ✓ |  |
| network | VPC used for the gateway and routes. | <code title="">string</code> | ✓ |  |
| project_id | Project where resources will be created. | <code title="">string</code> | ✓ |  |
| region | Region used for resources. | <code title="">string</code> | ✓ |  |
| *gateway_address* | Optional address assigned to the VPN gateway. Ignored unless gateway_address_create is set to false. | <code title="">string</code> |  | <code title=""></code> |
| *gateway_address_create* | Create external address assigned to the VPN gateway. Needs to be explicitly set to false to use address in gateway_address variable. | <code title="">bool</code> |  | <code title="">true</code> |
| *route_priority* | Route priority, defaults to 1000. | <code title="">number</code> |  | <code title="">1000</code> |
| *router_advertise_config* | Router custom advertisement configuration, ip_ranges is a map of address ranges and descriptions. | <code title="object&#40;&#123;&#10;groups    &#61; list&#40;string&#41;&#10;ip_ranges &#61; map&#40;string&#41;&#10;mode      &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *router_asn* | Router ASN used for auto-created router. | <code title="">number</code> |  | <code title="">64514</code> |
| *router_create* | Create router. | <code title="">bool</code> |  | <code title="">true</code> |
| *router_name* | Router name used for auto created router, or to specify existing router to use. Leave blank to use VPN name for auto created router. | <code title="">string</code> |  | <code title=""></code> |
| *tunnels* | VPN tunnel configurations, bgp_peer_options is usually null. | <code title="map&#40;object&#40;&#123;&#10;bgp_peer &#61; object&#40;&#123;&#10;address &#61; string&#10;asn     &#61; number&#10;&#125;&#41;&#10;bgp_peer_options &#61; object&#40;&#123;&#10;advertise_groups    &#61; list&#40;string&#41;&#10;advertise_ip_ranges &#61; map&#40;string&#41;&#10;advertise_mode      &#61; string&#10;route_priority      &#61; number&#10;&#125;&#41;&#10;bgp_session_range &#61; string&#10;ike_version       &#61; number&#10;peer_ip           &#61; string&#10;shared_secret     &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| address | VPN gateway address. |  |
| gateway | VPN gateway resource. |  |
| name | VPN gateway name. |  |
| random_secret | Generated secret. | ✓ |
| router | Router resource (only if auto-created). |  |
| router_name | Router name. |  |
| self_link | VPN gateway self link. |  |
| tunnel_names | VPN tunnel names. |  |
| tunnel_self_links | VPN tunnel self links. |  |
| tunnels | VPN tunnel resources. |  |
<!-- END TFDOC -->
