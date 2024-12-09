# External Regional Application Load Balancer Module

This module allows managing External Regional HTTP/HTTPS Application Load Balancers. It's designed to expose the full configuration of the underlying resources, and to facilitate common usage patterns by providing sensible defaults, and optionally managing prerequisite resources like health checks, instance groups, etc.

Due to the complexity of the underlying resources, changes to the configuration that involve recreation of resources are best applied in stages, starting by disabling the configuration in the urlmap that references the resources that need recreation, then doing the same for the backend service, etc.

The variable space of this module closely mirrors that of  [net-lb-app-ext](../net-lb-app-ext), with the exception of certain features not supported by the regional version. These unsupported features include GCS backends and Internet NEGs, among others. For a comprehensive overview of feature disparities, please consult the [load balancer feature comparison matrix](https://cloud.google.com/load-balancing/docs/features).

## Examples

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Minimal HTTP Example](#minimal-http-example)
  - [Minimal HTTPS examples](#minimal-https-examples)
    - [HTTP backends](#http-backends)
    - [HTTPS backends](#https-backends)
    - [HTTP to HTTPS redirect](#http-to-https-redirect)
  - [Health Checks](#health-checks)
  - [Backend Types and Management](#backend-types-and-management)
    - [Instance Groups](#instance-groups)
    - [Managed Instance Groups](#managed-instance-groups)
    - [Zonal NEG creation](#zonal-neg-creation)
    - [Hybrid NEG creation](#hybrid-neg-creation)
    - [Private Service Connect NEG creation](#private-service-connect-neg-creation)
    - [Serverless NEG creation](#serverless-neg-creation)
    - [Cross Project Backend](#cross-project-backend)
  - [URL Map](#url-map)
  - [Complex example](#complex-example)
- [Deploying changes to load balancer configurations](#deploying-changes-to-load-balancer-configurations)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
- [Fixtures](#fixtures)
<!-- END TOC -->

### Minimal HTTP Example

An HTTP load balancer with a backend service pointing to a GCE instance group:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [
        { backend = module.compute-vm-group-b.group.id },
        { backend = module.compute-vm-group-c.group.id }
      ]
    }
  }
}
# tftest modules=3 resources=9 fixtures=fixtures/compute-vm-group-bc.tf e2e
```

### Minimal HTTPS examples

#### HTTP backends

An HTTPS load balancer needs a certificate and backends can be HTTP or HTTPS. Regional external application load balancers don't support managed certificates, so you have to provide the certificate and private key manually as shown below:

```hcl
resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "default" {
  private_key_pem = tls_private_key.default.private_key_pem
  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }
  validity_period_hours = 720
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [
        { backend = module.compute-vm-group-b.group.id },
        { backend = module.compute-vm-group-c.group.id }
      ]
      protocol = "HTTP"
    }
  }
  protocol = "HTTPS"
  ssl_certificates = {
    create_configs = {
      default = {
        # certificate and key could also be read via file() from external files
        certificate = tls_self_signed_cert.default.cert_pem
        private_key = tls_private_key.default.private_key_pem
      }
    }
  }
}
# tftest modules=3 resources=12 fixtures=fixtures/compute-vm-group-bc.tf e2e
```

#### HTTPS backends

For HTTPS backends the backend service protocol needs to be set to `HTTPS`. The port name if omitted is inferred from the protocol, in this case it is set internally to `https`. The health check also needs to be set to https. This is a complete example:

```hcl
module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [
        { backend = module.compute-vm-group-b.group.id },
        { backend = module.compute-vm-group-c.group.id }
      ]
      protocol = "HTTPS"
    }
  }
  health_check_configs = {
    default = {
      https = {
        port_specification = "USE_SERVING_PORT"
      }
    }
  }
  protocol = "HTTPS"
  ssl_certificates = {
    create_configs = {
      default = {
        certificate = tls_self_signed_cert.default.cert_pem
        private_key = tls_private_key.default.private_key_pem
      }
    }
  }
}
# tftest modules=3 resources=12 fixtures=fixtures/ssl-certificate.tf,fixtures/compute-vm-group-bc.tf e2e
```

#### HTTP to HTTPS redirect

Redirect is implemented via an additional HTTP load balancer with a custom URL map, similarly to how it's done via the GCP Console. The address shared by the two load balancers needs to be reserved.

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  external_addresses = {
    "ralb-test-0" = {
      region = var.region
      tier   = "STANDARD"
    }
  }
}

module "ralb-test-0-redirect" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0-redirect"
  vpc        = var.vpc.self_link
  region     = var.region
  address = (
    module.addresses.external_addresses["ralb-test-0"].id
  )
  health_check_configs = {}
  urlmap_config = {
    description = "URL redirect for ralb-test-0."
    default_url_redirect = {
      https         = true
      response_code = "MOVED_PERMANENTLY_DEFAULT"
    }
  }
}

module "ralb-test-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  address = (
    module.addresses.external_addresses["ralb-test-0"].id
  )
  backend_service_configs = {
    default = {
      backends = [
        { backend = module.compute-vm-group-b.group.id },
      ]
      protocol = "HTTP"
    }
  }
  protocol = "HTTPS"
  ssl_certificates = {
    create_configs = {
      default = {
        certificate = tls_self_signed_cert.default.cert_pem
        private_key = tls_private_key.default.private_key_pem
      }
    }
  }
}

# tftest modules=5 resources=16 fixtures=fixtures/ssl-certificate.tf,fixtures/compute-vm-group-bc.tf e2e
```

### Health Checks

You can leverage externally defined health checks for backend services, or have the module create them for you.

By default a simple HTTP health check named `default` is created and used in backend services. If you need to override the default, simply define your own health check using the same key (`default`). For more complex configurations you can define your own health checks and reference them via keys in the backend service configurations.

Health checks created by this module are controlled via the `health_check_configs` variable, which behaves in a similar way to other LB modules in this repository. This is an example that overrides the default health check configuration using a TCP health check:

```hcl
module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [{
        backend = module.compute-vm-group-b.group.id
      }]
      # no need to reference the hc explicitly when using the `default` key
      # health_checks = ["default"]
    }
  }
  health_check_configs = {
    default = {
      tcp = { port = 80 }
    }
  }
}
# tftest modules=3 resources=9 fixtures=fixtures/compute-vm-group-bc.tf e2e
```

To leverage existing health checks without having the module create them, simply pass their self links to backend services and set the `health_check_configs` variable to an empty map:

```hcl
module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [{
        backend = module.compute-vm-group-b.group.id
      }]
      health_checks = ["projects/${var.project_id}/regions/${var.region}/healthChecks/custom"]
    }
  }
  health_check_configs = {}
}
# tftest modules=3 resources=8 fixtures=fixtures/compute-vm-group-bc.tf
```

### Backend Types and Management

#### Instance Groups

The module can optionally create unmanaged instance groups, which can then be referred to in backends via their key. This is the simple HTTP example above but with instance group creation managed by the module:

```hcl
module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [
        { backend = "default-b" }
      ]
    }
  }
  group_configs = {
    default-b = {
      zone = "${var.region}-b"
      instances = [
        module.compute-vm-group-b.id
      ]
      named_ports = { http = 80 }
    }
  }
}
# tftest modules=3 resources=10 fixtures=fixtures/compute-vm-group-bc.tf e2e
```

#### Managed Instance Groups

This example shows how to use the module with a manage instance group as backend:

```hcl
module "win-template" {
  source          = "./fabric/modules/compute-vm"
  project_id      = var.project_id
  zone            = "${var.region}-a"
  name            = "win-template"
  instance_type   = "n2d-standard-2"
  create_template = true
  boot_disk = {
    initialize_params = {
      image = "projects/windows-cloud/global/images/windows-server-2019-dc-v20221214"
      size  = 70
    }
  }
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = false
    addresses  = null
  }]
}

module "win-mig" {
  source            = "./fabric/modules/compute-mig"
  project_id        = var.project_id
  location          = "${var.region}-a"
  name              = "win-mig"
  instance_template = module.win-template.template.self_link
  autoscaler_config = {
    max_replicas    = 3
    min_replicas    = 1
    cooldown_period = 30
    scaling_signals = {
      cpu_utilization = {
        target = 0.80
      }
    }
  }
  named_ports = {
    http = 80
  }
}

module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [
        { backend = module.win-mig.group_manager.instance_group }
      ]
    }
  }
}
# tftest modules=3 resources=8 e2e
```

#### Zonal NEG creation

Supported Network Endpoint Groups (NEGs) can also be used as backends. Similarly to groups, you can pass a self link for existing NEGs or have the module manage them for you.

This example shows how to create and manage zonal NEGs using GCE VMs as endpoints:

```hcl
module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [
        {
          backend        = "neg-0"
          balancing_mode = "RATE"
          max_rate       = { per_endpoint = 10 }
        }
      ]
    }
  }
  neg_configs = {
    neg-0 = {
      gce = {
        network    = var.vpc.self_link
        subnetwork = var.subnet.self_link
        zone       = "${var.region}-b"
        endpoints = {
          e-0 = {
            instance   = "my-ig-b"
            ip_address = module.compute-vm-group-b.internal_ip
            port       = 80
          }
        }
      }
    }
  }
}
# tftest modules=3 resources=11 fixtures=fixtures/compute-vm-group-bc.tf e2e
```

#### Hybrid NEG creation

This example shows how to create and manage hybrid NEGs:

```hcl
module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [
        {
          backend        = "neg-0"
          balancing_mode = "RATE"
          max_rate       = { per_endpoint = 10 }
        }
      ]
    }
  }
  neg_configs = {
    neg-0 = {
      hybrid = {
        network = var.vpc.self_link
        zone    = "${var.region}-b"
        endpoints = {
          e-0 = {
            ip_address = "10.0.0.10"
            port       = 80
          }
        }
      }
    }
  }
}
# tftest modules=1 resources=7 e2e
```

#### Private Service Connect NEG creation

```hcl
module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [
        { backend = "neg-0" }
      ]
      health_checks = []
    }
  }
  # with a single PSC NEG the implied default health check is not needed
  health_check_configs = {}
  neg_configs = {
    neg-0 = {
      psc = {
        region         = var.region
        target_service = "${var.region}-cloudkms.googleapis.com"
      }
    }
  }
}
# tftest modules=1 resources=5 e2e
```

#### Serverless NEG creation

The module supports managing Serverless NEGs for Cloud Run and Cloud Function. This is an example of a Cloud Run NEG:

```hcl
module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [
        { backend = "neg-0" }
      ]
      health_checks = []
    }
  }
  # with a single serverless NEG the implied default health check is not needed
  health_check_configs = {}
  neg_configs = {
    neg-0 = {
      cloudrun = {
        region = var.region
        target_service = {
          name = "hello"
        }
      }
    }
  }
}
# tftest modules=1 resources=5 e2e
```

#### Cross Project Backend

The module supports Cross Project Backends. This is an example of a referencing to a Backend in another project:

```hcl
module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region

  backend_service_configs = {
    my_backend = {
      project_id = "backend_project_id" #Specify the project ID where the backend resides

      backends = [
        {
          backend = "neg-0"
        }
      ]
      health_checks = []
    }
  }
  urlmap_config = {
    default_service = "ralb-test-0-my_backend"
  }
}
# tftest modules=1 resources=5
```

### URL Map

The module exposes the full URL map resource configuration, with some minor changes to the interface to decrease verbosity, and support for aliasing backend services via keys.

The default URL map configuration sets the `default` backend service as the default service for the load balancer as a convenience. Just override the `urlmap_config` variable to change the default behaviour:

```hcl
module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [{
        backend = module.compute-vm-group-b.group.id
      }]
    }
    other = {
      backends = [{
        backend = module.compute-vm-group-c.group.id
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
          paths   = ["/other", "/other/*"]
          service = "other"
        }]
      }
    }
  }
}

# tftest modules=3 resources=10 fixtures=fixtures/compute-vm-group-bc.tf e2e
```

### Complex example

This example mixes group and NEG backends, and shows how to set HTTPS for specific backends.

```hcl
module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [
        { backend = "group-zone-b" },
        { backend = "group-zone-c" },
      ]
    }
    neg-gce-0 = {
      backends = [{
        balancing_mode = "RATE"
        backend        = "neg-zone-c"
        max_rate       = { per_endpoint = 10 }
      }]
    }
    neg-hybrid-0 = {
      backends = [{
        balancing_mode = "RATE"
        backend        = "neg-hello"
        max_rate       = { per_endpoint = 10 }
      }]
      health_checks = ["neg"]
      protocol      = "HTTPS"
    }
  }
  group_configs = {
    group-zone-b = {
      zone = "${var.region}-b"
      instances = [
        module.compute-vm-group-b.id
      ]
      named_ports = { http = 80 }
    }
    group-zone-c = {
      zone = "${var.region}-c"
      instances = [
        module.compute-vm-group-c.id
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
        host = "hello.example.com"
        port = 443
      }
    }
  }
  neg_configs = {
    neg-zone-c = {
      gce = {
        network    = var.vpc.self_link
        subnetwork = var.subnet.self_link
        zone       = "${var.region}-c"
        endpoints = {
          e-0 = {
            instance   = "my-ig-c"
            ip_address = module.compute-vm-group-c.internal_ip
            port       = 80
          }
        }
      }
    }
    neg-hello = {
      hybrid = {
        network = var.vpc.self_link
        zone    = "${var.region}-b"
        endpoints = {
          e-0 = {
            ip_address = "192.168.0.3"
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
        hosts        = ["hello.example.com"]
        path_matcher = "hello"
      },
      {
        hosts        = ["static.example.com"]
        path_matcher = "static"
      }
    ]
    path_matchers = {
      gce = {
        default_service = "default"
        path_rules = [
          {
            paths   = ["/gce-neg", "/gce-neg/*"]
            service = "neg-gce-0"
          }
        ]
      }
      hello = {
        default_service = "neg-hybrid-0"
      }
      static = {
        default_service = "neg-gce-0"
      }
    }
  }
}
# tftest modules=3 resources=18 fixtures=fixtures/compute-vm-group-bc.tf e2e
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
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_compute_forwarding_rule</code> · <code>google_compute_region_ssl_certificate</code> · <code>google_compute_region_target_http_proxy</code> · <code>google_compute_region_target_https_proxy</code> |
| [negs.tf](./negs.tf) | NEG resources. | <code>google_compute_network_endpoint</code> · <code>google_compute_network_endpoint_group</code> · <code>google_compute_region_network_endpoint_group</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [urlmap.tf](./urlmap.tf) | URL map resources. | <code>google_compute_region_url_map</code> |
| [variables-backend-service.tf](./variables-backend-service.tf) | Backend services variables. |  |
| [variables-health-check.tf](./variables-health-check.tf) | Health check variable. |  |
| [variables-urlmap.tf](./variables-urlmap.tf) | URLmap variable. |  |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L59) | Load balancer name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L151) | Project id. | <code>string</code> | ✓ |  |
| [region](variables.tf#L169) | Region where the load balancer is created. | <code>string</code> | ✓ |  |
| [vpc](variables.tf#L188) | VPC-level configuration. | <code>string</code> | ✓ |  |
| [address](variables.tf#L17) | Optional IP address used for the forwarding rule. | <code>string</code> |  | <code>null</code> |
| [backend_service_configs](variables-backend-service.tf#L19) | Backend service level configuration. | <code title="map&#40;object&#40;&#123;&#10;  affinity_cookie_ttl_sec         &#61; optional&#40;number&#41;&#10;  connection_draining_timeout_sec &#61; optional&#40;number&#41;&#10;  enable_cdn                      &#61; optional&#40;bool&#41;&#10;  health_checks                   &#61; optional&#40;list&#40;string&#41;, &#91;&#34;default&#34;&#93;&#41;&#10;  log_sample_rate                 &#61; optional&#40;number&#41;&#10;  port_name                       &#61; optional&#40;string&#41;&#10;  project_id                      &#61; optional&#40;string&#41;&#10;  protocol                        &#61; optional&#40;string&#41;&#10;  security_policy                 &#61; optional&#40;string&#41;&#10;  session_affinity                &#61; optional&#40;string&#41;&#10;  timeout_sec                     &#61; optional&#40;number&#41;&#10;  backends &#61; list&#40;object&#40;&#123;&#10;    backend         &#61; string&#10;    balancing_mode  &#61; optional&#40;string, &#34;UTILIZATION&#34;&#41;&#10;    capacity_scaler &#61; optional&#40;number, 1&#41;&#10;    description     &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;    failover        &#61; optional&#40;bool, false&#41;&#10;    max_connections &#61; optional&#40;object&#40;&#123;&#10;      per_endpoint &#61; optional&#40;number&#41;&#10;      per_group    &#61; optional&#40;number&#41;&#10;      per_instance &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    max_rate &#61; optional&#40;object&#40;&#123;&#10;      per_endpoint &#61; optional&#40;number&#41;&#10;      per_group    &#61; optional&#40;number&#41;&#10;      per_instance &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    max_utilization &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  cdn_policy &#61; optional&#40;object&#40;&#123;&#10;    cache_mode                   &#61; optional&#40;string&#41;&#10;    client_ttl                   &#61; optional&#40;number&#41;&#10;    default_ttl                  &#61; optional&#40;number&#41;&#10;    max_ttl                      &#61; optional&#40;number&#41;&#10;    negative_caching             &#61; optional&#40;bool&#41;&#10;    serve_while_stale            &#61; optional&#40;number&#41;&#10;    signed_url_cache_max_age_sec &#61; optional&#40;number&#41;&#10;    cache_key_policy &#61; optional&#40;object&#40;&#123;&#10;      include_host           &#61; optional&#40;bool&#41;&#10;      include_named_cookies  &#61; optional&#40;list&#40;string&#41;&#41;&#10;      include_protocol       &#61; optional&#40;bool&#41;&#10;      include_query_string   &#61; optional&#40;bool&#41;&#10;      query_string_blacklist &#61; optional&#40;list&#40;string&#41;&#41;&#10;      query_string_whitelist &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    negative_caching_policy &#61; optional&#40;object&#40;&#123;&#10;      code &#61; optional&#40;number&#41;&#10;      ttl  &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  circuit_breakers &#61; optional&#40;object&#40;&#123;&#10;    max_connections             &#61; optional&#40;number&#41;&#10;    max_pending_requests        &#61; optional&#40;number&#41;&#10;    max_requests                &#61; optional&#40;number&#41;&#10;    max_requests_per_connection &#61; optional&#40;number&#41;&#10;    max_retries                 &#61; optional&#40;number&#41;&#10;    connect_timeout &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  consistent_hash &#61; optional&#40;object&#40;&#123;&#10;    http_header_name  &#61; optional&#40;string&#41;&#10;    minimum_ring_size &#61; optional&#40;number&#41;&#10;    http_cookie &#61; optional&#40;object&#40;&#123;&#10;      name &#61; optional&#40;string&#41;&#10;      path &#61; optional&#40;string&#41;&#10;      ttl &#61; optional&#40;object&#40;&#123;&#10;        seconds &#61; number&#10;        nanos   &#61; optional&#40;number&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  iap_config &#61; optional&#40;object&#40;&#123;&#10;    oauth2_client_id            &#61; string&#10;    oauth2_client_secret        &#61; string&#10;    oauth2_client_secret_sha256 &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  outlier_detection &#61; optional&#40;object&#40;&#123;&#10;    consecutive_errors                    &#61; optional&#40;number&#41;&#10;    consecutive_gateway_failure           &#61; optional&#40;number&#41;&#10;    enforcing_consecutive_errors          &#61; optional&#40;number&#41;&#10;    enforcing_consecutive_gateway_failure &#61; optional&#40;number&#41;&#10;    enforcing_success_rate                &#61; optional&#40;number&#41;&#10;    max_ejection_percent                  &#61; optional&#40;number&#41;&#10;    success_rate_minimum_hosts            &#61; optional&#40;number&#41;&#10;    success_rate_request_volume           &#61; optional&#40;number&#41;&#10;    success_rate_stdev_factor             &#61; optional&#40;number&#41;&#10;    base_ejection_time &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    interval &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L23) | Optional description used for resources. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [group_configs](variables.tf#L29) | Optional unmanaged groups to create. Can be referenced in backends via key or outputs. | <code title="map&#40;object&#40;&#123;&#10;  zone        &#61; string&#10;  instances   &#61; optional&#40;list&#40;string&#41;&#41;&#10;  named_ports &#61; optional&#40;map&#40;number&#41;, &#123;&#125;&#41;&#10;  project_id  &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_check_configs](variables-health-check.tf#L19) | Optional auto-created health check configurations, use the output self-link to set it in the auto healing policy. Refer to examples for usage. | <code title="map&#40;object&#40;&#123;&#10;  check_interval_sec  &#61; optional&#40;number&#41;&#10;  description         &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  enable_logging      &#61; optional&#40;bool, false&#41;&#10;  healthy_threshold   &#61; optional&#40;number&#41;&#10;  project_id          &#61; optional&#40;string&#41;&#10;  timeout_sec         &#61; optional&#40;number&#41;&#10;  unhealthy_threshold &#61; optional&#40;number&#41;&#10;  grpc &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    service_name       &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  http &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  http2 &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  https &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  tcp &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request            &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  ssl &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request            &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  default &#61; &#123;&#10;    http &#61; &#123;&#10;      port_specification &#61; &#34;USE_SERVING_PORT&#34;&#10;    &#125;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [https_proxy_config](variables.tf#L41) | HTTPS proxy connfiguration. | <code title="object&#40;&#123;&#10;  certificate_manager_certificates &#61; optional&#40;list&#40;string&#41;&#41;&#10;  certificate_map                  &#61; optional&#40;string&#41;&#10;  quic_override                    &#61; optional&#40;string&#41;&#10;  ssl_policy                       &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L53) | Labels set on resources. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [neg_configs](variables.tf#L64) | Optional network endpoint groups to create. Can be referenced in backends via key or outputs. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string&#41;&#10;  cloudfunction &#61; optional&#40;object&#40;&#123;&#10;    region          &#61; string&#10;    target_function &#61; optional&#40;string&#41;&#10;    target_urlmask  &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  cloudrun &#61; optional&#40;object&#40;&#123;&#10;    region &#61; string&#10;    target_service &#61; optional&#40;object&#40;&#123;&#10;      name &#61; string&#10;      tag  &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    target_urlmask &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  gce &#61; optional&#40;object&#40;&#123;&#10;    network    &#61; string&#10;    subnetwork &#61; string&#10;    zone       &#61; string&#10;    endpoints &#61; optional&#40;map&#40;object&#40;&#123;&#10;      instance   &#61; string&#10;      ip_address &#61; string&#10;      port       &#61; number&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  hybrid &#61; optional&#40;object&#40;&#123;&#10;    network &#61; string&#10;    zone    &#61; string&#10;    endpoints &#61; optional&#40;map&#40;object&#40;&#123;&#10;      ip_address &#61; string&#10;      port       &#61; number&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  psc &#61; optional&#40;object&#40;&#123;&#10;    region         &#61; string&#10;    target_service &#61; string&#10;    network        &#61; optional&#40;string&#41;&#10;    subnetwork     &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ports](variables.tf#L145) | Optional ports for HTTP load balancer, valid ports are 80 and 8080. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [protocol](variables.tf#L156) | Protocol supported by this load balancer. | <code>string</code> |  | <code>&#34;HTTP&#34;</code> |
| [ssl_certificates](variables.tf#L174) | SSL target proxy certificates (only if protocol is HTTPS) for existing, custom, and managed certificates. | <code title="object&#40;&#123;&#10;  certificate_ids &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  create_configs &#61; optional&#40;map&#40;object&#40;&#123;&#10;    certificate &#61; string&#10;    private_key &#61; string&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [urlmap_config](variables-urlmap.tf#L19) | The URL map configuration. | <code title="object&#40;&#123;&#10;  default_route_action &#61; optional&#40;object&#40;&#123;&#10;    request_mirror_backend &#61; optional&#40;string&#41;&#10;    cors_policy &#61; optional&#40;object&#40;&#123;&#10;      allow_credentials    &#61; optional&#40;bool&#41;&#10;      allow_headers        &#61; optional&#40;list&#40;string&#41;&#41;&#10;      allow_methods        &#61; optional&#40;list&#40;string&#41;&#41;&#10;      allow_origin_regexes &#61; optional&#40;list&#40;string&#41;&#41;&#10;      allow_origins        &#61; optional&#40;list&#40;string&#41;&#41;&#10;      disabled             &#61; optional&#40;bool&#41;&#10;      expose_headers       &#61; optional&#40;list&#40;string&#41;&#41;&#10;      max_age              &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    fault_injection_policy &#61; optional&#40;object&#40;&#123;&#10;      abort &#61; optional&#40;object&#40;&#123;&#10;        percentage &#61; number&#10;        status     &#61; number&#10;      &#125;&#41;&#41;&#10;      delay &#61; optional&#40;object&#40;&#123;&#10;        fixed &#61; object&#40;&#123;&#10;          seconds &#61; number&#10;          nanos   &#61; number&#10;        &#125;&#41;&#10;        percentage &#61; number&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    retry_policy &#61; optional&#40;object&#40;&#123;&#10;      num_retries      &#61; number&#10;      retry_conditions &#61; optional&#40;list&#40;string&#41;&#41;&#10;      per_try_timeout &#61; optional&#40;object&#40;&#123;&#10;        seconds &#61; number&#10;        nanos   &#61; optional&#40;number&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    timeout &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    url_rewrite &#61; optional&#40;object&#40;&#123;&#10;      host          &#61; optional&#40;string&#41;&#10;      path_prefix   &#61; optional&#40;string&#41;&#10;      path_template &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    weighted_backend_services &#61; optional&#40;map&#40;object&#40;&#123;&#10;      weight &#61; number&#10;      header_action &#61; optional&#40;object&#40;&#123;&#10;        request_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;          value   &#61; string&#10;          replace &#61; optional&#40;bool, true&#41;&#10;        &#125;&#41;&#41;&#41;&#10;        request_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;        response_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;          value   &#61; string&#10;          replace &#61; optional&#40;bool, true&#41;&#10;        &#125;&#41;&#41;&#41;&#10;        response_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  default_service &#61; optional&#40;string&#41;&#10;  default_url_redirect &#61; optional&#40;object&#40;&#123;&#10;    host          &#61; optional&#40;string&#41;&#10;    https         &#61; optional&#40;bool&#41;&#10;    path          &#61; optional&#40;string&#41;&#10;    prefix        &#61; optional&#40;string&#41;&#10;    response_code &#61; optional&#40;string&#41;&#10;    strip_query   &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  header_action &#61; optional&#40;object&#40;&#123;&#10;    request_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;      value   &#61; string&#10;      replace &#61; optional&#40;bool, true&#41;&#10;    &#125;&#41;&#41;&#41;&#10;    request_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;    response_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;      value   &#61; string&#10;      replace &#61; optional&#40;bool, true&#41;&#10;    &#125;&#41;&#41;&#41;&#10;    response_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  host_rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;    hosts        &#61; list&#40;string&#41;&#10;    path_matcher &#61; string&#10;    description  &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  path_matchers &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description     &#61; optional&#40;string&#41;&#10;    default_service &#61; optional&#40;string&#41;&#10;    default_url_redirect &#61; optional&#40;object&#40;&#123;&#10;      host          &#61; optional&#40;string&#41;&#10;      https         &#61; optional&#40;bool&#41;&#10;      path          &#61; optional&#40;string&#41;&#10;      prefix        &#61; optional&#40;string&#41;&#10;      response_code &#61; optional&#40;string&#41;&#10;      strip_query   &#61; optional&#40;bool&#41;&#10;    &#125;&#41;&#41;&#10;    path_rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;      paths   &#61; list&#40;string&#41;&#10;      service &#61; optional&#40;string&#41;&#10;      route_action &#61; optional&#40;object&#40;&#123;&#10;        request_mirror_backend &#61; optional&#40;string&#41;&#10;        cors_policy &#61; optional&#40;object&#40;&#123;&#10;          allow_credentials    &#61; optional&#40;bool&#41;&#10;          allow_headers        &#61; optional&#40;list&#40;string&#41;&#41;&#10;          allow_methods        &#61; optional&#40;list&#40;string&#41;&#41;&#10;          allow_origin_regexes &#61; optional&#40;list&#40;string&#41;&#41;&#10;          allow_origins        &#61; optional&#40;list&#40;string&#41;&#41;&#10;          disabled             &#61; optional&#40;bool&#41;&#10;          expose_headers       &#61; optional&#40;list&#40;string&#41;&#41;&#10;          max_age              &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;        fault_injection_policy &#61; optional&#40;object&#40;&#123;&#10;          abort &#61; optional&#40;object&#40;&#123;&#10;            percentage &#61; number&#10;            status     &#61; number&#10;          &#125;&#41;&#41;&#10;          delay &#61; optional&#40;object&#40;&#123;&#10;            fixed &#61; object&#40;&#123;&#10;              seconds &#61; number&#10;              nanos   &#61; number&#10;            &#125;&#41;&#10;            percentage &#61; number&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        retry_policy &#61; optional&#40;object&#40;&#123;&#10;          num_retries      &#61; number&#10;          retry_conditions &#61; optional&#40;list&#40;string&#41;&#41;&#10;          per_try_timeout &#61; optional&#40;object&#40;&#123;&#10;            seconds &#61; number&#10;            nanos   &#61; optional&#40;number&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        timeout &#61; optional&#40;object&#40;&#123;&#10;          seconds &#61; number&#10;          nanos   &#61; optional&#40;number&#41;&#10;        &#125;&#41;&#41;&#10;        url_rewrite &#61; optional&#40;object&#40;&#123;&#10;          host          &#61; optional&#40;string&#41;&#10;          path_prefix   &#61; optional&#40;string&#41;&#10;          path_template &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;        weighted_backend_services &#61; optional&#40;map&#40;object&#40;&#123;&#10;          weight &#61; number&#10;          header_action &#61; optional&#40;object&#40;&#123;&#10;            request_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;              value   &#61; string&#10;              replace &#61; optional&#40;bool, true&#41;&#10;            &#125;&#41;&#41;&#41;&#10;            request_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;            response_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;              value   &#61; string&#10;              replace &#61; optional&#40;bool, true&#41;&#10;            &#125;&#41;&#41;&#41;&#10;            response_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      url_redirect &#61; optional&#40;object&#40;&#123;&#10;        host          &#61; optional&#40;string&#41;&#10;        https         &#61; optional&#40;bool&#41;&#10;        path          &#61; optional&#40;string&#41;&#10;        prefix        &#61; optional&#40;string&#41;&#10;        response_code &#61; optional&#40;string&#41;&#10;        strip_query   &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#41;&#10;    route_rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;      priority &#61; number&#10;      service  &#61; optional&#40;string&#41;&#10;      header_action &#61; optional&#40;object&#40;&#123;&#10;        request_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;          value   &#61; string&#10;          replace &#61; optional&#40;bool, true&#41;&#10;        &#125;&#41;&#41;&#41;&#10;        request_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;        response_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;          value   &#61; string&#10;          replace &#61; optional&#40;bool, true&#41;&#10;        &#125;&#41;&#41;&#41;&#10;        response_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      match_rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;        ignore_case &#61; optional&#40;bool, false&#41;&#10;        headers &#61; optional&#40;list&#40;object&#40;&#123;&#10;          name         &#61; string&#10;          invert_match &#61; optional&#40;bool, false&#41;&#10;          type         &#61; optional&#40;string, &#34;present&#34;&#41; &#35; exact, prefix, suffix, regex, present, range, template&#10;          value        &#61; optional&#40;string&#41;&#10;          range_value &#61; optional&#40;object&#40;&#123;&#10;            end   &#61; string&#10;            start &#61; string&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#41;&#10;        metadata_filters &#61; optional&#40;list&#40;object&#40;&#123;&#10;          labels    &#61; map&#40;string&#41;&#10;          match_all &#61; bool &#35; MATCH_ANY, MATCH_ALL&#10;        &#125;&#41;&#41;&#41;&#10;        path &#61; optional&#40;object&#40;&#123;&#10;          value &#61; string&#10;          type  &#61; optional&#40;string, &#34;prefix&#34;&#41; &#35; full, prefix, regex&#10;        &#125;&#41;&#41;&#10;        query_params &#61; optional&#40;list&#40;object&#40;&#123;&#10;          name  &#61; string&#10;          value &#61; string&#10;          type  &#61; optional&#40;string, &#34;present&#34;&#41; &#35; exact, present, regex&#10;        &#125;&#41;&#41;&#41;&#10;      &#125;&#41;&#41;&#41;&#10;      route_action &#61; optional&#40;object&#40;&#123;&#10;        request_mirror_backend &#61; optional&#40;string&#41;&#10;        cors_policy &#61; optional&#40;object&#40;&#123;&#10;          allow_credentials    &#61; optional&#40;bool&#41;&#10;          allow_headers        &#61; optional&#40;string&#41;&#10;          allow_methods        &#61; optional&#40;string&#41;&#10;          allow_origin_regexes &#61; list&#40;string&#41;&#10;          allow_origins        &#61; list&#40;string&#41;&#10;          disabled             &#61; optional&#40;bool&#41;&#10;          expose_headers       &#61; optional&#40;string&#41;&#10;          max_age              &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;        fault_injection_policy &#61; optional&#40;object&#40;&#123;&#10;          abort &#61; optional&#40;object&#40;&#123;&#10;            percentage &#61; number&#10;            status     &#61; number&#10;          &#125;&#41;&#41;&#10;          delay &#61; optional&#40;object&#40;&#123;&#10;            fixed &#61; object&#40;&#123;&#10;              seconds &#61; number&#10;              nanos   &#61; number&#10;            &#125;&#41;&#10;            percentage &#61; number&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        retry_policy &#61; optional&#40;object&#40;&#123;&#10;          num_retries      &#61; number&#10;          retry_conditions &#61; optional&#40;list&#40;string&#41;&#41;&#10;          per_try_timeout &#61; optional&#40;object&#40;&#123;&#10;            seconds &#61; number&#10;            nanos   &#61; optional&#40;number&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        timeout &#61; optional&#40;object&#40;&#123;&#10;          seconds &#61; number&#10;          nanos   &#61; optional&#40;number&#41;&#10;        &#125;&#41;&#41;&#10;        url_rewrite &#61; optional&#40;object&#40;&#123;&#10;          host          &#61; optional&#40;string&#41;&#10;          path_prefix   &#61; optional&#40;string&#41;&#10;          path_template &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;        weighted_backend_services &#61; optional&#40;map&#40;object&#40;&#123;&#10;          weight &#61; number&#10;          header_action &#61; optional&#40;object&#40;&#123;&#10;            request_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;              value   &#61; string&#10;              replace &#61; optional&#40;bool, true&#41;&#10;            &#125;&#41;&#41;&#41;&#10;            request_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;            response_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;              value   &#61; string&#10;              replace &#61; optional&#40;bool, true&#41;&#10;            &#125;&#41;&#41;&#41;&#10;            response_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      url_redirect &#61; optional&#40;object&#40;&#123;&#10;        host          &#61; optional&#40;string&#41;&#10;        https         &#61; optional&#40;bool&#41;&#10;        path          &#61; optional&#40;string&#41;&#10;        prefix        &#61; optional&#40;string&#41;&#10;        response_code &#61; optional&#40;string&#41;&#10;        strip_query   &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  test &#61; optional&#40;list&#40;object&#40;&#123;&#10;    host        &#61; string&#10;    path        &#61; string&#10;    service     &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  default_service &#61; &#34;default&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [address](outputs.tf#L17) | Forwarding rule address. |  |
| [backend_service_ids](outputs.tf#L22) | Backend service resources. |  |
| [backend_service_names](outputs.tf#L29) | Backend service resource names. |  |
| [forwarding_rule](outputs.tf#L36) | Forwarding rule resource. |  |
| [group_ids](outputs.tf#L41) | Autogenerated instance group ids. |  |
| [health_check_ids](outputs.tf#L48) | Autogenerated health check ids. |  |
| [id](outputs.tf#L55) | Fully qualified forwarding rule id. |  |
| [neg_ids](outputs.tf#L60) | Autogenerated network endpoint group ids. |  |

## Fixtures

- [compute-vm-group-bc.tf](../../tests/fixtures/compute-vm-group-bc.tf)
- [ssl-certificate.tf](../../tests/fixtures/ssl-certificate.tf)
<!-- END TFDOC -->
