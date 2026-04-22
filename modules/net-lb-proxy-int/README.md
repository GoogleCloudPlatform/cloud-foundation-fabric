# Internal Proxy Network Load Balancer Module

This module allows managing Internal HTTP/HTTPS Load Balancers (L7 ILBs). It's designed to expose the full configuration of the underlying resources, and to facilitate common usage patterns by providing sensible defaults, and optionally managing prerequisite resources like health checks, instance groups, etc.

Due to the complexity of the underlying resources, changes to the configuration that involve recreation of resources are best applied in stages, starting by disabling the configuration in the urlmap that references the resources that need recreation, then doing the same for the backend service, etc.

## Examples

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Minimal Example](#minimal-example)
  - [Health Checks](#health-checks)
  - [Instance Groups](#instance-groups)
  - [Network Endpoint Groups (NEGs)](#network-endpoint-groups-negs)
    - [Zonal NEG creation](#zonal-neg-creation)
    - [Hybrid NEG creation](#hybrid-neg-creation)
    - [Private Service Connect NEG creation](#private-service-connect-neg-creation)
    - [Internet NEG creation](#internet-neg-creation)
- [Deploying changes to load balancer configurations](#deploying-changes-to-load-balancer-configurations)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

### Minimal Example

An Regional internal proxy Network Load Balancer with a backend service pointing to an existing GCE instance group:

```hcl
module "tcp-proxy" {
  source     = "./fabric/modules/net-lb-proxy-int"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_config = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
    }]
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=4
```

### Health Checks

You can leverage externally defined health checks for backend services, or have the module create them for you. By default a simple TCP health check on port 80 is created, and used in backend services.

Health check configuration is controlled via the `health_check_config` variable, which behaves in a similar way to other LB modules in this repository.

```hcl
module "int-tcp-proxy" {
  source     = "./fabric/modules/net-lb-proxy-int"
  name       = "int-tcp-proxy"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_config = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
    }]
  }
  health_check_config = {
    tcp = { port = 80 }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=4
```

To leverage an existing health check without having the module create them, simply pass its self link:

```hcl
module "int-tcp-proxy" {
  source     = "./fabric/modules/net-lb-proxy-int"
  name       = "int-tcp-proxy"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_config = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
    }]
  }
  health_check = "projects/myprj/global/healthChecks/custom"
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=3
```

### Instance Groups

The module can optionally create unmanaged instance groups, which can then be referred in backends via their key:

```hcl
module "int-tcp-proxy" {
  source     = "./fabric/modules/net-lb-proxy-int"
  name       = "int-tcp-proxy"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_config = {
    port_name = "http"
    backends = [
      { group = "default" }
    ]
  }
  group_configs = {
    default = {
      zone = "europe-west1-b"
      instances = [
        "projects/myprj/zones/europe-west1-b/instances/vm-a"
      ]
      named_ports = { http = 80 }
    }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=5
```

### Network Endpoint Groups (NEGs)

Network Endpoint Groups (NEGs) can be used as backends, by passing their id as the backend group:

```hcl
module "int-tcp-proxy" {
  source     = "./fabric/modules/net-lb-proxy-int"
  name       = "int-tcp-proxy"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_config = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/networkEndpointGroups/my-neg"
    }]
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=4
```

Similarly to instance groups, NEGs can also be managed by this module which supports GCE, hybrid and Private Service Connect NEGs:

#### Zonal NEG creation

```hcl
resource "google_compute_address" "test" {
  project      = var.project_id
  name         = "neg-test"
  subnetwork   = var.subnet.self_link
  address_type = "INTERNAL"
  address      = "10.0.0.10"
  region       = "europe-west1"
}

module "int-tcp-proxy" {
  source     = "./fabric/modules/net-lb-proxy-int"
  name       = "int-tcp-proxy"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_config = {
    backends = [{
      group          = "my-neg"
      balancing_mode = "CONNECTION"
      max_connections = {
        per_endpoint = 10
      }
    }]
  }
  neg_configs = {
    my-neg = {
      gce = {
        zone = "europe-west1-b"
        endpoints = {
          e-0 = {
            instance   = "test-1"
            ip_address = google_compute_address.test.address
            # ip_address = "10.0.0.10"
            port = 80
          }
        }
      }
    }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=7 inventory=zonal-neg.yaml
```

#### Hybrid NEG creation

```hcl
module "int-tcp-proxy" {
  source     = "./fabric/modules/net-lb-proxy-int"
  name       = "int-tcp-proxy"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_config = {
    backends = [{
      group          = "my-neg"
      balancing_mode = "CONNECTION"
      max_connections = {
        per_endpoint = 10
      }
    }]
  }
  neg_configs = {
    my-neg = {
      hybrid = {
        zone = "europe-west1-b"
        endpoints = {
          e-0 = {
            ip_address = "10.0.0.10"
            port       = 80
          }
        }
      }
    }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=6
```

#### Private Service Connect NEG creation

```hcl
module "int-tcp-proxy" {
  source     = "./fabric/modules/net-lb-proxy-int"
  name       = "int-tcp-proxy"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_config = {
    backends = [{
      group          = "my-neg"
      balancing_mode = "CONNECTION"
      max_connections = {
        per_endpoint = 10
      }
    }]
  }
  neg_configs = {
    my-neg = {
      psc = {
        region         = "europe-west1"
        target_service = "europe-west1-cloudkms.googleapis.com"
      }
    }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=5
```

#### Internet NEG creation

This example shows how to create and manage internet NEGs:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-proxy-int"
  project_id = var.project_id
  name       = "ilb-test"
  region     = var.region
  backend_service_config = {
    backends = [
      { group = "neg-0" }
    ]
    # with a single internet NEG the implied default health check is optional
    health_checks = []
  }
  port = 80
  neg_configs = {
    neg-0 = {
      internet = {
        region   = var.region
        use_fqdn = true
        endpoints = {
          e-0 = {
            destination = "www.example.org"
            port        = 80
          }
        }
      }
    }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=6 inventory=internet-neg.yaml e2e
```

## Deploying changes to load balancer configurations
For deploying changes to load balancer configuration please refer to [net-lb-app-ext README.md](../net-lb-app-ext/README.md#deploying-changes-to-load-balancer-configurations)

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | resources |
|---|---|---|
| [backend-service.tf](./backend-service.tf) | Backend service resources. | <code>google_compute_region_backend_service</code> |
| [groups.tf](./groups.tf) | None | <code>google_compute_instance_group</code> |
| [health-check.tf](./health-check.tf) | Health check resource. | <code>google_compute_region_health_check</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_compute_forwarding_rule</code> · <code>google_compute_network_endpoint</code> · <code>google_compute_network_endpoint_group</code> · <code>google_compute_region_network_endpoint</code> · <code>google_compute_region_network_endpoint_group</code> · <code>google_compute_region_target_tcp_proxy</code> · <code>google_compute_service_attachment</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L203) | Load balancer name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L272) | Project id. | <code>string</code> | ✓ |  |
| [region](variables.tf#L277) | The region where to allocate the ILB resources. | <code>string</code> | ✓ |  |
| [vpc_config](variables.tf#L297) | VPC-level configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [address](variables.tf#L17) | Optional IP address used for the forwarding rule. | <code>string</code> |  | <code>null</code> |
| [backend_service_config](variables.tf#L23) | Backend service level configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L77) | Optional description used for resources. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [global_access](variables.tf#L84) | Allow client access from all regions. | <code>bool</code> |  | <code>null</code> |
| [group_configs](variables.tf#L90) | Optional unmanaged groups to create. Can be referenced in backends via key or outputs. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_check](variables.tf#L104) | Name of existing health check to use, disables auto-created health check. | <code>string</code> |  | <code>null</code> |
| [health_check_config](variables.tf#L110) | Optional auto-created health check configurations, use the output self-link to set it in the auto healing policy. Refer to examples for usage. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [labels](variables.tf#L197) | Labels set on resources. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [neg_configs](variables.tf#L208) | Optional network endpoint groups to create. Can be referenced in backends via key or outputs. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [port](variables.tf#L266) | Port. | <code>number</code> |  | <code>80</code> |
| [service_attachment](variables.tf#L282) | PSC service attachment. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [address](outputs.tf#L17) | Forwarding rule address. |  |
| [backend_service](outputs.tf#L22) | Backend resource. |  |
| [backend_service_id](outputs.tf#L27) | Backend id. |  |
| [backend_service_self_link](outputs.tf#L32) | Backend self link. |  |
| [forwarding_rule](outputs.tf#L37) | Forwarding rule resource. |  |
| [group_self_links](outputs.tf#L42) | Optional unmanaged instance group self links. |  |
| [groups](outputs.tf#L49) | Optional unmanaged instance group resources. |  |
| [health_check](outputs.tf#L54) | Auto-created health-check resource. |  |
| [health_check_id](outputs.tf#L59) | Auto-created health-check id. |  |
| [health_check_self_link](outputs.tf#L64) | Auto-created health-check self link. |  |
| [id](outputs.tf#L69) | Fully qualified forwarding rule id. |  |
| [neg_ids](outputs.tf#L74) | Autogenerated network endpoint group ids. |  |
| [service_attachment_id](outputs.tf#L81) | Id of the service attachment. |  |
<!-- END TFDOC -->
