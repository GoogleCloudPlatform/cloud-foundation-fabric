# Net Address Reservation Module

This module allows reserving Compute Engine external, global, and internal addresses.

## Examples

### External and global addresses

```hcl
module "addresses" {
  source     = "./modules/net-address"
  project_id = var.project_id
  external_addresses = {
    nat-1      = var.region
    vpn-remote = var.region
  }
  global_addresses = ["app-1", "app-2"]
}
# tftest modules=1 resources=4
```

### Internal addresses

```hcl
module "addresses" {
  source     = "./modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    ilb-1 = {
      region     = var.region
      subnetwork = var.subnet.self_link
    }
    ilb-2 = {
      region     = var.region
      subnetwork = var.subnet.self_link
    }
  }
  # optional configuration
  internal_addresses_config = {
    ilb-1 = {
      address = null
      purpose = "SHARED_LOADBALANCER_VIP"
      tier = null
    }
  }
}
# tftest modules=1 resources=2
```

### PSA addresses

```hcl
module "addresses" {
  source     = "./modules/net-address"
  project_id = var.project_id
  psa_addresses = {
    cloudsql-mysql = {
      address       = "10.10.10.0"
      network       = var.vpc.self_link
      prefix_length = 24
    }
  }
}
# tftest modules=1 resources=1
```

### PSC addresses

```hcl
module "addresses" {
  source     = "./modules/net-address"
  project_id = var.project_id
  psc_addresses = {
    one = {
      address     = null
      network = var.vpc.self_link
    }
    two = {
      address     = "10.0.0.32"
      network = var.vpc.self_link
    }
  }
}
# tftest modules=1 resources=2
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L60) | Project where the addresses will be created. | <code>string</code> | ✓ |  |
| [external_addresses](variables.tf#L17) | Map of external address regions, keyed by name. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [global_addresses](variables.tf#L29) | List of global addresses to create. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [internal_addresses](variables.tf#L35) | Map of internal addresses to create, keyed by name. | <code title="map&#40;object&#40;&#123;&#10;  region     &#61; string&#10;  subnetwork &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [internal_addresses_config](variables.tf#L44) | Optional configuration for internal addresses, keyed by name. Unused options can be set to null. | <code title="map&#40;object&#40;&#123;&#10;  address &#61; string&#10;  purpose &#61; string&#10;  tier    &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [psa_addresses](variables.tf#L65) | Map of internal addresses used for Private Service Access. | <code title="map&#40;object&#40;&#123;&#10;  address       &#61; string&#10;  network       &#61; string&#10;  prefix_length &#61; number&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [psc_addresses](variables.tf#L75) | Map of internal addresses used for Private Service Connect. | <code title="map&#40;object&#40;&#123;&#10;  address &#61; string&#10;  network &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [external_addresses](outputs.tf#L17) | Allocated external addresses. |  |
| [global_addresses](outputs.tf#L28) | Allocated global external addresses. |  |
| [internal_addresses](outputs.tf#L39) | Allocated internal addresses. |  |
| [psa_addresses](outputs.tf#L50) | Allocated internal addresses for PSA endpoints. |  |
| [psc_addresses](outputs.tf#L62) | Allocated internal addresses for PSC endpoints. |  |

<!-- END TFDOC -->
