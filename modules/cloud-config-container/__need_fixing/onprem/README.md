# Containerized on-premises infrastructure

This module manages a `cloud-config` configuration that starts an emulated on-premises infrastructure running in Docker Compose on a single instance, and connects it via static or dynamic VPN to a Google Cloud VPN gateway.

The emulated on-premises infrastructure is composed of:

- a [Strongswan container](./docker-images/strongswan) managing the VPN tunnel to GCP
- an optional Bird container managing the BGP session
- a CoreDNS container servng local DNS and forwarding to GCP
- an Nginx container serving a simple static web page
- a [generic Linux container](./docker-images/toolbox) used as a jump host inside the on-premises network

A complete scenario using this module is available in the networking blueprints.

The module renders the generated cloud config in the `cloud_config` output, to be used in instances or instance templates via the `user-data` metadata.

## Examples

### Static VPN

```hcl
module "cloud-vpn" {
  source        = "./fabric/modules/net-vpn-static"
  project_id    = "my-project"
  region        = "europe-west1"
  network       = "my-vpc"
  name          = "to-on-prem"
  remote_ranges = ["192.168.192.0/24"]
  tunnels = {
    remote-0 = {
      peer_ip           = module.vm.external_ip
      traffic_selectors = { local = ["0.0.0.0/0"], remote = null }
    }
  }
}

module "on-prem" {
  source = "./fabric/modules/cloud-config-container/onprem"
  vpn_config = {
    type          = "static"
    peer_ip       = module.cloud-vpn.address
    shared_secret = module.cloud-vpn.random_secret
  }
}

module "vm" {
  source     = "./fabric/modules/compute-vm"
  project_id = "my-project"
  zone       = "europe-west8-b"
  name       = "cos-nginx-tls"
  network_interfaces = [{
    nat        = true
    network    = "default"
    subnetwork = "gce"
  }]
  metadata = {
    user-data              = module.on-prem.cloud_config
    google-logging-enabled = true
  }
  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }
  tags = ["ssh"]
}
# tftest skip
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [vpn_config](variables.tf#L35) | VPN configuration, type must be one of 'dynamic' or 'static'. | <code title="object&#40;&#123;&#10;  peer_ip        &#61; string&#10;  shared_secret  &#61; string&#10;  type           &#61; optional&#40;string, &#34;static&#34;&#41;&#10;  peer_ip2       &#61; optional&#40;string&#41;&#10;  shared_secret2 &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [config_variables](variables.tf#L17) | Additional variables used to render the cloud-config and CoreDNS templates. | <code>map&#40;any&#41;</code> |  | <code>&#123;&#125;</code> |
| [coredns_config](variables.tf#L23) | CoreDNS configuration path, if null default will be used. | <code>string</code> |  | <code>null</code> |
| [local_ip_cidr_range](variables.tf#L29) | IP CIDR range used for the Docker onprem network. | <code>string</code> |  | <code>&#34;192.168.192.0&#47;24&#34;</code> |
| [vpn_dynamic_config](variables.tf#L46) | BGP configuration for dynamic VPN, ignored if VPN type is 'static'. | <code title="object&#40;&#123;&#10;  local_bgp_asn      &#61; number&#10;  local_bgp_address  &#61; string&#10;  peer_bgp_asn       &#61; number&#10;  peer_bgp_address   &#61; string&#10;  local_bgp_asn2     &#61; number&#10;  local_bgp_address2 &#61; string&#10;  peer_bgp_asn2      &#61; number&#10;  peer_bgp_address2  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  local_bgp_asn      &#61; 64514&#10;  local_bgp_address  &#61; &#34;169.254.1.2&#34;&#10;  peer_bgp_asn       &#61; 64513&#10;  peer_bgp_address   &#61; &#34;169.254.1.1&#34;&#10;  local_bgp_asn2     &#61; 64514&#10;  local_bgp_address2 &#61; &#34;169.254.2.2&#34;&#10;  peer_bgp_asn2      &#61; 64520&#10;  peer_bgp_address2  &#61; &#34;169.254.2.1&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [vpn_static_ranges](variables.tf#L70) | Remote CIDR ranges for static VPN, ignored if VPN type is 'dynamic'. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#34;10.0.0.0&#47;8&#34;&#93;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_config](outputs.tf#L17) | Rendered cloud-config file to be passed as user-data instance metadata. |  |

<!-- END TFDOC -->
