# Cloud VPN Route-based Module

This module makes it easy to deploy a [Classic VPN](https://docs.cloud.google.com/network-connectivity/docs/vpn/concepts/overview#classic-vpn) with static routing.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Classic VPN with single tunnel](#classic-vpn-with-single-tunnel)
  - [Classic VPN with single tunnel and custom ciphers](#classic-vpn-with-single-tunnel-and-custom-ciphers)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Examples

### Classic VPN with single tunnel

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  external_addresses = {
    vpn = { region = "europe-west1" }
  }
}

module "vpn" {
  source                 = "./fabric/modules/net-vpn-static"
  project_id             = var.project_id
  region                 = var.region
  network                = var.vpc.self_link
  name                   = "remote"
  gateway_address_create = false
  gateway_address        = module.addresses.external_addresses["vpn"].address
  remote_ranges          = ["10.10.0.0/24"]
  tunnels = {
    remote-0 = {
      peer_ip           = "1.1.1.1"
      shared_secret     = "mysecret"
      traffic_selectors = { local = ["0.0.0.0/0"], remote = ["0.0.0.0/0"] }
    }
  }
}
# tftest modules=2 resources=8 inventory=vpn-single-tunnel.yaml
```

### Classic VPN with single tunnel and custom ciphers

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  external_addresses = {
    vpn = { region = "europe-west1" }
  }
}

module "vpn" {
  source                 = "./fabric/modules/net-vpn-static"
  project_id             = var.project_id
  region                 = var.region
  network                = var.vpc.self_link
  name                   = "remote"
  gateway_address_create = false
  gateway_address        = module.addresses.external_addresses["vpn"].address
  remote_ranges          = ["10.10.0.0/24"]
  tunnels = {
    remote-0 = {
      cipher_suite = {
        phase1 = {
          dh         = ["Group-14"]
          encryption = ["AES-CBC-256"]
          integrity  = ["HMAC-SHA2-256-128"]
          prf        = ["PRF-HMAC-SHA2-256"]
        }
        phase2 = {
          encryption = ["AES-CBC-128"]
          integrity  = ["HMAC-SHA2-256-128"]
          pfs        = ["Group-14"]
        }
      }
      peer_ip           = "1.1.1.1"
      shared_secret     = "mysecret"
      traffic_selectors = { local = ["0.0.0.0/0"], remote = ["0.0.0.0/0"] }
    }
  }
}
# tftest modules=2 resources=8 inventory=vpn-single-tunnel-custom-ciphers.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L29) | VPN gateway name, and prefix used for dependent resources. | <code>string</code> | ✓ |  |
| [network](variables.tf#L34) | VPC used for the gateway and routes. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L39) | Project where resources will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L44) | Region used for resources. | <code>string</code> | ✓ |  |
| [gateway_address](variables.tf#L17) | Optional address assigned to the VPN gateway. Ignored unless gateway_address_create is set to false. | <code>string</code> |  | <code>null</code> |
| [gateway_address_create](variables.tf#L23) | Create external address assigned to the VPN gateway. Needs to be explicitly set to false to use address in gateway_address variable. | <code>bool</code> |  | <code>true</code> |
| [remote_ranges](variables.tf#L49) | Remote IP CIDR ranges. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [route_priority](variables.tf#L56) | Route priority, defaults to 1000. | <code>number</code> |  | <code>1000</code> |
| [tunnels](variables.tf#L62) | VPN tunnel configurations. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [address](outputs.tf#L17) | VPN gateway address. |  |
| [gateway](outputs.tf#L22) | VPN gateway resource. |  |
| [id](outputs.tf#L27) | Fully qualified VPN gateway id. |  |
| [name](outputs.tf#L32) | VPN gateway name. |  |
| [random_secret](outputs.tf#L37) | Generated secret. | ✓ |
| [self_link](outputs.tf#L43) | VPN gateway self link. |  |
| [tunnel_names](outputs.tf#L48) | VPN tunnel names. |  |
| [tunnel_self_links](outputs.tf#L56) | VPN tunnel self links. |  |
| [tunnels](outputs.tf#L64) | VPN tunnel resources. |  |
<!-- END TFDOC -->
