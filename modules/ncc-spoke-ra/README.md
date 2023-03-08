# NCC Spoke RA Module

This module allows management of NCC Spokes backed by Router Appliances. Network virtual appliances used as router appliances allow to connect an external network to Google Cloud by using a SD-WAN router or another appliance with BGP capabilities (_site-to-cloud_ connectivity). It is also possible to enable site-to-site data transfer, although this feature is not available in all regions, particularly not in EMEA.

The module manages a hub (optionally), a spoke, and the corresponding Cloud Router and BGP sessions to the router appliance(s).

## Examples

### Simple hub & spoke

```hcl
module "spoke-ra" {
  source     = "./fabric/modules/ncc-spoke-ra"
  hub        = { create = true, name = "ncc-hub" }
  name       = "spoke-ra"
  project_id = "my-project"
  asn        = 65000
  peer_asn   = 65001
  ras = [
    {
      vm = "projects/my-project/zones/europe-west1-b/instances/router-app"
      ip = "10.0.0.3"
    }
  ]
  region     = "europe-west1"
  subnetwork = var.subnet.self_link
  vpc        = "my-vpc"
}
# tftest modules=1 resources=7
```

### Two spokes

```hcl
module "spoke-ra-a" {
  source     = "./fabric/modules/ncc-spoke-ra"
  hub        = { name = "ncc-hub" }
  name       = "spoke-ra-a"
  project_id = "my-project"
  asn        = 65000
  peer_asn   = 65001
  ras = [
    {
      vm = "projects/my-project/zones/europe-west1-b/instances/router-app-a"
      ip = "10.0.0.3"
    }
  ]
  region     = "europe-west1"
  subnetwork = "projects/my-project/regions/europe-west1/subnetworks/subnet"
  vpc        = "my-vpc1"
}

module "spoke-ra-b" {
  source     = "./fabric/modules/ncc-spoke-ra"
  hub        = { name = "ncc-hub" }
  name       = "spoke-ra-b"
  project_id = "my-project"
  asn        = 65000
  peer_asn   = 65002
  ras = [
    {
      vm = "projects/my-project/zones/europe-west3-b/instances/router-app-b"
      ip = "10.1.0.5"
    }
  ]
  region     = "europe-west3"
  subnetwork = "projects/my-project/regions/europe-west3/subnetworks/subnet"
  vpc        = "my-vpc2"
}
# tftest modules=2 resources=12
```

### Spoke with load-balanced router appliances

```hcl
module "spoke-ra" {
  source     = "./fabric/modules/ncc-spoke-ra"
  hub        = { name = "ncc-hub" }
  name       = "spoke-ra"
  project_id = "my-project"
  asn        = 65000
  custom_advertise = {
    all_subnets = true
    ip_ranges = {
      "peered-vpc" = "10.10.0.0/24"
    }
  }
  ip_intf1 = "10.0.0.14"
  ip_intf2 = "10.0.0.15"
  peer_asn = 65001
  ras = [
    {
      vm = "projects/my-project/zones/europe-west1-b/instances/router-app-a"
      ip = "10.0.0.3"
    },
    {
      vm = "projects/my-project/zones/europe-west1-c/instances/router-app-b"
      ip = "10.0.0.4"
    }
  ]
  region     = "europe-west1"
  subnetwork = var.subnet.self_link
  vpc        = "my-vpc"
}
# tftest modules=1 resources=8
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [asn](variables.tf#L17) | Autonomous System Number for the CR. All spokes in a hub should use the same ASN. | <code>number</code> | ✓ |  |
| [hub](variables.tf#L37) | The name of the NCC hub to create or use. | <code title="object&#40;&#123;&#10;  create      &#61; optional&#40;bool, false&#41;&#10;  name        &#61; string&#10;  description &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L64) | The name of the NCC spoke. | <code>string</code> | ✓ |  |
| [peer_asn](variables.tf#L69) | Peer Autonomous System Number used by the router appliances. | <code>number</code> | ✓ |  |
| [project_id](variables.tf#L74) | The ID of the project where the NCC hub & spokes will be created. | <code>string</code> | ✓ |  |
| [ras](variables.tf#L79) | List of router appliances this spoke is associated with. | <code title="list&#40;object&#40;&#123;&#10;  vm &#61; string &#35; URI&#10;  ip &#61; string&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [region](variables.tf#L87) | Region where the spoke is located. | <code>string</code> | ✓ |  |
| [subnetwork](variables.tf#L92) | The URI of the subnetwork that CR interfaces belong to. | <code>string</code> | ✓ |  |
| [vpc](variables.tf#L97) | A reference to the network to which the CR belongs. | <code>string</code> | ✓ |  |
| [custom_advertise](variables.tf#L22) | IP ranges to advertise if not using default route advertisement (subnet ranges). | <code title="object&#40;&#123;&#10;  all_subnets &#61; bool&#10;  ip_ranges   &#61; map&#40;string&#41; &#35; map of descriptions and address ranges&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [data_transfer](variables.tf#L31) | Site-to-site data transfer feature, available only in some regions. | <code>bool</code> |  | <code>false</code> |
| [ip_intf1](variables.tf#L46) | IP address for the CR interface 1. It must belong to the primary range of the subnet. If you don't specify a value Google will try to find a free address. | <code>string</code> |  | <code>null</code> |
| [ip_intf2](variables.tf#L52) | IP address for the CR interface 2. It must belong to the primary range of the subnet. If you don't specify a value Google will try to find a free address. | <code>string</code> |  | <code>null</code> |
| [keepalive](variables.tf#L58) | The interval in seconds between BGP keepalive messages that are sent to the peer. | <code>number</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [hub_name](outputs.tf#L17) | NCC hub name (only if auto-created). |  |

<!-- END TFDOC -->
