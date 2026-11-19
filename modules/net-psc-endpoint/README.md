# Private Service Connect Endpoints Module

This module manages Private Service Connect (PSC) consumer endpoints and their internal IP addresses for published services, global Google APIs (`all-apis`, `vpc-sc`), and regional or multi-regional Google APIs (`*.rep.googleapis.com`).

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Published services](#published-services)
  - [Global Google APIs](#global-google-apis)
  - [Regional and multi-regional Google APIs](#regional-and-multi-regional-google-apis)
  - [Migrating from net-address](#migrating-from-net-address)
  - [Context interpolation](#context-interpolation)
- [Variables](#variables)
- [Outputs](#outputs)
- [Fixtures](#fixtures)
<!-- END TOC -->

## Examples

### Published services

To create regional PSC endpoints targeting published service attachments, configure `published_services`. Set `global_access = true` to make a regional endpoint reachable from any region in the VPC.

```hcl
module "psc_endpoints" {
  source     = "./fabric/modules/net-psc-endpoint"
  project_id = var.project_id
  published_services = {
    cloudsql-one = {
      address    = "10.0.16.32"
      region     = var.region
      subnetwork = var.subnet.self_link
      target     = module.cloudsql-instance.psc_service_attachment_link
    }
    cloudsql-global = {
      address       = "10.0.16.33"
      global_access = true
      region        = var.region
      subnetwork    = var.subnet.self_link
      target        = module.cloudsql-instance.psc_service_attachment_link
    }
  }
}
# tftest modules=2 resources=5 fixtures=fixtures/cloudsql-instance.tf inventory=published-services.yaml e2e
```

To reuse an existing internal IP address managed outside this module, set `address_create = false` and pass the existing address self-link or ID in `address`.

```hcl
module "psc_endpoints" {
  source     = "./fabric/modules/net-psc-endpoint"
  project_id = var.project_id
  published_services = {
    cloudsql-existing = {
      address        = "projects/${var.project_id}/regions/${var.region}/addresses/existing-psc"
      address_create = false
      region         = var.region
      subnetwork     = var.subnet.self_link
      target         = module.cloudsql-instance.psc_service_attachment_link
    }
  }
}
# tftest modules=2 resources=2 fixtures=fixtures/cloudsql-instance.tf inventory=published-services-existing-address.yaml
```

### Global Google APIs

Configure `global_apis` with `target` set to `all-apis` or `vpc-sc` to create a global PSC endpoint for Google APIs, and optionally register it with Service Directory. Global API endpoint names must be 1-20 lowercase letters and digits with no hyphens (when `prefix` is set, no hyphen separator is added on `global_apis`).

```hcl
module "psc_endpoints" {
  source     = "./fabric/modules/net-psc-endpoint"
  project_id = var.project_id
  global_apis = {
    googleapis = {
      address = "10.0.32.32"
      network = var.vpc.self_link
      target  = "all-apis"
      service_directory_registration = {
        region = var.region
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=global-apis.yaml e2e
```

### Regional and multi-regional Google APIs

[Regional endpoints](https://cloud.google.com/vpc/docs/access-regional-google-apis-endpoints) give private access to regional and multi-regional Google APIs (`<api>.<location>.rep.googleapis.com`), which the global `all-apis` and `vpc-sc` PSC endpoints and Private Google Access do not serve. Configure `regional_apis`: the module reserves the regional internal address (unless `address_create = false`) and creates the regional endpoint. Multi-regional APIs like `aiplatform.eu.rep.googleapis.com` still need a region and a subnet, and the API requires the VPC network in addition to the subnet.

Some notes on regional endpoints:

- the `networkconnectivity.googleapis.com` API needs to be enabled in the project
- in Shared VPC, the Network Connectivity service agent of the service project needs `roles/compute.networkUser` on the host project
- regional endpoints have their own quota, separate from PSC forwarding rules
- the access type (`global_access`) cannot be changed in place, the endpoint is recreated
- use the `addresses` or `regional_apis` outputs to create DNS records for the API hostname, for example in a private zone created via the [`dns`](../dns/) module or in a [`dns-response-policy`](../dns-response-policy/)

```hcl
module "psc_endpoints" {
  source     = "./fabric/modules/net-psc-endpoint"
  project_id = var.project_id
  regional_apis = {
    aiplatform-eu = {
      network    = var.vpc.self_link
      region     = var.region
      subnetwork = var.subnets.primary.self_link
      target     = "aiplatform.eu.rep.googleapis.com"
    }
    storage = {
      address       = "10.0.16.10"
      global_access = true
      network       = var.vpc.self_link
      region        = var.region
      subnetwork    = var.subnets.primary.self_link
      target        = "storage.${var.region}.rep.googleapis.com"
    }
  }
}
# tftest modules=1 resources=4 inventory=regional-apis.yaml
```

### Migrating from net-address

Existing PSC endpoints managed by [`modules/net-address`](../net-address/) can be moved into `modules/net-psc-endpoint` without resource replacement using `moved` blocks:

```hcl
moved {
  from = module.addresses.google_compute_global_address.psc_globalapis["googleapis"]
  to   = module.psc_endpoints.google_compute_global_address.global_apis["googleapis"]
}

moved {
  from = module.addresses.google_compute_global_forwarding_rule.psc_globalapis["googleapis"]
  to   = module.psc_endpoints.google_compute_global_forwarding_rule.global_apis["googleapis"]
}

moved {
  from = module.addresses.google_compute_address.psc_publishedservices["cloudsql-one"]
  to   = module.psc_endpoints.google_compute_address.published_services["cloudsql-one"]
}

moved {
  from = module.addresses.google_compute_forwarding_rule.psc_publishedservices["cloudsql-one"]
  to   = module.psc_endpoints.google_compute_forwarding_rule.published_services["cloudsql-one"]
}

moved {
  from = module.addresses.google_compute_address.psc_regionalapis["storage"]
  to   = module.psc_endpoints.google_compute_address.regional_apis["storage"]
}

moved {
  from = module.addresses.google_network_connectivity_regional_endpoint.psc_regionalapis["storage"]
  to   = module.psc_endpoints.google_network_connectivity_regional_endpoint.regional_apis["storage"]
}
# tftest skip
```

### Context interpolation

The module supports context-based interpolation for addresses, locations, networks, project IDs, service attachments, and subnets.

```hcl
module "psc_endpoints" {
  source     = "./fabric/modules/net-psc-endpoint"
  project_id = "$project_ids:my-prj"
  context = {
    addresses = {
      psc-global   = "10.0.0.32"
      psc-existing = "projects/my-project-1/regions/us-central1/addresses/existing-psc"
    }
    locations = {
      primary-region = "us-central1"
    }
    networks = {
      shared-vpc = "projects/prj-host/global/networks/shared-vpc"
    }
    project_ids = {
      my-prj = "my-project-1"
    }
    service_attachments = {
      ssm-http = "projects/prj-tenant/regions/us-central1/serviceAttachments/http-psc"
    }
    subnets = {
      subnet-primary = "projects/prj-host/regions/us-central1/subnetworks/sub-1"
    }
  }
  global_apis = {
    googleapis = {
      address = "$addresses:psc-global"
      network = "$networks:shared-vpc"
      target  = "all-apis"
      service_directory_registration = {
        region = "$locations:primary-region"
      }
    }
  }
  published_services = {
    ssm-http = {
      address        = "$addresses:psc-existing"
      address_create = false
      global_access  = true
      region         = "$locations:primary-region"
      subnetwork     = "$subnets:subnet-primary"
      target         = "$service_attachments:ssm-http"
    }
  }
  regional_apis = {
    storage = {
      network    = "$networks:shared-vpc"
      region     = "$locations:primary-region"
      subnetwork = "$subnets:subnet-primary"
      target     = "storage.us-central1.rep.googleapis.com"
    }
  }
}
# tftest modules=1 resources=5 inventory=context.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L94) | Project where the PSC endpoints will be created. | <code>string</code> | ✓ |  |
| [context](variables.tf#L17) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [global_apis](variables.tf#L31) | Global Private Service Connect endpoints for Google APIs, keyed by name. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L84) | Optional prefix used for resource names. | <code>string</code> |  | <code>null</code> |
| [published_services](variables.tf#L99) | Regional Private Service Connect endpoints for published services, keyed by name. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [regional_apis](variables.tf#L142) | Regional and multi-regional Private Service Connect endpoints for Google APIs (*.rep.googleapis.com), keyed by name. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [addresses](outputs.tf#L17) | Allocated or configured IP addresses for PSC endpoints. |  |
| [global_apis](outputs.tf#L41) | Allocated resources for global Google APIs PSC endpoints. |  |
| [published_services](outputs.tf#L51) | Allocated resources for published services PSC endpoints. |  |
| [regional_apis](outputs.tf#L61) | Allocated resources for regional Google APIs PSC endpoints. |  |

## Fixtures

- [cloudsql-instance.tf](../../tests/fixtures/cloudsql-instance.tf)
<!-- END TFDOC -->
