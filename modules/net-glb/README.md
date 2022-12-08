# Global HTTP/S Classic Load Balancer Module

This module allows managing Global HTTP/HTTPS Classic Load Balancers (GLBs). It's designed to expose the full configuration of the underlying resources, and to facilitate common usage patterns by providing sensible defaults, and optionally managing prerequisite resources like health checks, instance groups, etc.

Due to the complexity of the underlying resources, changes to the configuration that involve recreation of resources are best applied in stages, starting by disabling the configuration in the urlmap that references the resources that neeed recreation, then doing the same for the backend service, etc.

## Examples

- [Minimal HTTP Example](#minimal-http-example)
- [Minimal HTTPS Examples](#minimal-https-examples)
- [Health Checks](#health-checks)
- [Backend Types and Management](#backend-types-and-management)
  - [Instance Groups](#instance-groups)
  - [Storage Buckets](#storage-buckets)
  - [Network Endpoint Groups](#network-endpoint-groups-negs)
  - [Zonal NEGs](#zonal-neg-creation)
  - [Hybrid NEGs](#hybrid-neg-creation)
  - [Internet NEGs](#internet-neg-creation)
  - [Serverless NEGs](#serverless-neg-creation)
- [URL Map](#url-map)
- [SSL Certificates](#ssl-certificates)
- [Complex Example](#complex-example)

### Minimal HTTP Example

An HTTP load balancer with a backend service pointing to a GCE instance group:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = "myprj"
  name       = "glb-test-0"
  backend_service_configs = {
    default = {
      backends = [
        { backend = "projects/myprj/zones/europe-west8-b/instanceGroups/myig-b" },
        { backend = "projects/myprj/zones/europe-west8-c/instanceGroups/myig-c" },
      ]
    }
  }
}
# tftest modules=1 resources=5
```

### Minimal HTTPS examples

#### HTTP backends

An HTTPS load balancer needs a certificate and backends can be HTTP or HTTPS. THis is an example With HTTP backends and a managed certificate:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = "myprj"
  name       = "glb-test-0"
  backend_service_configs = {
    default = {
      backends = [
        { backend = "projects/myprj/zones/europe-west8-b/instanceGroups/myig-b" },
        { backend = "projects/myprj/zones/europe-west8-c/instanceGroups/myig-c" },
      ]
      protocol = "HTTP"
    }
  }
  protocol = "HTTPS"
  ssl_certificates = {
    managed_configs = {
      default = {
        domains = ["glb-test-0.example.org"]
      }
    }
  }
}
# tftest modules=1 resources=6
```

#### HTTPS backends

For HTTPS backends the backend service protocol needs to be set to `HTTPS`. The port name if omitted is inferred from the protocol, in this case it is set internally to `https`. The health check also needs to be set to https. This is a complete example:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = "myprj"
  name       = "glb-test-0"
  backend_service_configs = {
    default = {
      backends = [
        { backend = "projects/myprj/zones/europe-west8-b/instanceGroups/myig-b" },
        { backend = "projects/myprj/zones/europe-west8-c/instanceGroups/myig-c" },
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
    managed_configs = {
      default = {
        domains = ["glb-test-0.example.org"]
      }
    }
  }
}
# tftest modules=1 resources=6
```

### Classic vs Non-classic

The module uses a classic Global Load Balancer by default. To use the non-classic version set the `use_classic_version` variable to `false` as in the following example, note that the module is not enforcing feature sets between the two versions:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id          = "myprj"
  name                = "glb-test-0"
  use_classic_version = false
  backend_service_configs = {
    default = {
      backends = [
        { backend = "projects/myprj/zones/europe-west8-b/instanceGroups/myig-b" },
        { backend = "projects/myprj/zones/europe-west8-c/instanceGroups/myig-c" },
      ]
    }
  }
}
# tftest modules=1 resources=5
```

### Health Checks

You can leverage externally defined health checks for backend services, or have the module create them for you.

By default a simple HTTP health check named `default` is created and used in backend services. If you need to override the default, simply define your own health check using the same key (`default`). For more complex configurations you can define your own health checks and reference them via keys in the backend service configurations.

Health checks created by this module are controlled via the `health_check_configs` variable, which behaves in a similar way to other LB modules in this repository. This is an example that overrides the default health check configuration using a TCP health check:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = var.project_id
  name       = "glb-test-0"
  backend_service_configs = {
    default = {
      backends = [{
        backend = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
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
# tftest modules=1 resources=5
```

To leverage existing health checks without having the module create them, simply pass their self links to backend services and set the `health_check_configs` variable to an empty map:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = var.project_id
  name       = "glb-test-0"
  backend_service_configs = {
    default = {
      backends = [{
        backend = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
      }]
      health_checks = ["projects/myprj/global/healthChecks/custom"]
    }
  }
  health_check_configs = {}
}
# tftest modules=1 resources=4
```

### Backend Types and Management

#### Instance Groups

The module can optionally create unmanaged instance groups, which can then be referred to in backends via their key. THis is the simple HTTP example above but with instance group creation managed by the module:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = "myprj"
  name       = "glb-test-0"
  backend_service_configs = {
    default = {
      backends = [
        { backend = "default-b" }
      ]
    }
  }
  group_configs = {
    default-b = {
      zone = "europe-west8-b"
      instances = [
        "projects/myprj/zones/europe-west8-b/instances/vm-a"
      ]
      named_ports = { http = 80 }
    }
  }
}
# tftest modules=1 resources=6
```

#### Storage Buckets

GCS bucket backends can also be managed and used in this module in a similar way to regular backend services.Multiple GCS bucket backends can be defined and referenced in URL maps by their keys (or self links if defined externally) together with regular backend services, [an example is provided later in this document](#complex-example). This is a simple example that defines a GCS backend as the default for the URL map:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = "myprj"
  name       = "glb-test-0"
  backend_buckets_config = {
    default = {
      bucket_name = "tf-playground-svpc-gce-public"
    }
  }
  # with a single GCS backend the implied default health check is not needed
  health_check_configs = {}
}
# tftest modules=1 resources=4
```

#### Network Endpoint Groups (NEGs)

Supported Network Endpoint Groups (NEGs) can also be used as backends. Similarly to groups, you can pass a self link for existing NEGs or have the module manage them for you. A simple example using an existing zonal NEG:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = "myprj"
  name       = "glb-test-0"
  backend_service_configs = {
    default = {
      backends = [
        {
          backend        = "projects/myprj/zones/europe-west8-b/networkEndpointGroups/myneg-b"
          balancing_mode = "RATE"
          max_rate       = { per_endpoint = 10 }
        }
      ]
    }
  }
}
# tftest modules=1 resources=5
```

#### Zonal NEG creation

This example shows how to create and manage zonal NEGs using GCE VMs as endpoints:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = "myprj"
  name       = "glb-test-0"
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
        zone       = "europe-west8-b"
        endpoints = [{
          instance   = "myinstance-b-0"
          ip_address = "10.24.32.25"
          port       = 80
        }]
      }
    }
  }
}
# tftest modules=1 resources=7
```

#### Hybrid NEG creation

This example shows how to create and manage hybrid NEGs:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = "myprj"
  name       = "glb-test-0"
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
        network    = "projects/myprj-host/global/networks/svpc"
        zone       = "europe-west8-b"
        endpoints = [{
          ip_address = "10.0.0.10"
          port       = 80
        }]
      }
    }
  }
}
# tftest modules=1 resources=7
```

#### Internet NEG creation

This example shows how to create and manage internet NEGs:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = "myprj"
  name       = "glb-test-0"
  backend_service_configs = {
    default = {
      backends = [
        { backend = "neg-0" }
      ]
      health_checks = []
    }
  }
  # with a single internet NEG the implied default health check is not needed
  health_check_configs = {}
  neg_configs = {
    neg-0 = {
      internet = {
        use_fqdn  = true
        endpoints = [{
          destination = "www.example.org"
          port = 80
        }]
      }
    }
  }
}
# tftest modules=1 resources=6
```

#### Private Service Connect NEG creation

The module supports managing PSC NEGs if the non-classic version of the load balancer is used:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id          = "myprj"
  name                = "glb-test-0"
  use_classic_version = false
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
        region = "europe-west8"
        target_service = "europe-west8-cloudkms.googleapis.com"
      }
    }
  }
}
# tftest modules=1 resources=5
```

#### Serverless NEG creation

The module supports managing Serverless NEGs for Cloud Run and Cloud Function. This is an example of a Cloud Run NEG:

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = "myprj"
  name       = "glb-test-0"
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
        region = "europe-west8"
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
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = "myprj"
  name       = "glb-test-0"
  backend_service_configs = {
    default = {
      backends = [{
        backend = "projects/myprj/zones/europe-west8-b/instanceGroups/ig-0"
      }]
    }
    other = {
      backends = [{
        backend = "projects/myprj/zones/europe-west8-c/instanceGroups/ig-1"
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
          paths = ["/other", "/other/*"]
          service = "other"
        }]
      }
    }
  }
}

# tftest modules=1 resources=6
```

### SSL Certificates

The module also allows managing managed and self-managed SSL certificates via the `ssl_certificates` variable. Any certificate defined there will be added to the HTTPS proxy resource.

THe [HTTPS example above](#minimal-https-examples) shows how to configure manage certificated, the following example shows how to use an unmanaged (or self managed) certificate. The example uses Terraform resource for the key and certificate so that the we don't depend on external files when running tests,  in real use the key and certificate are generally provided via external files read by the Terraform `file()` function.

```hcl

resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 4096
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

module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = "myprj"
  name       = "glb-test-0"
  backend_service_configs = {
    default = {
      backends = [
        { backend = "projects/myprj/zones/europe-west8-b/instanceGroups/myig-b" },
        { backend = "projects/myprj/zones/europe-west8-c/instanceGroups/myig-c" },
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
# tftest modules=1 resources=8
```

### Complex example

This example mixes group and NEG backends, and shows how to set HTTPS for specific backends.

```hcl
module "glb-0" {
  source     = "./fabric/modules/net-glb"
  project_id = "myprj"
  name       = "glb-test-0"
  backend_buckets_config = {
    gcs-0 = {
      bucket_name = "my-bucket"
    }
  }
  backend_service_configs = {
    default = {
      backends = [
        { backend = "ew8-b" },
        { backend = "ew8-c" },
      ]
    }
    neg-gce-0 = {
      backends = [{
        balancing_mode = "RATE"
        backend          = "neg-ew8-c"
        max_rate       = { per_endpoint = 10 }
      }]
    }
    neg-hybrid-0 = {
      backends = [{
        backend          = "neg-hello"
      }]
      health_checks      = ["neg"]
      protocol           = "HTTPS"
    }
  }
  group_configs = {
    ew8-b = {
      zone = "europe-west8-b"
      instances = [
        "projects/prj-gce/zones/europe-west8-b/instances/nginx-ew8-b"
      ]
      named_ports = { http = 80 }
    }
    ew8-c = {
      zone = "europe-west8-c"
      instances = [
        "projects/prj-gce/zones/europe-west8-c/instances/nginx-ew8-c"
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
    neg-ew8-c = {
      gce = {
        network    = "projects/myprj-host/global/networks/svpc"
        subnetwork = "projects/myprj-host/regions/europe-west8/subnetworks/gce"
        zone = "europe-west8-c"
        endpoints = [{
          instance   = "nginx-ew8-c"
          ip_address = "10.24.32.26"
          port       = 80
        }]
      }
    }
    neg-hello = {
      hybrid = {
        network    = "projects/myprj-host/global/networks/svpc"
        zone      = "europe-west8-b"
        endpoints = [{
          ip_address = "192.168.0.3"
          port       = 443
        }]
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
        default_service = "gcs-0"
      }
    }
  }
}
# tftest modules=1 resources=15
```

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->

## Files

| name | description | resources |
|---|---|---|
| [backend-service.tf](./backend-service.tf) | Backend service resources. | <code>google_compute_backend_service</code> |
| [backends.tf](./backends.tf) | Backend groups and backend buckets resources. | <code>google_compute_backend_bucket</code> · <code>google_compute_instance_group</code> |
| [health-check.tf](./health-check.tf) | Health check resource. | <code>google_compute_health_check</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_compute_global_forwarding_rule</code> · <code>google_compute_managed_ssl_certificate</code> · <code>google_compute_ssl_certificate</code> · <code>google_compute_target_http_proxy</code> · <code>google_compute_target_https_proxy</code> |
| [negs.tf](./negs.tf) | NEG resources. | <code>google_compute_global_network_endpoint</code> · <code>google_compute_global_network_endpoint_group</code> · <code>google_compute_network_endpoint</code> · <code>google_compute_network_endpoint_group</code> · <code>google_compute_region_network_endpoint_group</code> |
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
| [name](variables.tf#L91) | Load balancer name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L193) | Project id. | <code>string</code> | ✓ |  |
| [address](variables.tf#L17) | Optional IP address used for the forwarding rule. | <code>string</code> |  | <code>null</code> |
| [backend_buckets_config](variables.tf#L23) | Backend buckets configuration. | <code title="map&#40;object&#40;&#123;&#10;  bucket_name             &#61; string&#10;  compression_mode        &#61; optional&#40;string&#41;&#10;  custom_response_headers &#61; optional&#40;list&#40;string&#41;&#41;&#10;  description             &#61; optional&#40;string&#41;&#10;  edge_security_policy    &#61; optional&#40;string&#41;&#10;  enable_cdn              &#61; optional&#40;bool&#41;&#10;  cdn_policy &#61; optional&#40;object&#40;&#123;&#10;    bypass_cache_on_request_headers &#61; optional&#40;list&#40;string&#41;&#41;&#10;    cache_mode                      &#61; optional&#40;string&#41;&#10;    client_ttl                      &#61; optional&#40;number&#41;&#10;    default_ttl                     &#61; optional&#40;number&#41;&#10;    max_ttl                         &#61; optional&#40;number&#41;&#10;    negative_caching                &#61; optional&#40;bool&#41;&#10;    request_coalescing              &#61; optional&#40;bool&#41;&#10;    serve_while_stale               &#61; optional&#40;bool&#41;&#10;    signed_url_cache_max_age_sec    &#61; optional&#40;number&#41;&#10;    cache_key_policy &#61; optional&#40;object&#40;&#123;&#10;      include_http_headers   &#61; optional&#40;list&#40;string&#41;&#41;&#10;      query_string_whitelist &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    negative_caching_policy &#61; optional&#40;object&#40;&#123;&#10;      code &#61; optional&#40;number&#41;&#10;      ttl  &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [backend_service_configs](variables-backend-service.tf#L19) | Backend service level configuration. | <code title="map&#40;object&#40;&#123;&#10;  affinity_cookie_ttl_sec         &#61; optional&#40;number&#41;&#10;  compression_mode                &#61; optional&#40;string&#41;&#10;  connection_draining_timeout_sec &#61; optional&#40;number&#41;&#10;  custom_request_headers          &#61; optional&#40;list&#40;string&#41;&#41;&#10;  custom_response_headers         &#61; optional&#40;list&#40;string&#41;&#41;&#10;  enable_cdn                      &#61; optional&#40;bool&#41;&#10;  health_checks                   &#61; optional&#40;list&#40;string&#41;, &#91;&#34;default&#34;&#93;&#41;&#10;  log_sample_rate                 &#61; optional&#40;number&#41;&#10;  port_name                       &#61; optional&#40;string&#41;&#10;  project_id                      &#61; optional&#40;string&#41;&#10;  protocol                        &#61; optional&#40;string&#41;&#10;  security_policy                 &#61; optional&#40;string&#41;&#10;  session_affinity                &#61; optional&#40;string&#41;&#10;  timeout_sec                     &#61; optional&#40;number&#41;&#10;  backends &#61; list&#40;object&#40;&#123;&#10;    backend         &#61; string&#10;    balancing_mode  &#61; optional&#40;string, &#34;UTILIZATION&#34;&#41;&#10;    capacity_scaler &#61; optional&#40;number, 1&#41;&#10;    description     &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;    failover        &#61; optional&#40;bool, false&#41;&#10;    max_connections &#61; optional&#40;object&#40;&#123;&#10;      per_endpoint &#61; optional&#40;number&#41;&#10;      per_group    &#61; optional&#40;number&#41;&#10;      per_instance &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    max_rate &#61; optional&#40;object&#40;&#123;&#10;      per_endpoint &#61; optional&#40;number&#41;&#10;      per_group    &#61; optional&#40;number&#41;&#10;      per_instance &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    max_utilization &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  cdn_policy &#61; optional&#40;object&#40;&#123;&#10;    cache_mode                   &#61; optional&#40;string&#41;&#10;    client_ttl                   &#61; optional&#40;number&#41;&#10;    default_ttl                  &#61; optional&#40;number&#41;&#10;    max_ttl                      &#61; optional&#40;number&#41;&#10;    negative_caching             &#61; optional&#40;bool&#41;&#10;    serve_while_stale            &#61; optional&#40;bool&#41;&#10;    signed_url_cache_max_age_sec &#61; optional&#40;number&#41;&#10;    cache_key_policy &#61; optional&#40;object&#40;&#123;&#10;      include_host           &#61; optional&#40;bool&#41;&#10;      include_named_cookies  &#61; optional&#40;list&#40;string&#41;&#41;&#10;      include_protocol       &#61; optional&#40;bool&#41;&#10;      include_query_string   &#61; optional&#40;bool&#41;&#10;      query_string_blacklist &#61; optional&#40;list&#40;string&#41;&#41;&#10;      query_string_whitelist &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    negative_caching_policy &#61; optional&#40;object&#40;&#123;&#10;      code &#61; optional&#40;number&#41;&#10;      ttl  &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  circuit_breakers &#61; optional&#40;object&#40;&#123;&#10;    max_connections             &#61; optional&#40;number&#41;&#10;    max_pending_requests        &#61; optional&#40;number&#41;&#10;    max_requests                &#61; optional&#40;number&#41;&#10;    max_requests_per_connection &#61; optional&#40;number&#41;&#10;    max_retries                 &#61; optional&#40;number&#41;&#10;    connect_timeout &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  consistent_hash &#61; optional&#40;object&#40;&#123;&#10;    http_header_name  &#61; optional&#40;string&#41;&#10;    minimum_ring_size &#61; optional&#40;number&#41;&#10;    http_cookie &#61; optional&#40;object&#40;&#123;&#10;      name &#61; optional&#40;string&#41;&#10;      path &#61; optional&#40;string&#41;&#10;      ttl &#61; optional&#40;object&#40;&#123;&#10;        seconds &#61; number&#10;        nanos   &#61; optional&#40;number&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  iap_config &#61; optional&#40;object&#40;&#123;&#10;    oauth2_client_id            &#61; string&#10;    oauth2_client_secret        &#61; string&#10;    oauth2_client_secret_sha256 &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  outlier_detection &#61; optional&#40;object&#40;&#123;&#10;    consecutive_errors                    &#61; optional&#40;number&#41;&#10;    consecutive_gateway_failure           &#61; optional&#40;number&#41;&#10;    enforcing_consecutive_errors          &#61; optional&#40;number&#41;&#10;    enforcing_consecutive_gateway_failure &#61; optional&#40;number&#41;&#10;    enforcing_success_rate                &#61; optional&#40;number&#41;&#10;    max_ejection_percent                  &#61; optional&#40;number&#41;&#10;    success_rate_minimum_hosts            &#61; optional&#40;number&#41;&#10;    success_rate_request_volume           &#61; optional&#40;number&#41;&#10;    success_rate_stdev_factor             &#61; optional&#40;number&#41;&#10;    base_ejection_time &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    interval &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  security_settings &#61; optional&#40;object&#40;&#123;&#10;    client_tls_policy &#61; string&#10;    subject_alt_names &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L56) | Optional description used for resources. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [group_configs](variables.tf#L62) | Optional unmanaged groups to create. Can be referenced in backends via key or outputs. | <code title="map&#40;object&#40;&#123;&#10;  zone        &#61; string&#10;  instances   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  named_ports &#61; optional&#40;map&#40;number&#41;, &#123;&#125;&#41;&#10;  project_id  &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_check_configs](variables-health-check.tf#L19) | Optional auto-created health check configurations, use the output self-link to set it in the auto healing policy. Refer to examples for usage. | <code title="map&#40;object&#40;&#123;&#10;  check_interval_sec  &#61; optional&#40;number&#41;&#10;  description         &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  enable_logging      &#61; optional&#40;bool, false&#41;&#10;  healthy_threshold   &#61; optional&#40;number&#41;&#10;  project_id          &#61; optional&#40;string&#41;&#10;  timeout_sec         &#61; optional&#40;number&#41;&#10;  unhealthy_threshold &#61; optional&#40;number&#41;&#10;  grpc &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    service_name       &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  http &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  http2 &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  https &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  tcp &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request            &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  ssl &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request            &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  default &#61; &#123;&#10;    http &#61; &#123;&#10;      port_specification &#61; &#34;USE_SERVING_PORT&#34;&#10;    &#125;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [https_proxy_config](variables.tf#L74) | HTTPS proxy connfiguration. | <code title="object&#40;&#123;&#10;  certificate_map &#61; optional&#40;string&#41;&#10;  quic_override   &#61; optional&#40;string&#41;&#10;  ssl_policy      &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L85) | Labels set on resources. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [neg_configs](variables.tf#L96) | Optional network endpoint groups to create. Can be referenced in backends via key or outputs. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string&#41;&#10;  cloudfunction &#61; optional&#40;object&#40;&#123;&#10;    region          &#61; string&#10;    target_function &#61; optional&#40;string&#41;&#10;    target_urlmask  &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  cloudrun &#61; optional&#40;object&#40;&#123;&#10;    region &#61; string&#10;    target_service &#61; optional&#40;object&#40;&#123;&#10;      name &#61; string&#10;      tag  &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    target_urlmask &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  gce &#61; optional&#40;object&#40;&#123;&#10;    network    &#61; string&#10;    subnetwork &#61; string&#10;    zone       &#61; string&#10;    endpoints &#61; optional&#40;list&#40;object&#40;&#123;&#10;      instance   &#61; string&#10;      ip_address &#61; string&#10;      port       &#61; number&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  hybrid &#61; optional&#40;object&#40;&#123;&#10;    network &#61; string&#10;    zone    &#61; string&#10;    endpoints &#61; optional&#40;list&#40;object&#40;&#123;&#10;      ip_address &#61; string&#10;      port       &#61; number&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  internet &#61; optional&#40;object&#40;&#123;&#10;    use_fqdn &#61; optional&#40;bool, true&#41;&#10;    endpoints &#61; optional&#40;list&#40;object&#40;&#123;&#10;      destination &#61; string&#10;      port        &#61; number&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  psc &#61; optional&#40;object&#40;&#123;&#10;    region         &#61; string&#10;    target_service &#61; string&#10;    network        &#61; optional&#40;string&#41;&#10;    subnetwork     &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ports](variables.tf#L187) | Optional ports for HTTP load balancer, valid ports are 80 and 8080. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [protocol](variables.tf#L198) | Protocol supported by this load balancer. | <code>string</code> |  | <code>&#34;HTTP&#34;</code> |
| [ssl_certificates](variables.tf#L211) | SSL target proxy certificates (only if protocol is HTTPS) for existing, custom, and managed certificates. | <code title="object&#40;&#123;&#10;  certificate_ids &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  create_configs &#61; optional&#40;map&#40;object&#40;&#123;&#10;    certificate &#61; string&#10;    private_key &#61; string&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  managed_configs &#61; optional&#40;map&#40;object&#40;&#123;&#10;    domains     &#61; list&#40;string&#41;&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [urlmap_config](variables-urlmap.tf#L19) | The URL map configuration. | <code title="object&#40;&#123;&#10;  default_route_action &#61; optional&#40;object&#40;&#123;&#10;    request_mirror_backend &#61; optional&#40;string&#41;&#10;    cors_policy &#61; optional&#40;object&#40;&#123;&#10;      allow_credentials    &#61; optional&#40;bool&#41;&#10;      allow_headers        &#61; optional&#40;string&#41;&#10;      allow_methods        &#61; optional&#40;string&#41;&#10;      allow_origin_regexes &#61; list&#40;string&#41;&#10;      allow_origins        &#61; list&#40;string&#41;&#10;      disabled             &#61; optional&#40;bool&#41;&#10;      expose_headers       &#61; optional&#40;string&#41;&#10;      max_age              &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    fault_injection_policy &#61; optional&#40;object&#40;&#123;&#10;      abort &#61; optional&#40;object&#40;&#123;&#10;        percentage &#61; number&#10;        status     &#61; number&#10;      &#125;&#41;&#41;&#10;      delay &#61; optional&#40;object&#40;&#123;&#10;        fixed &#61; object&#40;&#123;&#10;          seconds &#61; number&#10;          nanos   &#61; number&#10;        &#125;&#41;&#10;        percentage &#61; number&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    retry_policy &#61; optional&#40;object&#40;&#123;&#10;      num_retries      &#61; number&#10;      retry_conditions &#61; optional&#40;list&#40;string&#41;&#41;&#10;      per_try_timeout &#61; optional&#40;object&#40;&#123;&#10;        seconds &#61; number&#10;        nanos   &#61; optional&#40;number&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    timeout &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    url_rewrite &#61; optional&#40;object&#40;&#123;&#10;      host        &#61; optional&#40;string&#41;&#10;      path_prefix &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    weighted_backend_services &#61; optional&#40;map&#40;object&#40;&#123;&#10;      weight &#61; number&#10;      header_action &#61; optional&#40;object&#40;&#123;&#10;        request_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;          value   &#61; string&#10;          replace &#61; optional&#40;bool, true&#41;&#10;        &#125;&#41;&#41;&#41;&#10;        request_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;        response_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;          value   &#61; string&#10;          replace &#61; optional&#40;bool, true&#41;&#10;        &#125;&#41;&#41;&#41;&#10;        response_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  default_service &#61; optional&#40;string&#41;&#10;  default_url_redirect &#61; optional&#40;object&#40;&#123;&#10;    host          &#61; optional&#40;string&#41;&#10;    https         &#61; optional&#40;bool&#41;&#10;    path          &#61; optional&#40;string&#41;&#10;    prefix        &#61; optional&#40;string&#41;&#10;    response_code &#61; optional&#40;string&#41;&#10;    strip_query   &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  header_action &#61; optional&#40;object&#40;&#123;&#10;    request_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;      value   &#61; string&#10;      replace &#61; optional&#40;bool, true&#41;&#10;    &#125;&#41;&#41;&#41;&#10;    request_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;    response_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;      value   &#61; string&#10;      replace &#61; optional&#40;bool, true&#41;&#10;    &#125;&#41;&#41;&#41;&#10;    response_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  host_rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;    hosts        &#61; list&#40;string&#41;&#10;    path_matcher &#61; string&#10;    description  &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  path_matchers &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description &#61; optional&#40;string&#41;&#10;    default_route_action &#61; optional&#40;object&#40;&#123;&#10;      request_mirror_backend &#61; optional&#40;string&#41;&#10;      cors_policy &#61; optional&#40;object&#40;&#123;&#10;        allow_credentials    &#61; optional&#40;bool&#41;&#10;        allow_headers        &#61; optional&#40;string&#41;&#10;        allow_methods        &#61; optional&#40;string&#41;&#10;        allow_origin_regexes &#61; list&#40;string&#41;&#10;        allow_origins        &#61; list&#40;string&#41;&#10;        disabled             &#61; optional&#40;bool&#41;&#10;        expose_headers       &#61; optional&#40;string&#41;&#10;        max_age              &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      fault_injection_policy &#61; optional&#40;object&#40;&#123;&#10;        abort &#61; optional&#40;object&#40;&#123;&#10;          percentage &#61; number&#10;          status     &#61; number&#10;        &#125;&#41;&#41;&#10;        delay &#61; optional&#40;object&#40;&#123;&#10;          fixed &#61; object&#40;&#123;&#10;            seconds &#61; number&#10;            nanos   &#61; number&#10;          &#125;&#41;&#10;          percentage &#61; number&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      retry_policy &#61; optional&#40;object&#40;&#123;&#10;        num_retries      &#61; number&#10;        retry_conditions &#61; optional&#40;list&#40;string&#41;&#41;&#10;        per_try_timeout &#61; optional&#40;object&#40;&#123;&#10;          seconds &#61; number&#10;          nanos   &#61; optional&#40;number&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      timeout &#61; optional&#40;object&#40;&#123;&#10;        seconds &#61; number&#10;        nanos   &#61; optional&#40;number&#41;&#10;      &#125;&#41;&#41;&#10;      url_rewrite &#61; optional&#40;object&#40;&#123;&#10;        host        &#61; optional&#40;string&#41;&#10;        path_prefix &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      weighted_backend_services &#61; optional&#40;map&#40;object&#40;&#123;&#10;        weight &#61; number&#10;        header_action &#61; optional&#40;object&#40;&#123;&#10;          request_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;            value   &#61; string&#10;            replace &#61; optional&#40;bool, true&#41;&#10;          &#125;&#41;&#41;&#41;&#10;          request_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;          response_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;            value   &#61; string&#10;            replace &#61; optional&#40;bool, true&#41;&#10;          &#125;&#41;&#41;&#41;&#10;          response_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    default_service &#61; optional&#40;string&#41;&#10;    default_url_redirect &#61; optional&#40;object&#40;&#123;&#10;      host          &#61; optional&#40;string&#41;&#10;      https         &#61; optional&#40;bool&#41;&#10;      path          &#61; optional&#40;string&#41;&#10;      prefix        &#61; optional&#40;string&#41;&#10;      response_code &#61; optional&#40;string&#41;&#10;      strip_query   &#61; optional&#40;bool&#41;&#10;    &#125;&#41;&#41;&#10;    header_action &#61; optional&#40;object&#40;&#123;&#10;      request_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;        value   &#61; string&#10;        replace &#61; optional&#40;bool, true&#41;&#10;      &#125;&#41;&#41;&#41;&#10;      request_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;      response_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;        value   &#61; string&#10;        replace &#61; optional&#40;bool, true&#41;&#10;      &#125;&#41;&#41;&#41;&#10;      response_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    path_rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;      paths   &#61; list&#40;string&#41;&#10;      service &#61; optional&#40;string&#41;&#10;      route_action &#61; optional&#40;object&#40;&#123;&#10;        request_mirror_backend &#61; optional&#40;string&#41;&#10;        cors_policy &#61; optional&#40;object&#40;&#123;&#10;          allow_credentials    &#61; optional&#40;bool&#41;&#10;          allow_headers        &#61; optional&#40;string&#41;&#10;          allow_methods        &#61; optional&#40;string&#41;&#10;          allow_origin_regexes &#61; list&#40;string&#41;&#10;          allow_origins        &#61; list&#40;string&#41;&#10;          disabled             &#61; optional&#40;bool&#41;&#10;          expose_headers       &#61; optional&#40;string&#41;&#10;          max_age              &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;        fault_injection_policy &#61; optional&#40;object&#40;&#123;&#10;          abort &#61; optional&#40;object&#40;&#123;&#10;            percentage &#61; number&#10;            status     &#61; number&#10;          &#125;&#41;&#41;&#10;          delay &#61; optional&#40;object&#40;&#123;&#10;            fixed &#61; object&#40;&#123;&#10;              seconds &#61; number&#10;              nanos   &#61; number&#10;            &#125;&#41;&#10;            percentage &#61; number&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        retry_policy &#61; optional&#40;object&#40;&#123;&#10;          num_retries      &#61; number&#10;          retry_conditions &#61; optional&#40;list&#40;string&#41;&#41;&#10;          per_try_timeout &#61; optional&#40;object&#40;&#123;&#10;            seconds &#61; number&#10;            nanos   &#61; optional&#40;number&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        timeout &#61; optional&#40;object&#40;&#123;&#10;          seconds &#61; number&#10;          nanos   &#61; optional&#40;number&#41;&#10;        &#125;&#41;&#41;&#10;        url_rewrite &#61; optional&#40;object&#40;&#123;&#10;          host        &#61; optional&#40;string&#41;&#10;          path_prefix &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;        weighted_backend_services &#61; optional&#40;map&#40;object&#40;&#123;&#10;          weight &#61; number&#10;          header_action &#61; optional&#40;object&#40;&#123;&#10;            request_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;              value   &#61; string&#10;              replace &#61; optional&#40;bool, true&#41;&#10;            &#125;&#41;&#41;&#41;&#10;            request_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;            response_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;              value   &#61; string&#10;              replace &#61; optional&#40;bool, true&#41;&#10;            &#125;&#41;&#41;&#41;&#10;            response_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      url_redirect &#61; optional&#40;object&#40;&#123;&#10;        host          &#61; optional&#40;string&#41;&#10;        https         &#61; optional&#40;bool&#41;&#10;        path          &#61; optional&#40;string&#41;&#10;        prefix        &#61; optional&#40;string&#41;&#10;        response_code &#61; optional&#40;string&#41;&#10;        strip_query   &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#41;&#10;    route_rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;      priority &#61; number&#10;      service  &#61; optional&#40;string&#41;&#10;      header_action &#61; optional&#40;object&#40;&#123;&#10;        request_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;          value   &#61; string&#10;          replace &#61; optional&#40;bool, true&#41;&#10;        &#125;&#41;&#41;&#41;&#10;        request_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;        response_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;          value   &#61; string&#10;          replace &#61; optional&#40;bool, true&#41;&#10;        &#125;&#41;&#41;&#41;&#10;        response_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      match_rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;        ignore_case &#61; optional&#40;bool, false&#41;&#10;        headers &#61; optional&#40;list&#40;object&#40;&#123;&#10;          name         &#61; string&#10;          invert_match &#61; optional&#40;bool, false&#41;&#10;          type         &#61; optional&#40;string, &#34;present&#34;&#41; &#35; exact, prefix, suffix, regex, present, range&#10;          value        &#61; optional&#40;string&#41;&#10;          range_value &#61; optional&#40;object&#40;&#123;&#10;            end   &#61; string&#10;            start &#61; string&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#41;&#10;        metadata_filters &#61; optional&#40;list&#40;object&#40;&#123;&#10;          labels    &#61; map&#40;string&#41;&#10;          match_all &#61; bool &#35; MATCH_ANY, MATCH_ALL&#10;        &#125;&#41;&#41;&#41;&#10;        path &#61; optional&#40;object&#40;&#123;&#10;          value &#61; string&#10;          type  &#61; optional&#40;string, &#34;prefix&#34;&#41; &#35; full, prefix, regex&#10;        &#125;&#41;&#41;&#10;        query_params &#61; optional&#40;list&#40;object&#40;&#123;&#10;          name  &#61; string&#10;          value &#61; string&#10;          type  &#61; optional&#40;string, &#34;present&#34;&#41; &#35; exact, present, regex&#10;        &#125;&#41;&#41;&#41;&#10;      &#125;&#41;&#41;&#41;&#10;      route_action &#61; optional&#40;object&#40;&#123;&#10;        request_mirror_backend &#61; optional&#40;string&#41;&#10;        cors_policy &#61; optional&#40;object&#40;&#123;&#10;          allow_credentials    &#61; optional&#40;bool&#41;&#10;          allow_headers        &#61; optional&#40;string&#41;&#10;          allow_methods        &#61; optional&#40;string&#41;&#10;          allow_origin_regexes &#61; list&#40;string&#41;&#10;          allow_origins        &#61; list&#40;string&#41;&#10;          disabled             &#61; optional&#40;bool&#41;&#10;          expose_headers       &#61; optional&#40;string&#41;&#10;          max_age              &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;        fault_injection_policy &#61; optional&#40;object&#40;&#123;&#10;          abort &#61; optional&#40;object&#40;&#123;&#10;            percentage &#61; number&#10;            status     &#61; number&#10;          &#125;&#41;&#41;&#10;          delay &#61; optional&#40;object&#40;&#123;&#10;            fixed &#61; object&#40;&#123;&#10;              seconds &#61; number&#10;              nanos   &#61; number&#10;            &#125;&#41;&#10;            percentage &#61; number&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        retry_policy &#61; optional&#40;object&#40;&#123;&#10;          num_retries      &#61; number&#10;          retry_conditions &#61; optional&#40;list&#40;string&#41;&#41;&#10;          per_try_timeout &#61; optional&#40;object&#40;&#123;&#10;            seconds &#61; number&#10;            nanos   &#61; optional&#40;number&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        timeout &#61; optional&#40;object&#40;&#123;&#10;          seconds &#61; number&#10;          nanos   &#61; optional&#40;number&#41;&#10;        &#125;&#41;&#41;&#10;        url_rewrite &#61; optional&#40;object&#40;&#123;&#10;          host        &#61; optional&#40;string&#41;&#10;          path_prefix &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;        weighted_backend_services &#61; optional&#40;map&#40;object&#40;&#123;&#10;          weight &#61; number&#10;          header_action &#61; optional&#40;object&#40;&#123;&#10;            request_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;              value   &#61; string&#10;              replace &#61; optional&#40;bool, true&#41;&#10;            &#125;&#41;&#41;&#41;&#10;            request_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;            response_add &#61; optional&#40;map&#40;object&#40;&#123;&#10;              value   &#61; string&#10;              replace &#61; optional&#40;bool, true&#41;&#10;            &#125;&#41;&#41;&#41;&#10;            response_remove &#61; optional&#40;list&#40;string&#41;&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      url_redirect &#61; optional&#40;object&#40;&#123;&#10;        host          &#61; optional&#40;string&#41;&#10;        https         &#61; optional&#40;bool&#41;&#10;        path          &#61; optional&#40;string&#41;&#10;        prefix        &#61; optional&#40;string&#41;&#10;        response_code &#61; optional&#40;string&#41;&#10;        strip_query   &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  test &#61; optional&#40;list&#40;object&#40;&#123;&#10;    host        &#61; string&#10;    path        &#61; string&#10;    service     &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  default_service &#61; &#34;default&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [use_classic_version](variables.tf#L228) | Use classic Global Load Balancer. | <code>bool</code> |  | <code>true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [address](outputs.tf#L17) | Forwarding rule address. |  |
| [backend_service_ids](outputs.tf#L22) | Backend service resources. |  |
| [forwarding_rule](outputs.tf#L29) | Forwarding rule resource. |  |
| [group_ids](outputs.tf#L34) | Autogenerated instance group ids. |  |
| [health_check_ids](outputs.tf#L41) | Autogenerated health check ids. |  |
| [neg_ids](outputs.tf#L48) | Autogenerated network endpoint group ids. |  |

<!-- END TFDOC -->
