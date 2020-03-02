# On-prem-in-a-box Module

This module allows emulating on-premise enviroment in a box (Compute VM) via connecting Docker Network to Cloud Network with `static` or `dynamic (bgp)`  VPN connection. It also provides a good playground for testing around Hybrid DNS connectivity between on-premise and Google Cloud Environment.

To see this module in action, please refer to the folowing end-to-end network examples:
- [shared-vpc](../../infrastructure/shared-vpc/)
- [hub-and-spoke-vpns](../../infrastructure/hub-and-spoke-vpns/)
- [hub-and-spoke-peerings](../../infrastructure/hub-and-spoke-peerings/)

## Examples

### Static VPN Gateway
```hcl
module "cloud-vpn" {
  source     = "modules/net-vpn-static/"
  project_id = "<PROJECT_ID>"
  region     = "europe-west4"
  network    = "vpn-network"
  name       = "cloud-net-to-on-prem"
  remote_ranges = ["192.168.192.0/24"]
  tunnels = {
    remote-0 = {
      ike_version       = 2
      peer_ip           = module.on-prem.external_address
      shared_secret     = ""
      traffic_selectors = { local = ["0.0.0.0/0"], remote = null }
    }
  }
}

module "on-prem" {
  source = "modules/on-prem-in-a-box/"

  name                    = "onprem-instance"
  project_id              = "<PROJECT_ID>"
  zone                    = "europe-west4-b"
  network                 = <NETWORK_NAME>
  subnet_self_link        = "https://www.googleapis.com/compute/v1/projects/<PROJECT_ID>/regions/europe-west4/subnetworks/<SUBNETWORK_NAME>"
  vpn_gateway_type        = "static"
  peer_ip                 = module.cloud-vpn.address
  local_ip_cidr_range     = "192.168.192.0/24"
  shared_secret           = module.cloud-vpn.random_secret
  remote_ip_cidr_ranges   = "172.16.0.0/24,172.16.1.0/24,172.16.2.0/24"
}
```

### Dynamic VPN Gateway
```hcl
module "cloud-vpn" {
  source     = "modules/net-vpn-dynamic/"
  project_id = "<PROJECT_ID>"
  region     = "europe-west4"
  network    = "vpn-network"
  name       = "cloud-net-to-on-prem"
  router_asn = 65001
  tunnels = {
    remote-1 = {
      bgp_peer = {
        address = "169.254.0.2"
        asn     = 65002
      }
      bgp_session_range = "169.254.0.1/30"
      ike_version       = 2
      peer_ip           = module.on-prem.external_address
      shared_secret     = null
      bgp_peer_options = {
        advertise_groups = ["ALL_SUBNETS"]
        advertise_ip_ranges = {
        }
        advertise_mode = "DEFAULT"
        route_priority = 1000
      }
    }
  }
}

module "on-prem" {
  source = "modules/on-prem-in-a-box/"

  name                    = "onprem-instance"
  project_id              = "<PROJECT_ID>"
  zone                    = "europe-west4-b"
  network                 = "<NETWORK_NAME>"
  subnet_self_link        = "https://www.googleapis.com/compute/v1/projects/<PROJECT_ID>/regions/europe-west4/subnetworks/<SUBNETWORK_NAME>"
  vpn_gateway_type        = "dynamic"
  peer_ip                 = module.cloud-vpn.address
  local_ip_cidr_range     = "192.168.192.0/24"
  shared_secret           = module.cloud-vpn.random_secret
  peer_bgp_session_range  = "169.254.0.1/30"
  local_bgp_session_range = "169.254.0.2/30"
  peer_bgp_asn            = 65001
  local_bgp_asn           = 65002
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| network | VPC network name. | <code title="">string</code> | ✓ |  |
| peer_ip | IP Address of Cloud VPN Gateway. | <code title="">string</code> | ✓ |  |
| project_id | Project id. | <code title="">string</code> | ✓ |  |
| shared_secret | None | <code title="">string</code> | ✓ |  |
| subnet_self_link | VPC subnet self link. | <code title="">string</code> | ✓ |  |
| vpn_gateway_type | VPN Gateway type, applicable values are `static` and `dynamic`. | <code title="">string</code> | ✓ |  |
| zone | Compute zone. | <code title="">string</code> | ✓ |  |
| *cloud_dns_forwarder_ip* | Inbound DNS Forwarding ip address. | <code title="">string</code> |  | <code title="">172.16.0.3</code> |
| *cloud_dns_zone* | Google Cloud DNS Private Zone Name. | <code title="">string</code> |  | <code title="">cloud.internal</code> |
| *local_bgp_asn* | Local BGP ASN. Should be provided if `vpn_gateway_type` is `dynamic`. | <code title="">string</code> |  | <code title="">65002</code> |
| *local_bgp_session_range* | Local BGP sesison range of the BGP interface. Should be provided if `vpn_gateway_type` is `dynamic`. | <code title="">string</code> |  | <code title="">169.254.0.2/30</code> |
| *local_ip_cidr_range* | None | <code title="">string</code> |  | <code title="">192.168.192.0/24</code> |
| *machine_type* | Machine type. | <code title="">string</code> |  | <code title="">g1-small</code> |
| *name* | On-prem-in-a-box compute instance name. | <code title="">string</code> |  | <code title="">on-prem-in-a-box</code> |
| *network_tags* | Network tags. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["ssh"]</code> |
| *on_prem_dns_zone* | On-premises DNS Private Zone Name. | <code title="">string</code> |  | <code title="">onprem.internal</code> |
| *peer_bgp_asn* | Peer BGP ASN. Should be provided if `vpn_gateway_type` is `dynamic`. | <code title="">string</code> |  | <code title="">65001</code> |
| *peer_bgp_session_range* | Peer BGP sesison range of the BGP interface. Should be provided if `vpn_gateway_type` is `dynamic`. | <code title="">string</code> |  | <code title="">169.254.0.1/30</code> |
| *remote_ip_cidr_ranges* | List of comma separated remote CIDR ranges. Should be provided if `vpn_gateway_type` is `static`. | <code title="">string</code> |  | <code title=""></code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| external_address | None |  |
| internal_address | None |  |
| name | None |  |
<!-- END TFDOC -->
