# Interconnect Attachment and BGP Session


This module allows creation of a VLAN attachment and router.

## Examples

### Interconnect attachments to achieve 99.9% SLA setup

```hcl
module "vlan-attachment-1" {
  source       = "./modules/net-interconnect"
  project_id   = "dedicated-ic-3-8386"
  region       = "us-west2"
  router = {
    name  = "router-1"
    description =""
    asn = 65003
  }
  network_name = "myvpc"
  router_advertise_config = {
    groups = ["ALL_SUBNETS"]
    ip_ranges = {
      "199.36.153.8/30" = "custom"
    }
    mode = "CUSTOM"

  }
  vlan_attachment = {
    name = "vlan-603-1"
    vlan_id      = 603
    interconnect = "https://www.googleapis.com/compute/v1/projects/cso-lab-management/global/interconnects/cso-lab-interconnect-1"
    bandwidth     = "BPS_10G"
    admin_enabled = true
  }
  bgp = {
    peer_ip_address           = "169.254.63.2"
    peer_asn                  = 65418
    bgp_session_range   = "169.254.63.1/29"
    advertised_route_priority = 0
    candidate_ip_ranges = ["169.254.63.0/29"]
  }
}

module "vlan-attachment-2" {
  source       = "./modules/net-interconnect"
  project_id   = "dedicated-ic-3-8386"
  region       = "us-west2"
  router = {
      name  = "router-2"
      description=""
       asn = 65003
  }
  network_name = "myvpc"
  router_advertise_config = {
    groups = ["ALL_SUBNETS"]
    ip_ranges = {
      "199.36.153.8/30" = "custom"
    }
    mode = "CUSTOM"
  }
 
  vlan_attachment = {
    name = "vlan-603-2"
    vlan_id       = 603
    interconnect  = "https://www.googleapis.com/compute/v1/projects/cso-lab-management/global/interconnects/cso-lab-interconnect-2"
    bandwidth     = "BPS_10G"
    admin_enabled = true
  }
  bgp = {
    peer_ip_address           = "169.254.63.10"
    peer_asn                  = 65418
    bgp_session_range   = "169.254.63.9/29"
    advertised_route_priority = 0
    candidate_ip_ranges = ["169.254.63.8/29"]
  }    
}
# tftest:modules=2:resources=8
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| bgp | Bgp session parameters | <code title="object&#40;&#123;&#10;peer_ip_address           &#61; string&#10;peer_asn                  &#61; number&#10;bgp_session_range         &#61; string&#10;candidate_ip_ranges       &#61; list&#40;string&#41;&#10;advertised_route_priority &#61; number&#10;&#125;&#41;">object({...})</code> | ✓ |  |
| network_name | A reference to the network to which this router belongs | <code title="">string</code> | ✓ |  |
| project_id | The project containing the resources | <code title="">string</code> | ✓ |  |
| *description* | Vlan attachement description | <code title="">string</code> |  | <code title=""></code> |
| *region* | Region where the router resides | <code title="">string</code> |  | <code title="">europe-west1-b</code> |
| *router* | Router name and description.  | <code title="object&#40;&#123;&#10;name        &#61; string&#10;description &#61; string&#10;asn         &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;name        &#61; &#34;&#34;&#10;description &#61; &#34;&#34;&#10;asn         &#61;null&#10;&#125;">...</code> |
| *router_advertise_config* | Router custom advertisement configuration, ip_ranges is a map of address ranges and descriptions. | <code title="object&#40;&#123;&#10;groups    &#61; list&#40;string&#41;&#10;ip_ranges &#61; map&#40;string&#41;&#10;mode      &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *router_create* | Create router. | <code title="">bool</code> |  | <code title="">true</code> |
| *vlan_attachment* | VLAN attachment parameters | <code title="object&#40;&#123;&#10;name          &#61; string&#10;vlan_id       &#61; number&#10;bandwidth     &#61; string&#10;admin_enabled &#61; bool&#10;interconnect  &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;name          &#61; &#34;&#34;&#10;vlan_id       &#61; null&#10;bandwidth     &#61; &#34;BPS_10G&#34;&#10;admin_enabled &#61; true&#10;interconnect  &#61; null&#10;&#125;">...</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| bgpsession | bgp session |  |
| interconnect_attachment | interconnect attachment |  |
| router | Router resource (only if auto-created). |  |
<!-- END TFDOC -->
