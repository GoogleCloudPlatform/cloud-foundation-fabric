# Cross-region Internal Proxy Network Load Balancer Module

This module allows managing Cross-region Internal Proxy Network Load Balancers (L4 proxy ILBs). It's designed to expose the full configuration of the underlying resources, and to facilitate common usage patterns by providing sensible defaults, and optionally managing prerequisite resources like health checks, network endpoint groups (NEGs), etc.

> [!IMPORTANT]
> Cross-region internal proxy Network Load Balancers support Instance Groups (Managed or Unmanaged), zonal NEGs (`GCE_VM_IP_PORT`), and Hybrid NEGs as backends.
>
> Proxy-only subnets for cross-region load balancers must be created with the purpose set to `GLOBAL_MANAGED_PROXY` (in the VPC module, set `global = true` in the `subnets_proxy_only` configuration).

## Examples

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Minimal Example](#minimal-example)
  - [Health Checks](#health-checks)
  - [Network Endpoint Groups (NEGs)](#network-endpoint-groups-negs)
    - [Zonal NEG creation](#zonal-neg-creation)
    - [Hybrid NEG creation](#hybrid-neg-creation)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

### Minimal Example

An internal TCP proxy cross-region load balancer with a backend service pointing to auto-created zonal NEGs. This example demonstrates the use of the [context pattern](../../adrs/20251013-context-locals.md) for symbolic variable interpolation:

```hcl
module "tcp-proxy-cross-region" {
  source     = "./fabric/modules/net-lb-proxy-int-cross-region"
  name       = "ilb-proxy-test"
  project_id = "$project_ids:my-project"
  port       = 80

  context = {
    project_ids = {
      my-project = var.project_id
    }
    networks = {
      my-vpc = var.vpc.self_link
    }
    subnets = {
      my-subnet-1 = var.subnet1.self_link
      my-subnet-2 = var.subnet2.self_link
    }
  }

  vpc_config = {
    network = "$networks:my-vpc"
    subnetworks = {
      europe-west1 = "$subnets:my-subnet-1"
      europe-west4 = "$subnets:my-subnet-2"
    }
  }

  neg_configs = {
    neg-a = {
      gce = {
        zone       = "europe-west1-b"
        network    = "$networks:my-vpc"
        subnetwork = "$subnets:my-subnet-1"
        endpoints = {
          vm-a = {
            instance   = "my-vm-a"
            ip_address = "10.0.0.2"
            port       = 80
          }
        }
      }
    }
    neg-b = {
      gce = {
        zone       = "europe-west4-a"
        network    = "$networks:my-vpc"
        subnetwork = "$subnets:my-subnet-2"
        endpoints = {
          vm-b = {
            instance   = "my-vm-b"
            ip_address = "10.0.1.2"
            port       = 80
          }
        }
      }
    }
  }

  backend_service_config = {
    backends = [
      {
        group = "neg-a"
        max_connections = {
          per_endpoint = 100
        }
      },
      {
        group = "neg-b"
        max_connections = {
          per_endpoint = 100
        }
      }
    ]
  }
}
# tftest modules=1 resources=9
```

### Health Checks

You can leverage externally defined health checks for backend services, or have the module create them for you. By default a simple TCP health check is created, and used in backend services.

Defining a custom health check:

```hcl
module "tcp-proxy-cross-region" {
  source     = "./fabric/modules/net-lb-proxy-int-cross-region"
  name       = "ilb-proxy-test"
  project_id = var.project_id
  port       = 80

  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
    }
  }

  backend_service_config = {
    backends = [{
      group = "projects/my-project/zones/europe-west1-b/networkEndpointGroups/my-neg"
      max_connections = {
        per_endpoint = 100
      }
    }]
  }

  health_check_config = {
    tcp = {
      port = 8080
    }
  }
}
# tftest modules=1 resources=4
```

### Network Endpoint Groups (NEGs)

#### Zonal NEG creation

You can have the module create zonal NEGs for you by defining the `neg_configs` variable:

```hcl
module "tcp-proxy-cross-region" {
  source     = "./fabric/modules/net-lb-proxy-int-cross-region"
  name       = "ilb-proxy-test"
  project_id = var.project_id
  port       = 80

  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
    }
  }

  neg_configs = {
    neg-a = {
      gce = {
        zone       = "europe-west1-b"
        network    = var.vpc.self_link
        subnetwork = var.subnet1.self_link
      }
    }
  }

  backend_service_config = {
    backends = [{
      group = "neg-a"
      max_connections = {
        per_endpoint = 100
      }
    }]
  }
}
# tftest modules=1 resources=5
```

#### Hybrid NEG creation

You can also configure hybrid NEGs:

```hcl
module "tcp-proxy-cross-region" {
  source     = "./fabric/modules/net-lb-proxy-int-cross-region"
  name       = "ilb-proxy-test"
  project_id = var.project_id
  port       = 80

  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
    }
  }

  neg_configs = {
    hybrid-a = {
      hybrid = {
        network = var.vpc.self_link
        zone    = "europe-west1-b"
        endpoints = {
          endpoint-1 = {
            ip_address = "10.10.10.1"
            port       = 80
          }
        }
      }
    }
  }

  backend_service_config = {
    backends = [{
      group = "hybrid-a"
      max_connections = {
        per_endpoint = 100
      }
    }]
  }
}
# tftest modules=1 resources=6
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L204) | Load balancer name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L258) | Project id. | <code>string</code> | ✓ |  |
| [vpc_config](variables.tf#L274) | VPC-level configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [addresses](variables.tf#L17) | Optional IP addresses used for the forwarding rules, mapped by subnetwork key. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [backend_service_config](variables.tf#L23) | Backend service level configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L72) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L85) | Optional description used for resources. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [group_configs](variables.tf#L91) | Optional unmanaged groups to create. Can be referenced in backends via key or outputs. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_check](variables.tf#L105) | Name of existing health check to use, disables auto-created health check. | <code>string</code> |  | <code>null</code> |
| [health_check_config](variables.tf#L111) | Optional auto-created health check configurations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [labels](variables.tf#L198) | Labels set on resources. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [neg_configs](variables.tf#L209) | Optional network endpoint groups to create. Can be referenced in backends via key or outputs. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [port](variables.tf#L252) | Forwarding rule port. Cross-region internal proxy load balancers support a single port. | <code>number</code> |  | <code>80</code> |
| [target_proxy_config](variables.tf#L263) | Target proxy configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [addresses](outputs.tf#L17) | Forwarding rule addresses. |  |
| [backend_service](outputs.tf#L22) | Backend resource. |  |
| [backend_service_id](outputs.tf#L27) | Backend id. |  |
| [backend_service_self_link](outputs.tf#L32) | Backend self link. |  |
| [forwarding_rules](outputs.tf#L37) | Forwarding rule resources. |  |
| [group_self_links](outputs.tf#L42) | Optional unmanaged instance group self links. |  |
| [groups](outputs.tf#L49) | Optional unmanaged instance group resources. |  |
| [health_check](outputs.tf#L54) | Auto-created health-check resource. |  |
| [health_check_id](outputs.tf#L59) | Auto-created health-check id. |  |
| [health_check_self_link](outputs.tf#L64) | Auto-created health-check self link. |  |
| [ids](outputs.tf#L69) | Fully qualified forwarding rule ids. |  |
| [neg_ids](outputs.tf#L74) | Autogenerated network endpoint group ids. |  |
| [psc_neg_ids](outputs.tf#L81) | Autogenerated PSC network endpoint group ids. |  |
| [target_proxy](outputs.tf#L88) | Target proxy resource. |  |
| [target_proxy_id](outputs.tf#L93) | Target proxy id. |  |
<!-- END TFDOC -->
