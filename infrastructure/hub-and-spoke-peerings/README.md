# Hub and Spoke VPNs

This sample creates a simple **Hub and Spoke Peerings** architecture, where the VPC network connects satellite locations (spokes) through a single intermediary location (hub) via [VPC Network Peering](https://cloud.google.com/vpc/docs/vpc-peering). 
> **NOTE**: This example does not provide full mesh networking, if you need connectivity between spoke networks you will have to create a peering between every two spokes. Make sure you are not going to hit the [VPC Network Peering limits](https://cloud.google.com/vpc/docs/quota#vpc-peering). 

The benefits of this topology include:

- Network/Security Admin manages Central Services Project (Hub).
- Central services and tools deployed in Central Services Project (Hub) for use by all Service Projects (Spokes).
- Network/Security Admin hands over spoke Projects to respective team who then have full autonomy.
- Network/Security Admin monitors spoke projects for organization security posture compliance using tools like [Forseti](https://forsetisecurity.org/), [CSCC](https://cloud.google.com/security-command-center/) etc deployed in Central Services Project (Hub).
- Spokes communicate with on-prem via VPC Network Peering to transit hub and then over Interconnect or VPN to on-premises (on-premises resources are not included in this sample for obvious reasons).
- This is a decentralized architecture where each spoke project has autonomy to manage all their GCP compute and network resources.

The purpose of this sample is showing how to wire different [Cloud Foundation Fabric](https://github.com/search?q=topic%3Acft-fabric+org%3Aterraform-google-modules&type=Repositories) modules to create **Hub and Spoke Peerings** network architectures, and as such it is meant to be used for prototyping, or to experiment with networking configurations. Additional best practices and security considerations need to be taken into account for real world usage (eg removal of default service accounts, disabling of external IPs, firewall design, etc).


![High-level diagram](diagram.png "High-level diagram")

## Managed resources and services

This sample creates several distinct groups of resources:

- three VPC Networks (hub network and two ppoke networks)
- VPC-level resources (VPC, subnets, firewall rules, etc.)
- one Cloud DNS Private zone in the hub project
- one Cloud DNS Forwarding zone in the hub project
- four Cloud DNS Peering zones (two per each spoke project)
- one Cloud DNS Policy for inbound forwarding
- four VPC Network Peerings (two in hub project and one per each spoke project)

## Test resources

A set of test resources are included for convenience, as they facilitate experimenting with different networking configurations (firewall rules, external connectivity via VPN, etc.). They are encapsulated in the `test-resources.tf` file, and can be safely removed as a single unit.

- two virtual machine instances in hub project (one per each region) 
- two virtual machine instances in spoke1 project (one per each region) 
- two virtual machine instances in spoke2 project (one per each region) 

SSH access to instances is configured via [OS Login](https://cloud.google.com/compute/docs/oslogin/). External access is allowed via the default SSH rule created by the firewall module, and corresponding `ssh` tags on the instances.

## Known issues
 - It is not possible to get inbound DNS forwarding IPs in the terraform output.
   -  Please refer to the [bug](https://github.com/terraform-providers/terraform-provider-google/issues/3753) for more details.
   -  Please refer to the [documentation](https://cloud.google.com/dns/zones/#creating_a_dns_policy_that_enables_inbound_dns_forwarding) on how to get the IPs with `gcloud`.

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| hub_project_id | Hub Project id. Same project can be used for hub and spokes. | <code title="">string</code> | ✓ |  |
| spoke_1_project_id | Spoke 1 Project id. Same project can be used for hub and spokes. | <code title="">string</code> | ✓ |  |
| spoke_2_project_id | Spoke 2 Project id. Same project can be used for hub and spokes. | <code title="">string</code> | ✓ |  |
| *forwarding_dns_zone_domain* | Forwarding DNS Zone Domain. | <code title="">string</code> |  | <code title="">on-prem.local.</code> |
| *forwarding_dns_zone_name* | Forwarding DNS Zone Name. | <code title="">string</code> |  | <code title="">on-prem-local</code> |
| *hub_subnets* | Hub VPC subnets configuration. | <code title="map&#40;object&#40;&#123;&#10;ip_cidr_range      &#61; string&#10;region             &#61; string&#10;secondary_ip_range &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="&#123;&#10;hub-subnet-a &#61; &#123;&#10;ip_cidr_range      &#61; &#34;10.10.10.0&#47;24&#34;&#10;region             &#61; &#34;europe-west1&#34;&#10;secondary_ip_range &#61; &#123;&#125;&#10;&#125;&#10;hub-subnet-b &#61; &#123;&#10;ip_cidr_range      &#61; &#34;10.10.20.0&#47;24&#34;&#10;region             &#61; &#34;europe-west2&#34;&#10;secondary_ip_range &#61; &#123;&#125;&#10;&#125;&#10;&#125;">...</code> |
| *on_prem_cidr_range* | On-prem CIDR range for on-prem-in-a-box emulation. | <code title="">string</code> |  | <code title="">192.168.192.0/24</code> |
| *private_dns_zone_domain* | Private DNS Zone Domain. | <code title="">string</code> |  | <code title="">gcp.local.</code> |
| *private_dns_zone_name* | Private DNS Zone Name. | <code title="">string</code> |  | <code title="">gcp-local</code> |
| *spoke_1_subnets* | Spoke 1 VPC subnets configuration. | <code title="map&#40;object&#40;&#123;&#10;ip_cidr_range      &#61; string&#10;region             &#61; string&#10;secondary_ip_range &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="&#123;&#10;spoke-1-subnet-a &#61; &#123;&#10;ip_cidr_range      &#61; &#34;10.20.10.0&#47;24&#34;&#10;region             &#61; &#34;europe-west1&#34;&#10;secondary_ip_range &#61; &#123;&#125;&#10;&#125;&#10;spoke-1-subnet-b &#61; &#123;&#10;ip_cidr_range      &#61; &#34;10.20.20.0&#47;24&#34;&#10;region             &#61; &#34;europe-west2&#34;&#10;secondary_ip_range &#61; &#123;&#125;&#10;&#125;&#10;&#125;">...</code> |
| *spoke_2_subnets* | Spoke 2 VPC subnets configuration. | <code title="map&#40;object&#40;&#123;&#10;ip_cidr_range      &#61; string&#10;region             &#61; string&#10;secondary_ip_range &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="&#123;&#10;spoke-2-subnet-a &#61; &#123;&#10;ip_cidr_range      &#61; &#34;10.30.10.0&#47;24&#34;&#10;region             &#61; &#34;europe-west1&#34;&#10;secondary_ip_range &#61; &#123;&#125;&#10;&#125;&#10;spoke-2-subnet-b &#61; &#123;&#10;ip_cidr_range      &#61; &#34;10.30.20.0&#47;24&#34;&#10;region             &#61; &#34;europe-west2&#34;&#10;secondary_ip_range &#61; &#123;&#125;&#10;&#125;&#10;&#125;">...</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| hub | Hub network resources. |  |
| spoke-1 | Spoke1 network resources. |  |
| spoke-2 | Spoke2 network resources. |  |
<!-- END TFDOC -->