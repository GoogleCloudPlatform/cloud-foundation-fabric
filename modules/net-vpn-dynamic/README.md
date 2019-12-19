# Cloud VPN Dynamic Module

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| name | VPN gateway name, and prefix used for dependent resources. | `string` | ✓
| network | VPC used for the gateway and routes. | `string` | ✓
| project_id | Project where resources will be created. | `string` | ✓
| region | Region used for resources. | `string` | ✓
| *create_address* | Create gateway address resource instead of using external one, defaults to true. | `bool` | 
| *create_router* | Create router for Cloud NAT instead of using existing one. | `bool` | 
| *gateway_address* | Optional address assigned to the VPN, used if create_address is false. | `string` | 
| *route_priority* | Route priority, defaults to 1000. | `number` | 
| *router_advertise_config* | Router custom advertisement configuration, ip_ranges is a map of range as key and description as value. | `object({...})` | 
| *router_asn* | Router ASN used for auto-created router. | `number` | 
| *router_name* | Name of the existing or auto-created router. | `string` | 
| *tunnels* | VPN tunnel configurations. | `map(object({...}))` | 

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
