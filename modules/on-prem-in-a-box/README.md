# On-prem-in-a-box Module

This module allows emulating an on-premise enviroment in a single GCE VM, by connecting a Docker Network to a VPC via a static or dynamic (BGP) VPN connection implemented with Strongswan. It provides a good playground for testing private access and hybrid DNS connectivity between on-premise and Google Cloud.

To see this module in action, please refer to the folowing end-to-end network examples:
- [hub-and-spoke-peerings](../../infrastructure/hub-and-spoke-peerings/)

## TODO

- [ ] describe how to check and troubleshoot the onprem VPN and services
- [ ] add support for service account, scopes and network tags
- [ ] allow passing in arbitrary CoreDNS configurations instead of tweaking a default one via variables

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
| project_id | Project id. | <code title="">string</code> | ✓ |  |
| subnet_self_link | VPC subnet self link. | <code title="">string</code> | ✓ |  |
| vpn_config | VPN configuration, type must be one of 'dynamic' or 'static'. | <code title="object&#40;&#123;&#10;peer_ip       &#61; string&#10;shared_secret &#61; string&#10;type &#61; string&#10;&#125;&#41;">object({...})</code> | ✓ |  |
| zone | Compute zone. | <code title="">string</code> | ✓ |  |
| *coredns_config* | CoreDNS configuration, set to null to use default. | <code title="">string</code> |  | <code title="">null</code> |
| *dns_domain* | DNS domain used for on-prem host records. | <code title="">string</code> |  | <code title="">onprem.example.com</code> |
| *local_ip_cidr_range* | IP CIDR range used for the Docker onprem network. | <code title="">string</code> |  | <code title="">192.168.192.0/24</code> |
| *machine_type* | Machine type. | <code title="">string</code> |  | <code title="">g1-small</code> |
| *name* | On-prem-in-a-box compute instance name. | <code title="">string</code> |  | <code title="">onprem</code> |
| *network_tags* | Network tags. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["ssh"]</code> |
| *service_account* | Service account customization. | <code title="object&#40;&#123;&#10;email  &#61; string&#10;scopes &#61; list&#40;string&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;email &#61; null&#10;scopes &#61; &#91;&#10;&#34;https:&#47;&#47;www.googleapis.com&#47;auth&#47;devstorage.read_only&#34;,&#10;&#34;https:&#47;&#47;www.googleapis.com&#47;auth&#47;logging.write&#34;,&#10;&#34;https:&#47;&#47;www.googleapis.com&#47;auth&#47;monitoring.write&#34;&#10;&#93;&#10;&#125;">...</code> |
| *vpn_dynamic_config* | BGP configuration for dynamic VPN, ignored if VPN type is 'static'. | <code title="object&#40;&#123;&#10;local_bgp_asn     &#61; number&#10;local_bgp_address &#61; string&#10;peer_bgp_asn      &#61; number&#10;peer_bgp_address  &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;local_bgp_asn     &#61; 65002&#10;local_bgp_address &#61; &#34;169.254.0.2&#34;&#10;peer_bgp_asn      &#61; 65001&#10;peer_bgp_address  &#61; &#34;169.254.0.1&#34;&#10;&#125;">...</code> |
| *vpn_static_ranges* | Remote CIDR ranges for static VPN, ignored if VPN type is 'dynamic'. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| dns_ip_address | None |  |
| external_address | None |  |
| instance_name | None |  |
| internal_address | None |  |
| toolbox_ip_address | None |  |
| vpn_ip_address | None |  |
| web_ip_address | None |  |
<!-- END TFDOC -->
