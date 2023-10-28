# Net Address Reservation Module

This module allows reserving Compute Engine external, global, and internal addresses.

## Examples

### External and global addresses

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  external_addresses = {
    one = { region = "europe-west1" }
    two = { region = "europe-west2" }
  }
  global_addresses = {
    app-1 = {}
    app-2 = {}
  }
}
# tftest modules=1 resources=4 inventory=external.yaml
```

### Internal addresses

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    ilb-1 = {
      purpose    = "SHARED_LOADBALANCER_VIP"
      region     = var.region
      subnetwork = var.subnet.self_link
    }
    ilb-2 = {
      address    = "10.0.0.2"
      region     = var.region
      subnetwork = var.subnet.self_link
    }
  }
}
# tftest modules=1 resources=2 inventory=internal.yaml
```

### IPv6 addresses

You can reserve both external and internal IPv6 addresses.

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  external_addresses = {
    nlb = {
      region     = var.region
      subnetwork = var.subnet.self_link
      ipv6 = {
        endpoint_type = "NETLB"
      }
    }
  }
  internal_addresses = {
    ilb = {
      ipv6       = {}
      purpose    = "SHARED_LOADBALANCER_VIP"
      region     = var.region
      subnetwork = var.subnet.self_link
    }
    vm = {
      ipv6       = {}
      region     = var.region
      subnetwork = var.subnet.self_link
    }
  }
}
# tftest modules=1 resources=3 inventory=ipv6.yaml
```

### PSA addresses

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  psa_addresses = {
    cloudsql-mysql = {
      address       = "10.10.10.0"
      network       = var.vpc.self_link
      prefix_length = 24
    }
  }
}
# tftest modules=1 resources=1 inventory=psa.yaml
```

### PSC addresses

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  psc_addresses = {
    one = {
      address = null
      network = var.vpc.self_link
    }
    two = {
      address = "10.0.0.32"
      network = var.vpc.self_link
    }
  }
}
# tftest modules=1 resources=2 inventory=psc.yaml
```

# IPSec Interconnect addresses

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  ipsec_interconnect_addresses = {
    vpn-gw-range-1 = {
      address       = "10.255.255.0"
      region        = var.region
      network       = var.vpc.self_link
      prefix_length = 29
    }
    vpn-gw-range-2 = {
      address       = "10.255.255.8"
      region        = var.region
      network       = var.vpc.self_link
      prefix_length = 29
    }
  }
}
# tftest modules=1 resources=2 inventory=ipsec-interconnect.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L83) | Project where the addresses will be created. | <code>string</code> | ✓ |  |
| [external_addresses](variables.tf#L17) | Map of external addresses, keyed by name. | <code title="map&#40;object&#40;&#123;&#10;  region      &#61; string&#10;  description &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  ipv6 &#61; optional&#40;object&#40;&#123;&#10;    endpoint_type &#61; string&#10;  &#125;&#41;&#41;&#10;  labels &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  name   &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [global_addresses](variables.tf#L38) | List of global addresses to create. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  ipv6        &#61; optional&#40;map&#40;string&#41;&#41; &#35; To be left empty for ipv6&#10;  name        &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [internal_addresses](variables.tf#L48) | Map of internal addresses to create, keyed by name. | <code title="map&#40;object&#40;&#123;&#10;  region      &#61; string&#10;  subnetwork  &#61; string&#10;  address     &#61; optional&#40;string&#41;&#10;  description &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  ipv6        &#61; optional&#40;map&#40;string&#41;&#41; &#35; To be left empty for ipv6&#10;  labels      &#61; optional&#40;map&#40;string&#41;&#41;&#10;  name        &#61; optional&#40;string&#41;&#10;  purpose     &#61; optional&#40;string&#41;&#10;  tier        &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ipsec_interconnect_addresses](variables.tf#L64) | Map of internal addresses used for HPA VPN over Cloud Interconnect. | <code title="map&#40;object&#40;&#123;&#10;  region        &#61; string&#10;  address       &#61; string&#10;  network       &#61; string&#10;  description   &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  name          &#61; optional&#40;string&#41;&#10;  prefix_length &#61; number&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [psa_addresses](variables.tf#L88) | Map of internal addresses used for Private Service Access. | <code title="map&#40;object&#40;&#123;&#10;  address       &#61; string&#10;  network       &#61; string&#10;  prefix_length &#61; number&#10;  description   &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  name          &#61; optional&#40;string&#41;&#10;&#10;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [psc_addresses](variables.tf#L101) | Map of internal addresses used for Private Service Connect. | <code title="map&#40;object&#40;&#123;&#10;  address     &#61; string&#10;  network     &#61; string&#10;  description &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  name        &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [external_addresses](outputs.tf#L17) | Allocated external addresses. |  |
| [global_addresses](outputs.tf#L25) | Allocated global external addresses. |  |
| [internal_addresses](outputs.tf#L33) | Allocated internal addresses. |  |
| [ipsec_interconnect_addresses](outputs.tf#L41) | Allocated internal addresses for HA VPN over Cloud Interconnect. |  |
| [psa_addresses](outputs.tf#L49) | Allocated internal addresses for PSA endpoints. |  |
| [psc_addresses](outputs.tf#L57) | Allocated internal addresses for PSC endpoints. |  |
<!-- END TFDOC -->
