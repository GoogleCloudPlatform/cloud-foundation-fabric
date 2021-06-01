# Interconnect Attachment and BGP Session


This module allows creation of an InterconnectAttachment (VLAN attachment), a Cloud Router and BGP information that must be configured into the routing stack to establish BGP peering.

## Examples

The module allows the creation of one or more  Interconnect Attachments and related BGP Session.

### Interconnect attachments to achieve 99.9% SLA setup

```hcl
module "vlan-attachement-1"{
    source="./networking/interconnect"
    router_name="router-1"
    project = "dedicated-ic-3-8386"
    region = "us-west2"
    network_name = "myvpc"

    router_advertise_config = {
        groups = ["ALL_SUBNETS"]
        ip_ranges = {
           "199.36.153.8/30" = "custom"
       }
       mode = "CUSTOM"
       
    }
    asn=65003

    vlan_id=603
    interconnect="https://www.googleapis.com/compute/v1/projects/cso-lab-management/global/interconnects/cso-lab-interconnect-1"
    interconnect_region="us-west2"
    vlan_attachment_name="vlan-603-1"
    bgp_session_name="bgp-session"
    peer_ip_address="169.254.63.2"
    peer_asn=65418
    candidate_ip_ranges=["169.254.63.0/29"]
    ip_range="169.254.63.1/29"

}

module "vlan-attachement-2"{
  
  source="./networking/interconnect"
  router_name="router-2"
  project="dedicated-ic-3-8386"
  region="us-west2"
  network_name = "myvpc"

  router_advertise_config = {
        groups = ["ALL_SUBNETS"]
        ip_ranges = {
           "199.36.153.8/30" = "custom"
       }
       mode = "CUSTOM"
       
    }

    asn=65003
    vlan_id=603
    interconnect="https://www.googleapis.com/compute/v1/projects/cso-lab-             management/global/interconnects/cso-lab-interconnect-2"
    interconnect_region="us-west2"
    vlan_attachment_name="vlan-603-2"
    bgp_session_name="bgp-session"
    peer_ip_address="169.254.63.10"
    peer_asn=65418
    candidate_ip_ranges=["169.254.63.8/29"]
    ip_range="169.254.63.9/29"
}

```


<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| vlan_attachment_name | The name of the vlan attachment being created | <code title="">string</code> | ✓ |  |
| project_id | The ID of the project where this VLAN attachment will be created | <code title="">string</code> | ✓ |  |
| asn |Local BGP Autonomous System Number (ASN). Must be an RFC6996 private ASN, either 16-bit or 32-bit. The value will be fixed for this router resource. All VPN tunnels that link to this router will have the same local ASN. | <code title="">number</code> | ✓ | |
| network_name | A reference to the network to which this router belongs. | <code title="">string</code> |  ✓ |  |
| bgp_session_name | Name of the BGP peer. The name must be 1-63 characters long, and comply with RFC1035. Specifically, the name must be 1-63 characters long and match the regular expression `[a-z]([-a-z0-9]*[a-z0-9])?` which means the first character must be a lowercase letter, and all following characters must be a dash, lowercase letter, or digit, except the last character, which cannot be a dash. | <code title="">string</code> |  ✓ |  |
| peer_asn | Peer BGP Autonomous System Number (ASN). Each BGP interface may use a different value. | <code title="">number</code> |  ✓ |  |
| peer_ip_address | IP address of the BGP interface outside Google Cloud Platform. Only IPv4 is supported. | <code title="">string</code> |  ✓ |  |
| peer_asn | Peer BGP Autonomous System Number (ASN). Each BGP interface may use a different value. | <code title="">number</code> |  ✓ |  |
| *candidate_ip_ranges* | Up to 16 candidate prefixes that can be used to restrict the allocation of cloudRouterIpAddress and customerRouterIpAddress for this attachment. All prefixes must be within link-local address space (169.254.0.0/16) and must be /29 or shorter (/28, /27, etc). Google will attempt to select an unused /29 from the supplied candidate prefix(es). The request will fail if all possible /29s are in use on Google's edge. If not supplied, Google will randomly select an unused /29 from all of link-local space.| <code title="">string</code> |   |  |
| *vlan_id* |The IEEE 802.1Q VLAN tag for this attachment, in the range 2-4094. When using PARTNER type this will be managed upstream. | <code title="">number</code> |   |  |
| *interconnect* | URL of the underlying Interconnect object that this attachment's traffic will traverse through. Required if type is DEDICATED, must not be set if type is PARTNER. | <code title="">string</code> |  | <code title=""></code> |
| *router_name* | Router name.The name must be 1-63 characters long, and comply with RFC1035. Specifically, the name must be 1-63 characters long and match the regular expression `[a-z]([-a-z0-9]*[a-z0-9])?` which means the first character must be a lowercase letter, and all following characters must be a dash, lowercase letter, or digit, except the last character, which cannot be a dash. | <code title="">string</code> |  | <code title="">router-vlan_attachement_name</code> |
| *router_description* | An optional description of the router.| <code title="">string</code> |  |  |
| *encrypted_interconnect_router* | Field to indicate if a router is dedicated to use with encrypted Interconnect Attachment (IPsec-encrypted Cloud Interconnect feature). Not currently available publicly. | <code title="">bool</code> |  | <code title="">false</code> |
| *region* | Region where the router and the vlan attachement reside. | <code title="">string</code> |  | <code title="">us-west2</code> |
| *router_advertise_config* | Router custom advertisement configuration, ip_ranges is a map of address ranges and descriptions. | <code  title="object&#40;&#123;&#10;groups &#61; list&#40;string&#41;&#10;ip_ranges &#61; map&#40;string&#41;&#10;mode &#61; string&#10;&#125;&#41;">object({...})</code>|  | <code title="">null</code> |
| *description* | VLAN attachement description| <code title="">string</code> |  | <code title="">null</code> |

<!-- END TFDOC -->


