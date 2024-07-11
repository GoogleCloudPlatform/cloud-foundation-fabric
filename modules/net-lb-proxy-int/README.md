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
| [name](variables.tf#L198) | Load balancer name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L267) | Project id. | <code>string</code> | ✓ |  |
| [region](variables.tf#L272) | The region where to allocate the ILB resources. | <code>string</code> | ✓ |  |
| [vpc_config](variables.tf#L292) | VPC-level configuration. | <code title="object&#40;&#123;&#10;  network    &#61; string&#10;  subnetwork &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [address](variables.tf#L17) | Optional IP address used for the forwarding rule. | <code>string</code> |  | <code>null</code> |
| [backend_service_config](variables.tf#L23) | Backend service level configuration. | <code title="object&#40;&#123;&#10;  affinity_cookie_ttl_sec         &#61; optional&#40;number&#41;&#10;  connection_draining_timeout_sec &#61; optional&#40;number&#41;&#10;  health_checks                   &#61; optional&#40;list&#40;string&#41;, &#91;&#34;default&#34;&#93;&#41;&#10;  log_sample_rate                 &#61; optional&#40;number&#41;&#10;  port_name                       &#61; optional&#40;string&#41;&#10;  project_id                      &#61; optional&#40;string&#41;&#10;  session_affinity                &#61; optional&#40;string, &#34;NONE&#34;&#41;&#10;  timeout_sec                     &#61; optional&#40;number&#41;&#10;  backends &#61; optional&#40;list&#40;object&#40;&#123;&#10;    group           &#61; string&#10;    balancing_mode  &#61; optional&#40;string, &#34;UTILIZATION&#34;&#41;&#10;    capacity_scaler &#61; optional&#40;number, 1&#41;&#10;    description     &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;    failover        &#61; optional&#40;bool, false&#41;&#10;    max_connections &#61; optional&#40;object&#40;&#123;&#10;      per_endpoint &#61; optional&#40;number&#41;&#10;      per_group    &#61; optional&#40;number&#41;&#10;      per_instance &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    max_utilization &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  connection_tracking &#61; optional&#40;object&#40;&#123;&#10;    idle_timeout_sec          &#61; optional&#40;number&#41;&#10;    persist_conn_on_unhealthy &#61; optional&#40;string&#41;&#10;    track_per_session         &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  failover_config &#61; optional&#40;object&#40;&#123;&#10;    disable_conn_drain        &#61; optional&#40;bool&#41;&#10;    drop_traffic_if_unhealthy &#61; optional&#40;bool&#41;&#10;    ratio                     &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L75) | Optional description used for resources. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [global_access](variables.tf#L82) | Allow client access from all regions. | <code>bool</code> |  | <code>null</code> |
| [group_configs](variables.tf#L88) | Optional unmanaged groups to create. Can be referenced in backends via key or outputs. | <code title="map&#40;object&#40;&#123;&#10;  zone        &#61; string&#10;  instances   &#61; optional&#40;list&#40;string&#41;&#41;&#10;  named_ports &#61; optional&#40;map&#40;number&#41;, &#123;&#125;&#41;&#10;  project_id  &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_check](variables.tf#L100) | Name of existing health check to use, disables auto-created health check. | <code>string</code> |  | <code>null</code> |
| [health_check_config](variables.tf#L106) | Optional auto-created health check configurations, use the output self-link to set it in the auto healing policy. Refer to examples for usage. | <code title="object&#40;&#123;&#10;  check_interval_sec  &#61; optional&#40;number&#41;&#10;  description         &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  enable_logging      &#61; optional&#40;bool, false&#41;&#10;  healthy_threshold   &#61; optional&#40;number&#41;&#10;  project_id          &#61; optional&#40;string&#41;&#10;  timeout_sec         &#61; optional&#40;number&#41;&#10;  unhealthy_threshold &#61; optional&#40;number&#41;&#10;  grpc &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    service_name       &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  http &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  http2 &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  https &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  tcp &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request            &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  ssl &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request            &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  tcp &#61; &#123;&#10;    port_specification &#61; &#34;USE_SERVING_PORT&#34;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [labels](variables.tf#L192) | Labels set on resources. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [neg_configs](variables.tf#L203) | Optional network endpoint groups to create. Can be referenced in backends via key or outputs. | <code title="map&#40;object&#40;&#123;&#10;  project_id &#61; optional&#40;string&#41;&#10;  gce &#61; optional&#40;object&#40;&#123;&#10;    zone &#61; string&#10;    network    &#61; optional&#40;string&#41;&#10;    subnetwork &#61; optional&#40;string&#41;&#10;    endpoints &#61; optional&#40;map&#40;object&#40;&#123;&#10;      instance   &#61; string&#10;      ip_address &#61; string&#10;      port       &#61; number&#10;    &#125;&#41;&#41;&#41;&#10;&#10;&#10;  &#125;&#41;&#41;&#10;  hybrid &#61; optional&#40;object&#40;&#123;&#10;    zone    &#61; string&#10;    network &#61; optional&#40;string&#41;&#10;    endpoints &#61; optional&#40;map&#40;object&#40;&#123;&#10;      ip_address &#61; string&#10;      port       &#61; number&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  internet &#61; optional&#40;object&#40;&#123;&#10;    region   &#61; string&#10;    use_fqdn &#61; optional&#40;bool, true&#41;&#10;    endpoints &#61; optional&#40;map&#40;object&#40;&#123;&#10;      destination &#61; string&#10;      port        &#61; number&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  psc &#61; optional&#40;object&#40;&#123;&#10;    region         &#61; string&#10;    target_service &#61; string&#10;    network        &#61; optional&#40;string&#41;&#10;    subnetwork     &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [port](variables.tf#L261) | Port. | <code>number</code> |  | <code>80</code> |
| [service_attachment](variables.tf#L277) | PSC service attachment. | <code title="object&#40;&#123;&#10;  nat_subnets           &#61; list&#40;string&#41;&#10;  automatic_connection  &#61; optional&#40;bool, false&#41;&#10;  consumer_accept_lists &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41; &#35; map of &#96;project_id&#96; &#61;&#62; &#96;connection_limit&#96;&#10;  consumer_reject_lists &#61; optional&#40;list&#40;string&#41;&#41;&#10;  description           &#61; optional&#40;string&#41;&#10;  domain_name           &#61; optional&#40;string&#41;&#10;  enable_proxy_protocol &#61; optional&#40;bool, false&#41;&#10;  reconcile_connections &#61; optional&#40;bool&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

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
