# Cloud VPN Dynamic Module

## Example

This example shows how to configure a single VPN tunnel using a couple of extra features

-  custom advertisement on the tunnel's BGP session; if custom advertisement is not needed, simply set the `bgp_peer_options` attribute to `null`
- internally generated shared secret, which can be fetched from the module's `random_secret` output for reuse; a predefined secret can be used instead by assigning it to the `shared_secret` attribute

```hcl
module "vm" {
  source     = "./fabric/modules/compute-vm"
  project_id = "my-project"
  zone       = "europe-west1-b"
  name       = "my-vm"
  network_interfaces = [{
    nat        = true
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  service_account_create = true
}


module "vpn-dynamic" {
  source          = "./fabric/modules/net-vpn-dynamic"
  project_id      = "my-project"
  region          = "europe-west1"
  network         = var.vpc.name
  name            = "gateway-1"
  router_config = {
    asn = 64514
  }

  tunnels = {
    remote-1 = {
      bgp_peer = {
        address = "169.254.139.134"
        asn     = 64513
        custom_advertise = {
          all_subnets          = true
          all_vpc_subnets      = false
          all_peer_vpc_subnets = false
          ip_ranges = {
            "192.168.0.0/24" = "Advertised range description"
          }
        }
      }
      bgp_session_range = "169.254.139.133/30"
      peer_ip           = module.vm.external_ip
    }
  }
}
# tftest modules=2 resources=12
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L29) | VPN gateway name, and prefix used for dependent resources. | <code>string</code> | ✓ |  |
| [network](variables.tf#L34) | VPC used for the gateway and routes. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L39) | Project where resources will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L44) | Region used for resources. | <code>string</code> | ✓ |  |
| [router_config](variables.tf#L49) | Cloud Router configuration for the VPN. If you want to reuse an existing router, set create to false and use name to specify the desired router. | <code title="object&#40;&#123;&#10;  create    &#61; optional&#40;bool, true&#41;&#10;  asn       &#61; number&#10;  name      &#61; optional&#40;string&#41;&#10;  keepalive &#61; optional&#40;number&#41;&#10;  custom_advertise &#61; optional&#40;object&#40;&#123;&#10;    all_subnets &#61; bool&#10;    ip_ranges   &#61; map&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [gateway_address](variables.tf#L17) | Optional address assigned to the VPN gateway. Ignored unless gateway_address_create is set to false. | <code>string</code> |  | <code>null</code> |
| [gateway_address_create](variables.tf#L23) | Create external address assigned to the VPN gateway. Needs to be explicitly set to false to use address in gateway_address variable. | <code>bool</code> |  | <code>true</code> |
| [tunnels](variables.tf#L64) | VPN tunnel configurations. | <code title="map&#40;object&#40;&#123;&#10;  bgp_peer &#61; object&#40;&#123;&#10;    address        &#61; string&#10;    asn            &#61; number&#10;    route_priority &#61; optional&#40;number, 1000&#41;&#10;    custom_advertise &#61; optional&#40;object&#40;&#123;&#10;      all_subnets          &#61; bool&#10;      all_vpc_subnets      &#61; bool&#10;      all_peer_vpc_subnets &#61; bool&#10;      ip_ranges            &#61; map&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#10;  bgp_session_range &#61; string&#10;  ike_version       &#61; optional&#40;number, 2&#41;&#10;  peer_ip           &#61; string&#10;  router            &#61; optional&#40;string&#41;&#10;  shared_secret     &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [address](outputs.tf#L17) | VPN gateway address. |  |
| [gateway](outputs.tf#L22) | VPN gateway resource. |  |
| [name](outputs.tf#L27) | VPN gateway name. |  |
| [random_secret](outputs.tf#L32) | Generated secret. |  |
| [router](outputs.tf#L38) | Router resource (only if auto-created). |  |
| [router_name](outputs.tf#L43) | Router name. |  |
| [self_link](outputs.tf#L48) | VPN gateway self link. |  |
| [tunnel_names](outputs.tf#L53) | VPN tunnel names. |  |
| [tunnel_self_links](outputs.tf#L61) | VPN tunnel self links. |  |
| [tunnels](outputs.tf#L69) | VPN tunnel resources. |  |

<!-- END TFDOC -->
