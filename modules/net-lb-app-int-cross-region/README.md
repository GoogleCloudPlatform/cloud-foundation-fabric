# Cross-region Internal Application Load Balancer Module

This module allows managing Cross-regional Internal HTTP/HTTPS Load Balancers (L7 ILBs). It's designed to expose the full configuration of the underlying resources, and to facilitate common usage patterns by providing sensible defaults, and optionally managing prerequisite resources like health checks, instance groups, etc.

Due to the complexity of the underlying resources, changes to the configuration that involve recreation of resources are best applied in stages, starting by disabling the configuration in the urlmap that references the resources that need recreation, then doing the same for the backend service, etc.

## Examples

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Minimal Example](#minimal-example)
  - [Cross-project backend services](#cross-project-backend-services)
  - [Health Checks](#health-checks)
  - [Instance Groups](#instance-groups)
  - [Network Endpoint Groups (NEGs)](#network-endpoint-groups-negs)
    - [Zonal NEG creation](#zonal-neg-creation)
    - [Hybrid NEG creation](#hybrid-neg-creation)
    - [Serverless NEG creation](#serverless-neg-creation)
    - [Private Service Connect NEG creation](#private-service-connect-neg-creation)
  - [URL Map](#url-map)
  - [PSC service attachment](#psc-service-attachment)
  - [Complex example](#complex-example)
- [Deploying changes to load balancer configurations](#deploying-changes-to-load-balancer-configurations)
- [Recipes](#recipes)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
- [Fixtures](#fixtures)
<!-- END TOC -->

### Minimal Example

An HTTP ILB with a backend service pointing to a GCE instance group:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = var.project_id
  backend_service_configs = {
    default = {
      backends = [{
        group = module.compute-mig.group_manager.instance_group
      }]
    }
  }
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      (var.region) = var.subnet.self_link
    }
  }
}
# tftest modules=3 resources=7 fixtures=fixtures/compute-mig.tf e2e
```

An HTTPS ILB needs a few additional fields:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = var.project_id
  backend_service_configs = {
    default = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig-ew1"
        }, {
        group = "projects/myprj/zones/europe-west4-a/instanceGroups/my-ig-ew4"
      }]
    }
  }
  protocol = "HTTPS"
  https_proxy_config = {
    certificate_manager_certificates = [
      "projects/myprj/locations/global/certificates/certificate"
    ]
  }
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
      europe-west4 = var.subnet2.self_link
    }
  }
}
# tftest modules=1 resources=6
```

### Cross-project backend services

When using Shared VPC, this module also allows configuring [cross-project backend services](https://cloud.google.com/load-balancing/docs/l7-internal/l7-internal-shared-vpc#cross-project):

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = "prj-host"
  backend_service_configs = {
    default = {
      project_id = "prj-svc"
      backends = [{
        group = "projects/prj-svc/zones/europe-west1-a/instanceGroups/my-ig-ew1"
        }, {
        group = "projects/prj-svc/zones/europe-west4-a/instanceGroups/my-ig-ew4"
      }]
    }
  }
  health_check_configs = {
    default = {
      project_id = "prj-svc"
      http = {
        port_specification = "USE_SERVING_PORT"
      }
    }
  }
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
      europe-west4 = var.subnet2.self_link
    }
  }
}
# tftest modules=1 resources=6
```

### Health Checks

You can leverage externally defined health checks for backend services, or have the module create them for you. By default a simple HTTP health check is created, and used in backend services.

Health check configuration is controlled via the `health_check_configs` variable, which behaves in a similar way to other LB modules in this repository.

Defining different health checks from the default is very easy. You can for example replace the default HTTP health check with a TCP one and reference it in you backend service:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = var.project_id
  backend_service_configs = {
    default = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig-ew1"
        }, {
        group = "projects/myprj/zones/europe-west4-a/instanceGroups/my-ig-ew4"
      }]
      health_checks = ["custom-tcp"]
    }
  }
  health_check_configs = {
    custom-tcp = {
      tcp = { port = 80 }
    }
  }
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
      europe-west4 = var.subnet2.self_link
    }
  }
}
# tftest modules=1 resources=6
```

To leverage existing health checks without having the module create them, simply pass their self links to backend services and set the `health_check_configs` variable to an empty map:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = var.project_id
  backend_service_configs = {
    default = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig-ew1"
        }, {
        group = "projects/myprj/zones/europe-west4-a/instanceGroups/my-ig-ew4"
      }]
      health_checks = ["projects/myprj/global/healthChecks/custom"]
    }
  }
  health_check_configs = {}
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
      europe-west4 = var.subnet2.self_link
    }
  }
}
# tftest modules=1 resources=5
```

### Instance Groups

The module can optionally create unmanaged instance groups, which can then be referred to in backends via their key:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = var.project_id
  backend_service_configs = {
    default = {
      port_name = "http"
      backends = [
        { group = "europe-west1" },
        { group = "europe-west4" },
      ]
    }
  }
  group_configs = {
    europe-west1 = {
      zone = "europe-west1-b"
      instances = [
        "projects/myprj/zones/europe-west1-b/instances/vm-a"
      ]
      named_ports = { http = 80 }
    }
    europe-west4 = {
      zone = "europe-west4-a"
      instances = [
        "projects/myprj/zones/europe-west1-b/instances/vm-b"
      ]
      named_ports = { http = 80 }
    }
  }
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
      europe-west4 = var.subnet2.self_link
    }
  }
}
# tftest modules=1 resources=8
```

### Network Endpoint Groups (NEGs)

Network Endpoint Groups (NEGs) can be used as backends, by passing their id as the backend group in a backends service configuration:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = var.project_id
  backend_service_configs = {
    default = {
      backends = [{
        balancing_mode = "RATE"
        group          = "projects/myprj/zones/europe-west1-a/networkEndpointGroups/my-neg-ew1"
        max_rate = {
          per_endpoint = 1
        }
        }, {
        balancing_mode = "RATE"
        group          = "projects/myprj/zones/europe-west4-a/networkEndpointGroups/my-neg-ew4"
        max_rate = {
          per_endpoint = 1
        }
      }]
    }
  }
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
      europe-west4 = var.subnet2.self_link
    }
  }
}
# tftest modules=1 resources=6
```

Similarly to instance groups, NEGs can also be managed by this module which supports GCE, hybrid, serverless and Private Service Connect NEGs:

#### Zonal NEG creation

```hcl
resource "google_compute_address" "address_ew1" {
  project      = var.project_id
  name         = "neg-test-ew1"
  subnetwork   = var.subnet1.self_link
  address_type = "INTERNAL"
  address      = "10.0.0.10"
  region       = "europe-west1"
}

resource "google_compute_address" "address_ew4" {
  project      = var.project_id
  name         = "neg-test-ew4"
  subnetwork   = var.subnet2.self_link
  address_type = "INTERNAL"
  address      = "10.0.0.11"
  region       = "europe-west4"
}

module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = var.project_id
  backend_service_configs = {
    default = {
      backends = [{
        balancing_mode = "RATE"
        group          = "my-neg-ew1"
        max_rate = {
          per_endpoint = 1
        }
        }, {
        balancing_mode = "RATE"
        group          = "my-neg-ew4"
        max_rate = {
          per_endpoint = 1
        }
      }]
    }
  }
  neg_configs = {
    my-neg-ew1 = {
      gce = {
        zone = "europe-west1-b"
        endpoints = {
          e-0 = {
            instance   = "test-ew1"
            ip_address = google_compute_address.address_ew1.address
            port       = 80
          }
        }
      }
    }
    my-neg-ew4 = {
      gce = {
        zone = "europe-west4-b"
        endpoints = {
          e-0 = {
            instance   = "test-ew4"
            ip_address = google_compute_address.address_ew4.address
            port       = 80
          }
        }
      }
    }
  }
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
      europe-west4 = var.subnet2.self_link
    }
  }
}
# tftest modules=1 resources=12 inventory=zonal-neg.yaml
```

#### Hybrid NEG creation

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = var.project_id
  backend_service_configs = {
    default = {
      backends = [{
        balancing_mode = "RATE"
        group          = "neg-ew1"
        max_rate = {
          per_endpoint = 1
        }
        }, {
        balancing_mode = "RATE"
        group          = "neg-ew4"
        max_rate = {
          per_endpoint = 1
        }
      }]
    }
  }
  neg_configs = {
    neg-ew1 = {
      hybrid = {
        zone = "europe-west1-b"
        endpoints = {
          e-0-ew1 = {
            ip_address = "10.0.0.10"
            port       = 80
          }
        }
      }
    }
    neg-ew4 = {
      hybrid = {
        zone = "europe-west4-b"
        endpoints = {
          e-0-ew4 = {
            ip_address = "10.0.0.20"
            port       = 80
          }
        }
      }
    }
  }
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
      europe-west4 = var.subnet1.self_link
    }
  }
}
# tftest modules=1 resources=10
```

#### Serverless NEG creation

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = var.project_id
  backend_service_configs = {
    default = {
      backends = [{
        group = "neg-ew1"
        }, {
        group = "neg-ew4"
      }]
      health_checks = []
    }
  }
  health_check_configs = {}
  neg_configs = {
    neg-ew1 = {
      cloudrun = {
        region = "europe-west1"
        target_service = {
          name = "my-run-service-ew1"
        }
      }
    }
    neg-ew4 = {
      cloudrun = {
        region = "europe-west4"
        target_service = {
          name = "my-run-service-ew4"
        }
      }
    }
  }
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
      europe-west4 = var.subnet2.self_link
    }
  }
}
# tftest modules=1 resources=7
```

#### Private Service Connect NEG creation

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = var.project_id
  backend_service_configs = {
    default = {
      backends = [{
        group = "neg-ew1"
        }, {
        group = "neg-ew4"
      }]
      health_checks = []
    }
  }
  health_check_configs = {}
  neg_configs = {
    neg-ew1 = {
      psc = {
        region         = "europe-west1"
        target_service = "europe-west1-cloudkms.googleapis.com"
      }
    }
    neg-ew4 = {
      psc = {
        region         = "europe-west4"
        target_service = "europe-west4-cloudkms.googleapis.com"
      }
    }
  }
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
      europe-west4 = var.subnet2.self_link
    }
  }
}
# tftest modules=1 resources=7
```

### URL Map

The module exposes the full URL map resource configuration, with some minor changes to the interface to decrease verbosity, and support for aliasing backend services via keys.

The default URL map configuration sets the `default` backend service as the default service for the load balancer as a convenience. Just override the `urlmap_config` variable to change the default behaviour:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = var.project_id
  backend_service_configs = {
    default = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig-1-ew1"
        }, {
        group = "projects/myprj/zones/europe-west4-a/instanceGroups/my-ig-1-ew4"
      }]
    }
    video = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig-2-ew1"
        }, {
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig-2-ew4"
      }]
    }
  }
  urlmap_config = {
    default_service = "default"
    host_rules = [{
      hosts        = ["*"]
      path_matcher = "pathmap"
    }]
    path_matchers = {
      pathmap = {
        default_service = "default"
        path_rules = [{
          paths   = ["/video", "/video/*"]
          service = "video"
        }]
      }
    }
  }
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
      europe-west4 = var.subnet2.self_link
    }
  }
}
# tftest modules=1 resources=7
```

### PSC service attachment
The optional `service_attachment` variable allows [publishing Private Service Connect service](https://cloud.google.com/vpc/docs/configure-private-service-connect-producer) by configuring service attachment for all forwarding rules in every configured region.

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = var.project_id
  backend_service_configs = {
    default = {
      backends = [{
        group = "neg-ew1"
        }, {
        group = "neg-ew4"
      }]
      health_checks = []
    }
  }
  health_check_configs = {}
  neg_configs = {
    neg-ew1 = {
      cloudrun = {
        region = "europe-west1"
        target_service = {
          name = "my-run-service-ew1"
        }
      }
    }
    neg-ew4 = {
      cloudrun = {
        region = "europe-west4"
        target_service = {
          name = "my-run-service-ew4"
        }
      }
    }
  }
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      europe-west1 = var.subnet1.self_link
      europe-west4 = var.subnet2.self_link
    }
  }

  service_attachment = {
    nat_subnets = {
      europe-west1 = [var.subnet_psc_1.self_link]
      europe-west4 = [var.subnet_psc_2.self_link]
    }
    reconcile_connections = false
    consumer_accept_lists = {
      # map of `project_id` => `connection_limit`
      (var.project_id) = 10
    }
    domain_name = {
      europe-west1 = "ew1.p.example.com."
      europe-west4 = "ew4.p.example.com."
    }
  }
}
# tftest modules=1 resources=9
```


### Complex example

This example mixes group and NEG backends, and shows how to set HTTPS for specific backends.

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-l7-test-0"
  project_id = "prj-gce"
  backend_service_configs = {
    default = {
      backends = [
        { group = "nginx-ew1" },
        { group = "nginx-ew4" },
      ]
    }
    gce-neg = {
      backends = [{
        balancing_mode = "RATE"
        group          = "neg-nginx-ew1"
        max_rate = {
          per_endpoint = 1
        }
        }, {
        balancing_mode = "RATE"
        group          = "neg-nginx-ew4"
        max_rate = {
          per_endpoint = 1
        }
      }]
    }
    home = {
      backends = [{
        balancing_mode = "RATE"
        group          = "neg-home-hello-ew1"
        max_rate = {
          per_endpoint = 1
        }
        }, {
        balancing_mode = "RATE"
        group          = "neg-home-hello-ew4"
        max_rate = {
          per_endpoint = 1
        }
      }]
      health_checks      = ["neg"]
      locality_lb_policy = "ROUND_ROBIN"
      protocol           = "HTTPS"
    }
  }
  group_configs = {
    nginx-ew1 = {
      zone = "europe-west1-b"
      instances = [
        "projects/prj-gce/zones/europe-west1-b/instances/nginx-ew1"
      ]
      named_ports = { http = 80 }
    }
    nginx-ew4 = {
      zone = "europe-west4-b"
      instances = [
        "projects/prj-gce/zones/europe-west4-b/instances/nginx-ew4"
      ]
      named_ports = { http = 80 }
    }
  }
  health_check_configs = {
    default = {
      http = {
        port = 80
      }
    }
    neg = {
      https = {
        host = "hello.home.example.com"
        port = 443
      }
    }
  }
  neg_configs = {
    neg-nginx-ew1 = {
      gce = {
        zone = "europe-west1-c"
        endpoints = {
          e-0 = {
            instance   = "nginx-ew1-c"
            ip_address = "10.24.32.26"
            port       = 80
          }
        }
      }
    }
    neg-nginx-ew4 = {
      gce = {
        zone = "europe-west4-c"
        endpoints = {
          e-0 = {
            instance   = "nginx-ew4-c"
            ip_address = "10.34.32.26"
            port       = 80
          }
        }
      }
    }
    neg-home-hello-ew1 = {
      hybrid = {
        zone = "europe-west1-b"
        endpoints = {
          e-0 = {
            ip_address = "192.168.0.3"
            port       = 443
          }
        }
      }
    }
    neg-home-hello-ew4 = {
      hybrid = {
        zone = "europe-west4-b"
        endpoints = {
          e-0 = {
            ip_address = "192.168.1.3"
            port       = 443
          }
        }
      }
    }
  }
  urlmap_config = {
    default_service = "default"
    host_rules = [
      {
        hosts        = ["*"]
        path_matcher = "gce"
      },
      {
        hosts        = ["hello.home.example.com"]
        path_matcher = "home"
      }
    ]
    path_matchers = {
      gce = {
        default_service = "default"
        path_rules = [
          {
            paths   = ["/gce-neg", "/gce-neg/*"]
            service = "gce-neg"
          }
        ]
      }
      home = {
        default_service = "home"
      }
    }
  }
  vpc_config = {
    network = "projects/prj-host/global/networks/shared-vpc"
    subnetworks = {
      europe-west1 = var.subnet1.self_link
      europe-west4 = var.subnet2.self_link
    }
  }
}
# tftest modules=1 resources=19
```

## Deploying changes to load balancer configurations

When deploying changes to load balancer configuration please refer to [net-lb-app-ext README.md](../net-lb-app-ext/README.md#deploying-changes-to-load-balancer-configurations)

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Recipes

- [Cross-region internal Application Load Balancer with VM instance group backends](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master/modules/net-lb-app-int-cross-region/recipe-cross-reg-int-app-lb-vm-dns)

## Files

| name | description | resources |
|---|---|---|
| [backend-service.tf](./backend-service.tf) | Backend service resources. | <code>google_compute_backend_service</code> |
| [groups.tf](./groups.tf) | None | <code>google_compute_instance_group</code> |
| [health-check.tf](./health-check.tf) | Health check resource. | <code>google_compute_health_check</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_compute_global_forwarding_rule</code> · <code>google_compute_network_endpoint</code> · <code>google_compute_network_endpoint_group</code> · <code>google_compute_region_network_endpoint_group</code> · <code>google_compute_service_attachment</code> · <code>google_compute_target_http_proxy</code> · <code>google_compute_target_https_proxy</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [urlmap.tf](./urlmap.tf) | URL map resources. | <code>google_compute_url_map</code> |
| [variables-backend-service.tf](./variables-backend-service.tf) | Backend services variables. |  |
| [variables-health-check.tf](./variables-health-check.tf) | Health check variable. |  |
| [variables-urlmap.tf](./variables-urlmap.tf) | URLmap variable. |  |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L74) | Load balancer name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L155) | Project id. | <code>string</code> | ✓ |  |
| [vpc_config](variables.tf#L197) | VPC-level configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [addresses](variables.tf#L17) | Optional IP address used for the forwarding rule. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [backend_service_configs](variables-backend-service.tf#L19) | Backend service level configuration. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L23) | Optional description used for resources. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [group_configs](variables.tf#L29) | Optional unmanaged groups to create. Can be referenced in backends via key or outputs. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_check_configs](variables-health-check.tf#L19) | Optional auto-created health check configurations, use the output self-link to set it in the auto healing policy. Refer to examples for usage. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [http_proxy_config](variables.tf#L43) | HTTP proxy configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [https_proxy_config](variables.tf#L54) | HTTPS proxy configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L68) | Labels set on resources. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [neg_configs](variables.tf#L79) | Optional network endpoint groups to create. Can be referenced in backends via key or outputs. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ports](variables.tf#L145) | Optional ports for HTTP load balancer. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [protocol](variables.tf#L160) | Protocol supported by this load balancer. | <code>string</code> |  | <code>&#34;HTTP&#34;</code> |
| [service_attachment](variables.tf#L173) | PSC service attachments. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [service_directory_registration](variables.tf#L188) | Service directory namespace and service used to register this load balancer. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [urlmap_config](variables-urlmap.tf#L19) | The URL map configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [addresses](outputs.tf#L17) | Forwarding rule address. |  |
| [backend_service_ids](outputs.tf#L22) | Backend service resources. |  |
| [backend_service_names](outputs.tf#L29) | Backend service resource names. |  |
| [forwarding_rules](outputs.tf#L36) | Forwarding rule resource. |  |
| [group_ids](outputs.tf#L41) | Autogenerated instance group ids. |  |
| [health_check_ids](outputs.tf#L48) | Autogenerated health check ids. |  |
| [ids](outputs.tf#L55) | Fully qualified forwarding rule ids. |  |
| [neg_ids](outputs.tf#L61) | Autogenerated network endpoint group ids. |  |
| [psc_neg_ids](outputs.tf#L68) | Autogenerated PSC network endpoint group ids. |  |
| [regional_neg_ids](outputs.tf#L75) | Autogenerated regional network endpoint group ids. |  |
| [url_map_id](outputs.tf#L82) | Fully qualified URL map ID (resource path) for use in IAM conditions and API calls. |  |

## Fixtures

- [compute-mig.tf](../../tests/fixtures/compute-mig.tf)
<!-- END TFDOC -->
