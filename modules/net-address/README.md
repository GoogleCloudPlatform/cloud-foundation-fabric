# Net Address Reservation Module

This module allows reserving Compute Engine external, global, and internal addresses.

## Examples

### External and global addresses

```hcl
module "addresses" {
  source     = "./modules/net-address"
  project_id = local.projects.host
  external_addresses = {
    nat-1      = var.region
    vpn-remote = var.region
  }
  global_addresses = ["app-1", "app-2"]
}
```

### Internal addresses

```hcl
module "addresses" {
  source     = "./modules/net-address"
  project_id = local.projects.host
  internal_addresses = {
    ilb-1      = {
      region = var.region
      subnetwork = module.vpc.subnet_self_links["${var.region}-test"]
    }
    ilb-2      = {
      region = var.region
      subnetwork = module.vpc.subnet_self_links["${var.region}-test"]
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
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| project_id | Project where the addresses will be created. | <code title="">string</code> | ✓ |  |
| *external_addresses* | Map of external address regions, keyed by name. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *global_addresses* | List of global addresses to create. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *internal_addresses* | Map of internal addresses to create, keyed by name. | <code title="map&#40;object&#40;&#123;&#10;region     &#61; string&#10;subnetwork &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *internal_addresses_config* | Optional configuration for internal addresses, keyed by name. Unused options can be set to null. | <code title="map&#40;object&#40;&#123;&#10;address &#61; string&#10;purpose &#61; string&#10;tier    &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| external_addresses | None |  |
| global_addresses | None |  |
| internal_addresses | None |  |
<!-- END TFDOC -->