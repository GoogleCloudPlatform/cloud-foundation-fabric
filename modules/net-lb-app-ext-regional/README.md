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
    - [Network Endpoint Groups (NEGs)](#network-endpoint-groups-negs)
    - [Zonal NEG creation](#zonal-neg-creation)
    - [Hybrid NEG creation](#hybrid-neg-creation)
    - [Private Service Connect NEG creation](#private-service-connect-neg-creation)
    - [Serverless NEG creation](#serverless-neg-creation)
  - [URL Map](#url-map)
  - [Complex example](#complex-example)
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
        { backend = module.compute-mig-b.group.id },
        { backend = module.compute-mig-c.group.id }
      ]
    }
  }
}
# tftest modules=3 resources=9 fixtures=fixtures/compute-mig-bc.tf
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
        { backend = module.compute-mig-b.group.id },
        { backend = module.compute-mig-c.group.id }
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
# tftest modules=3 resources=12 fixtures=fixtures/compute-mig-bc.tf
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
        { backend = module.compute-mig-b.group.id },
        { backend = module.compute-mig-c.group.id }
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
# tftest modules=3 resources=12 fixtures=fixtures/ssl-certificate.tf,fixtures/compute-mig-bc.tf
```

#### HTTP to HTTPS redirect

Redirect is implemented via an additional HTTP load balancer with a custom URL map, similarly to how it's done via the GCP Console. The address shared by the two load balancers needs to be reserved.

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  global_addresses = {
    "ralb-test-0" = {}
  }
}

module "ralb-test-0-redirect" {
  source     = "./fabric/modules/net-lb-app-ext-regional"
  project_id = var.project_id
  name       = "ralb-test-0-redirect"
  vpc        = var.vpc.self_link
  region     = var.region
  address = (
    module.addresses.global_addresses["ralb-test-0"].address
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
    module.addresses.global_addresses["ralb-test-0"].address
  )
  backend_service_configs = {
    default = {
      backends = [
        { backend = module.compute-mig-b.group.id },
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

# tftest modules=5 resources=16 fixtures=fixtures/ssl-certificate.tf,fixtures/compute-mig-bc.tf
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
        backend = module.compute-mig-b.group.id
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
# tftest modules=3 resources=9 fixtures=fixtures/compute-mig-bc.tf
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
        backend = module.compute-mig-b.group.id
      }]
      health_checks = ["projects/${var.project_id}/global/healthChecks/custom"]
    }
  }
  health_check_configs = {}
}
# tftest modules=3 resources=8 fixtures=fixtures/compute-mig-bc.tf
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
        module.compute-mig-b.id
      ]
      named_ports = { http = 80 }
    }
  }
}
# tftest modules=3 resources=10 fixtures=fixtures/compute-mig-bc.tf
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
# tftest modules=3 resources=8
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
        network    = "projects/myprj-host/global/networks/svpc"
        subnetwork = "projects/myprj-host/regions/europe-west8/subnetworks/gce"
        zone       = "${var.region}-b"
        endpoints = {
          e-0 = {
            instance   = "my-ig-b"
            ip_address = module.compute-mig-b.internal_ip
            port       = 80
          }
        }
      }
    }
  }
}
# tftest modules=3 resources=11 fixtures=fixtures/compute-mig-bc.tf
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
        network = "projects/myprj-host/global/networks/svpc"
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
# tftest modules=1 resources=7
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
# tftest modules=1 resources=5
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
        backend = module.compute-mig-b.group.id
      }]
    }
    other = {
      backends = [{
        backend = module.compute-mig-c.group.id
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

# tftest modules=3 resources=10 fixtures=fixtures/compute-mig-bc.tf
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
        module.compute-mig-b.id
      ]
      named_ports = { http = 80 }
    }
    group-zone-c = {
      zone = "${var.region}-c"
      instances = [
        module.compute-mig-c.id
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
            ip_address = module.compute-mig-c.internal_ip
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
# tftest modules=3 resources=18 fixtures=fixtures/compute-mig-bc.tf
```

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->

<!-- END TFDOC -->
