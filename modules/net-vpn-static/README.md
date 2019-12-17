# Cloud VPN Route-based Module

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| name | VPN gateway name, and prefix used for dependent resources. | `string` | ✓
| network | VPC used for the gateway and routes. | `string` | ✓
| project_id | Project where resources will be created. | `string` | ✓
| region | Region used for resources. | `string` | ✓
| *create_address* | Create gateway address resource instead of using external one, defaults to true. | `bool` | 
| *gateway_address* | Optional address assigned to the VPN, used if create_address is false. | `string` | 
| *remote_ranges* | Remote IP CIDR ranges. | `list(string)` | 
| *route_priority* | Route priority, defaults to 1000. | `number` | 
| *tunnels* | VPN tunnel configurations. | `map(object({...}))` | 

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
