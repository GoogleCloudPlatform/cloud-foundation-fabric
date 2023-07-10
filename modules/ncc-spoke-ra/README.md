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
  region     = "europe-west1"
  router_appliances = [
    {
      internal_ip  = "10.0.0.3"
      vm_self_link = "projects/my-project/zones/europe-west1-b/instances/router-app"
    }
  ]
  router_config = {
    asn           = 65000
    ip_interface0 = "10.0.0.14"
    ip_interface1 = "10.0.0.15"
    peer_asn      = 65001
  }
  vpc_config = {
    network_name     = "my-vpc"
    subnet_self_link = var.subnet.self_link
  }
}
# tftest modules=1 resources=7
```

### Two spokes

```hcl
module "spoke-ra-a" {
  source     = "./fabric/modules/ncc-spoke-ra"
  hub        = { id = "projects/my-project/locations/global/hubs/ncc-hub" }
  name       = "spoke-ra-a"
  project_id = "my-project"
  region     = "europe-west1"
  router_appliances = [
    {
      internal_ip  = "10.0.0.3"
      vm_self_link = "projects/my-project/zones/europe-west1-b/instances/router-app-a"
    }
  ]
  router_config = {
    asn           = 65000
    ip_interface0 = "10.0.0.14"
    ip_interface1 = "10.0.0.15"
    peer_asn      = 65001
  }
  vpc_config = {
    network_name     = "my-vpc1"
    subnet_self_link = "projects/my-project/regions/europe-west1/subnetworks/subnet"
  }
}

module "spoke-ra-b" {
  source     = "./fabric/modules/ncc-spoke-ra"
  hub        = { id = "projects/my-project/locations/global/hubs/ncc-hub" }
  name       = "spoke-ra-b"
  project_id = "my-project"
  region     = "europe-west3"
  router_appliances = [
    {
      internal_ip  = "10.1.0.5"
      vm_self_link = "projects/my-project/zones/europe-west3-b/instances/router-app-b"
    }
  ]
  router_config = {
    asn           = 65000
    ip_interface0 = "10.0.0.14"
    ip_interface1 = "10.0.0.15"
    peer_asn      = 65002
  }
  vpc_config = {
    network_name     = "my-vpc2"
    subnet_self_link = "projects/my-project/regions/europe-west3/subnetworks/subnet"
  }
}
# tftest modules=2 resources=12
```

### Spoke with load-balanced router appliances

```hcl
module "spoke-ra" {
  source     = "./fabric/modules/ncc-spoke-ra"
  hub        = { id = "projects/my-project/locations/global/hubs/ncc-hub" }
  name       = "spoke-ra"
  project_id = "my-project"
  region     = "europe-west1"
  router_appliances = [
    {
      internal_ip  = "10.0.0.3"
      vm_self_link = "projects/my-project/zones/europe-west1-b/instances/router-app-a"
    },
    {
      internal_ip  = "10.0.0.4"
      vm_self_link = "projects/my-project/zones/europe-west1-c/instances/router-app-b"
    }
  ]
  router_config = {
    asn = 65000
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        "10.10.0.0/24" = "peered-vpc"
      }
    }
    ip_interface0 = "10.0.0.14"
    ip_interface1 = "10.0.0.15"
    peer_asn      = 65001
  }
  vpc_config = {
    network_name     = "my-vpc"
    subnet_self_link = var.subnet.self_link
  }
}
# tftest modules=1 resources=8
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [hub](variables.tf#L23) | The NCC hub. You should either provide an existing hub id or a hub name if create is true. | <code title="object&#40;&#123;&#10;  create      &#61; optional&#40;bool, false&#41;&#10;  description &#61; optional&#40;string&#41;&#10;  id          &#61; optional&#40;string&#41;&#10;  name        &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L37) | The name of the NCC spoke. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L42) | The ID of the project where the NCC hub & spokes will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L47) | Region where the spoke is located. | <code>string</code> | ✓ |  |
| [router_appliances](variables.tf#L52) | List of router appliances this spoke is associated with. | <code title="list&#40;object&#40;&#123;&#10;  internal_ip  &#61; string&#10;  vm_self_link &#61; string&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [router_config](variables.tf#L60) | Configuration of the Cloud Router. | <code title="object&#40;&#123;&#10;  asn &#61; number&#10;  custom_advertise &#61; optional&#40;object&#40;&#123;&#10;    all_subnets &#61; bool&#10;    ip_ranges   &#61; map&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  ip_interface0   &#61; string&#10;  ip_interface1   &#61; string&#10;  keepalive       &#61; optional&#40;number&#41;&#10;  peer_asn        &#61; number&#10;  routes_priority &#61; optional&#40;number, 100&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [vpc_config](variables.tf#L76) | Network and subnetwork for the CR interfaces. | <code title="object&#40;&#123;&#10;  network_name     &#61; string&#10;  subnet_self_link &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [data_transfer](variables.tf#L17) | Site-to-site data transfer feature, available only in some regions. | <code>bool</code> |  | <code>false</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [hub](outputs.tf#L17) | NCC hub resource (only if auto-created). |  |
| [id](outputs.tf#L22) | Fully qualified hub id. |  |
| [router](outputs.tf#L27) | Cloud Router resource. |  |
| [spoke-ra](outputs.tf#L32) | NCC spoke resource. |  |

<!-- END TFDOC -->
