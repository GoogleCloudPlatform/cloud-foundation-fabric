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
  - [Backend Authenticated TLS](#backend-authenticated-tls)
  - [Health Checks](#health-checks)
  - [Backend Types and Management](#backend-types-and-management)
    - [Instance Groups](#instance-groups)
    - [Managed Instance Groups](#managed-instance-groups)
    - [Zonal NEG creation](#zonal-neg-creation)
    - [Hybrid NEG creation](#hybrid-neg-creation)
    - [Internet NEG creation](#internet-neg-creation)
    - [Private Service Connect NEG creation](#private-service-connect-neg-creation)
    - [Serverless NEG creation](#serverless-neg-creation)
    - [Cross Project Backend Services](#cross-project-backend-services)
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

### Backend Authenticated TLS

This example shows how to configure Backend Authenticated TLS using the `tls_settings` block.

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
      ]
      tls_settings = {
        sni               = "backend.example.com"
        subject_alt_names = ["backend.example.com"]
      }
    }
  }
}
# tftest modules=3 resources=9 fixtures=fixtures/compute-vm-group-bc.tf inventory=tls-settings.yaml
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
  source       = "./fabric/modules/compute-vm"
  project_id   = var.project_id
  zone         = "${var.region}-a"
  name         = "win-template"
  machine_type = "n2d-standard-2"
  create_template = {
    regional = false
  }
  boot_disk = {
    source = {
      image = "projects/windows-cloud/global/images/windows-server-2019-dc-v20221214"
    }
    initialize_params = {
      size = 70
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
      backends = [{
        backend = "hybrid-neg"
        # Balancing mode must be RATE for Hybrid NEG
        balancing_mode = "RATE"
        max_rate = {
          per_endpoint = 100
        }
      }]
    }
  }
  neg_configs = {
    hybrid-neg = {
      hybrid = {
        network = var.vpc.self_link
        zone    = "${var.region}-b"
        # default_port = 80
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

#### Internet NEG creation

You can create internet NEGs with either FQDN or IP address endpoints:

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
        { backend = "internet-neg-fqdn" },
        { backend = "internet-neg-ip" }
      ]
    }
  }
  neg_configs = {
    internet-neg-fqdn = {
      internet = {
        region = var.region
        endpoints = {
          e-0 = {
            fqdn = "example.com"
            port = 443
          }
        }
      }
    }
    internet-neg-ip = {
      internet = {
        region = var.region
        endpoints = {
          e-0 = {
            ip_address = "192.0.2.5"
            port       = 443
          }
        }
      }
    }
  }
}
# tftest skip
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

#### Cross Project Backend Services

The module supports Cross Project Backend Services. This is an example of a referencing to a Backend Service in another project:

```hcl
module "ralb-0" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0"
  vpc        = var.vpc.self_link
  region     = var.region

  backend_service_configs = {
    my_backend = {
      project_id = "backend_project_id" #Specify the project ID where the backend service resides

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
| [negs.tf](./negs.tf) | NEG resources. | <code>google_compute_network_endpoint</code> · <code>google_compute_network_endpoint_group</code> · <code>google_compute_region_network_endpoint</code> · <code>google_compute_region_network_endpoint_group</code> |
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
| [name](variables.tf#L73) | Load balancer name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L199) | Project id. | <code>string</code> | ✓ |  |
| [region](variables.tf#L217) | Region where the load balancer is created. | <code>string</code> | ✓ |  |
| [vpc](variables.tf#L237) | VPC-level configuration. | <code>string</code> | ✓ |  |
| [address](variables.tf#L17) | Optional IP address used for the forwarding rule. | <code>string</code> |  | <code>null</code> |
| [backend_service_configs](variables-backend-service.tf#L19) | Backend service level configuration. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L23) | Optional description used for resources. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [group_configs](variables.tf#L29) | Optional unmanaged groups to create. Can be referenced in backends via key or outputs. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_check_configs](variables-health-check.tf#L19) | Optional auto-created health check configurations, use the output self-link to set it in the auto healing policy. Refer to examples for usage. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [http_proxy_config](variables.tf#L43) | HTTP proxy configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [https_proxy_config](variables.tf#L53) | HTTPS proxy connfiguration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L67) | Labels set on resources. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [neg_configs](variables.tf#L78) | Optional network endpoint groups to create. Can be referenced in backends via key or outputs. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [network_tier_standard](variables.tf#L182) | Use standard network tier. | <code>bool</code> |  | <code>true</code> |
| [ports](variables.tf#L189) | Optional ports for HTTP load balancer. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [protocol](variables.tf#L204) | Protocol supported by this load balancer. | <code>string</code> |  | <code>&#34;HTTP&#34;</code> |
| [ssl_certificates](variables.tf#L222) | SSL target proxy certificates (only if protocol is HTTPS) for existing, custom, and managed certificates. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [urlmap_config](variables-urlmap.tf#L19) | The URL map configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |

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
| [url_map_id](outputs.tf#L78) | Fully qualified URL map ID (resource path) for use in IAM conditions and API calls. |  |

## Fixtures

- [compute-vm-group-bc.tf](../../tests/fixtures/compute-vm-group-bc.tf)
- [ssl-certificate.tf](../../tests/fixtures/ssl-certificate.tf)
<!-- END TFDOC -->
