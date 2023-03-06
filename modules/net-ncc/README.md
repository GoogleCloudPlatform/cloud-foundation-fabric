# Network Connectivity Center Module

This module allows the creation and management of an NCC-based hub-and-spoke architecture. It focuses in site-to-cloud connectivity with network virtual appliances (NVAs) as the _backing resource_ for spokes. This allows to connect an external network to Google Cloud by using a SD-WAN router or another appliance with BGP capabilities. It does not handle site-to-site data transfer which is not available in all regions, in particular in EMEA.

The module can manage a hub, multiple spokes, and corresponding Cloud Routers and BGP sessions to network virtual appliances. The NVAs themselves, VPCs, and other Google Cloud resources should be handled externally.

## Examples

### Connect a site to a VPC network

In this example a router appliance connects with a peer router in an on-premises network, and also peers with a Cloud Router.

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = "my-project"
  name       = "network-a"
  subnets = [
    {
      name          = "subnet-a"
      ip_cidr_range = "10.1.3.0/24"
      region        = "us-central1"
    }
  ]
}

module "nva1" {
  source     = "./fabric/modules/compute-vm"
  project_id = "my-project"
  zone       = "us-central1-a"
  name       = "router-app-a"
  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["us-central1/subnet-a"]
    addresses  = {external = null, internal = "10.1.3.8"}
  }]
  can_ip_forward = true
}

module "ncc" {
  source     = "./fabric/modules/net-ncc"
  asn        = 65000
  name       = "ncc-hub"
  project_id = "my-project"
  spokes = {
    spoke_A = {
      vpc        = module.vpc.name
      region     = "us-central1"
      subnetwork = module.vpc.subnet_self_links["us-central1/subnet-a"]
      nvas = [
        {
          vm = module.nva1.self_link
          ip = module.nva1.internal_ip
        }
      ]
      router = {
        ip1       = "10.1.3.14"
        ip2       = "10.1.3.15"
        peer_asn  = 65001
      }
    }
  }
}
# tftest
```
