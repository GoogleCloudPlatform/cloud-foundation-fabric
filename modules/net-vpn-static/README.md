# Cloud VPN Route-based Module

## Example

```hcl
module "vpn" {
  source          = "./modules/net-vpn-static"
  project_id      = var.project_id
  region          = var.region
  network         = var.network
  name            = "remote"
  # gateway_address = var.gateway_address
  remote_ranges   = [var.remote_ranges]
  tunnels = {
    remote-0 = {
      ike_version       = 2
      peer_ip           = var.remote_vpn_gateway_address
      shared_secret     = ""
      traffic_selectors = { local = ["0.0.0.0/0"], remote = null }
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
| *remote_ranges* | Remote IP CIDR ranges. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *route_priority* | Route priority, defaults to 1000. | <code title="">number</code> |  | <code title="">1000</code> |
| *tunnels* | VPN tunnel configurations. | <code title="map&#40;object&#40;&#123;&#10;ike_version   &#61; number&#10;peer_ip       &#61; string&#10;shared_secret &#61; string&#10;traffic_selectors &#61; object&#40;&#123;&#10;local  &#61; list&#40;string&#41;&#10;remote &#61; list&#40;string&#41;&#10;&#125;&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| address | VPN gateway address. |  |
| gateway | VPN gateway resource. |  |
| name | VPN gateway name. |  |
| random_secret | Generated secret. | ✓ |
| self_link | VPN gateway self link. |  |
| tunnel_names | VPN tunnel names. |  |
| tunnel_self_links | VPN tunnel self links. |  |
| tunnels | VPN tunnel resources. |  |
<!-- END TFDOC -->
