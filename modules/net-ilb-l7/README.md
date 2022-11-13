# Internal (HTTP/S) Load Balancer Module

The module allows managing Internal HTTP/HTTPS Load Balancers (HTTP(S) ILBs), integrating the forwarding rule, the url-map, the backends, optional health checks and SSL certificates.

It's designed to be a simple match for the [`vpc`](../net-vpc) and the [`compute-mig`](../compute-mig) modules, which can be used to manage VPCs and instance groups.

## Examples

### Minimal Example

An HTTP ILB with a backend service pointing to a GCE instance group:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
      }]
    }
  }
  urlmap_config = {
    default_service = "default"
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=5
```

An HTTPS ILB needs a few additional fields:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
      }]
    }
  }
  protocol = "HTTPS"
  ssl_certificates = {
    certificate_ids = [
      "projects/myprj/regions/europe-west1/sslCertificates/my-cert"
    ]
  }
  urlmap_config = {
    default_service = "default"
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=5
```

### Health Checks

You can leverage externally defined health checks for backend services, or have the module create them for you. By default a simple HTTP health check is created, and used in backend services.

Health check configuration is controlled via the `health_check_configs` variable, which behaves in a similar way to other LB modules in this repository.

Defining different health checks fromt he default is very easy. You can for example replace the default HTTP health check with a TCP one and reference it in you backend service:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
      }]
      health_checks = ["custom-tcp"]
    }
  }
  health_check_configs = {
    custom-tcp = {
      tcp = { port = 80 }
    }
  }
  urlmap_config = {
    default_service = "default"
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=5
```

To leverage existing health checks without having the module create them, simply pass their self links to backend services and set the `health_check_configs` variable to an empty map:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
      }]
      health_checks = ["projects/myprj/global/healthChecks/custom"]
    }
  }
  health_check_configs = {}
  urlmap_config = {
    default_service = "default"
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=4
```

### SSL Certificates

Similarly to health checks, SSL certificates can also be created by the module. In this example we are using private key and certificate resources so that the example test only depends on Terraform providers, but in real use those can be replaced by external files.

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

module "ilb-l7" {
  source     = "./fabric/modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
      }]
    }
  }
  health_check_configs = {
    default = {
      https = { port = 443 }
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
  urlmap_config = {
    default_service = "default"
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=8
```

### Instance Groups

The module can optionally create unmanaged instance groups, which can then be referred to in backends via their key:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      port_name = "http"
      backends  = [
        { group = "default" }
      ]
    }
  }
  group_configs = {
    default = {
      zone = "europe-west1-b"
      instances = [
        "projects/myprj/zones/europe-west1-b/instances/vm-a"
      ]
      named_ports = {
        http = 80
      }
    }
  }
  urlmap_config = {
    default_service = "default"
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=6
```

### Network Endpoint Groups (NEGs)

Zonal Network Endpoint Groups (NEGs) can be used as backends, by passing their id as the backend group in a backends service configuration:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/networkEndpointGroups/my-neg"
      }]
    }
  }
  urlmap_config = {
    default_service = "default"
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=5
```

Similarly to instance groups, NEGs can also be managed by this module:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [
        { group = "my-neg" }
      ]
    }
  }
  neg_configs = {
    my-neg = {
      zone = "europe-west1-b"
      endpoints = [
        {
          ip_address = "10.0.0.10"
          instance   = "test-1"
        }
      ]
    }
  }
  urlmap_config = {
    default_service = "default"
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=7
```

### URL Map

The module exposes the full URL map resource configuration, with some minor changes to the interface to decrease verbosity, and support for aliasing backend services via keys:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
      }]
    }
    video = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig-2"
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
        path_rules = [{
          paths = ["/video", "/video/*"]
          service = "video"
        }]
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

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->

## Files

| name | description | resources |
|---|---|---|
| [backend-services.tf](./backend-services.tf) | Bucket and group backend services. | <code>google_compute_region_backend_service</code> |
| [forwarding-rule.tf](./forwarding-rule.tf) | IP Address and forwarding rule. | <code>google_compute_address</code> · <code>google_compute_forwarding_rule</code> |
| [health-checks.tf](./health-checks.tf) | Health checks. | <code>google_compute_region_health_check</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [ssl-certificates.tf](./ssl-certificates.tf) | SSL certificates. | <code>google_compute_region_ssl_certificate</code> |
| [target-proxy.tf](./target-proxy.tf) | HTTP and HTTPS target proxies. | <code>google_compute_region_target_http_proxy</code> · <code>google_compute_region_target_https_proxy</code> |
| [url-map.tf](./url-map.tf) | URL maps. | <code>google_compute_region_url_map</code> |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L17) | Load balancer name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L22) | Project id. | <code>string</code> | ✓ |  |
| [region](variables.tf#L159) | The region where to allocate the ILB resources. | <code>string</code> | ✓ |  |
| [subnetwork](variables.tf#L189) | The subnetwork where the ILB VIP is allocated. | <code>string</code> | ✓ |  |
| [backend_services_config](variables.tf#L27) | The backends services configuration. | <code title="map&#40;object&#40;&#123;&#10;  backends &#61; list&#40;object&#40;&#123;&#10;    group &#61; string &#35; The instance group link id&#10;    options &#61; object&#40;&#123;&#10;      balancing_mode               &#61; string &#35; Can be UTILIZATION, RATE&#10;      capacity_scaler              &#61; number &#35; Valid range is &#91;0.0,1.0&#93;&#10;      max_connections              &#61; number&#10;      max_connections_per_instance &#61; number&#10;      max_connections_per_endpoint &#61; number&#10;      max_rate                     &#61; number&#10;      max_rate_per_instance        &#61; number&#10;      max_rate_per_endpoint        &#61; number&#10;      max_utilization              &#61; number&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;  health_checks &#61; list&#40;string&#41;&#10;&#10;&#10;  log_config &#61; object&#40;&#123;&#10;    enable      &#61; bool&#10;    sample_rate &#61; number &#35; must be in &#91;0, 1&#93;&#10;  &#125;&#41;&#10;&#10;&#10;  options &#61; object&#40;&#123;&#10;    affinity_cookie_ttl_sec         &#61; number&#10;    custom_request_headers          &#61; list&#40;string&#41;&#10;    custom_response_headers         &#61; list&#40;string&#41;&#10;    connection_draining_timeout_sec &#61; number&#10;    locality_lb_policy              &#61; string&#10;    port_name                       &#61; string&#10;    protocol                        &#61; string&#10;    session_affinity                &#61; string&#10;    timeout_sec                     &#61; number&#10;&#10;&#10;    circuits_breakers &#61; object&#40;&#123;&#10;      max_requests_per_connection &#61; number &#35; Set to 1 to disable keep-alive&#10;      max_connections             &#61; number &#35; Defaults to 1024&#10;      max_pending_requests        &#61; number &#35; Defaults to 1024&#10;      max_requests                &#61; number &#35; Defaults to 1024&#10;      max_retries                 &#61; number &#35; Defaults to 3&#10;    &#125;&#41;&#10;&#10;&#10;    consistent_hash &#61; object&#40;&#123;&#10;      http_header_name  &#61; string&#10;      minimum_ring_size &#61; string&#10;      http_cookie &#61; object&#40;&#123;&#10;        name &#61; string&#10;        path &#61; string&#10;        ttl &#61; object&#40;&#123;&#10;          seconds &#61; number&#10;          nanos   &#61; number&#10;        &#125;&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#10;&#10;&#10;    iap &#61; object&#40;&#123;&#10;      oauth2_client_id            &#61; string&#10;      oauth2_client_secret        &#61; string&#10;      oauth2_client_secret_sha256 &#61; string&#10;    &#125;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [forwarding_rule_config](variables.tf#L98) | Forwarding rule configurations. | <code title="object&#40;&#123;&#10;  ip_version    &#61; string&#10;  labels        &#61; map&#40;string&#41;&#10;  network_tier  &#61; string&#10;  port_range    &#61; string&#10;  service_label &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  allow_global_access &#61; true&#10;  ip_version          &#61; &#34;IPV4&#34;&#10;  labels              &#61; &#123;&#125;&#10;  network_tier        &#61; &#34;PREMIUM&#34;&#10;  port_range    &#61; null&#10;  service_label &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |
| [health_checks_config](variables.tf#L118) | Custom health checks configuration. | <code title="map&#40;object&#40;&#123;&#10;  type    &#61; string      &#35; http https tcp ssl http2&#10;  check   &#61; map&#40;any&#41;    &#35; actual health check block attributes&#10;  options &#61; map&#40;number&#41; &#35; interval, thresholds, timeout&#10;  logging &#61; bool&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_checks_config_defaults](variables.tf#L129) | Auto-created health check default configuration. | <code title="object&#40;&#123;&#10;  check   &#61; map&#40;any&#41; &#35; actual health check block attributes&#10;  logging &#61; bool&#10;  options &#61; map&#40;number&#41; &#35; interval, thresholds, timeout&#10;  type    &#61; string      &#35; http https tcp ssl http2&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  type    &#61; &#34;http&#34;&#10;  logging &#61; false&#10;  options &#61; &#123;&#125;&#10;  check &#61; &#123;&#10;    port_specification &#61; &#34;USE_SERVING_PORT&#34;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [https](variables.tf#L147) | Whether to enable HTTPS. | <code>bool</code> |  | <code>false</code> |
| [network](variables.tf#L153) | The network where the ILB is created. | <code>string</code> |  | <code>&#34;default&#34;</code> |
| [ssl_certificates_config](variables.tf#L164) | The SSL certificates configuration. | <code title="map&#40;object&#40;&#123;&#10;  domains              &#61; list&#40;string&#41;&#10;  tls_private_key      &#61; string&#10;  tls_self_signed_cert &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [static_ip_config](variables.tf#L174) | Static IP address configuration. | <code title="object&#40;&#123;&#10;  reserve &#61; bool&#10;  options &#61; object&#40;&#123;&#10;    address    &#61; string&#10;    subnetwork &#61; string &#35; The subnet id&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  reserve &#61; false&#10;  options &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |
| [target_proxy_https_config](variables.tf#L194) | The HTTPS target proxy configuration. | <code title="object&#40;&#123;&#10;  ssl_certificates &#61; list&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [url_map_config](variables.tf#L202) | The url-map configuration. | <code title="object&#40;&#123;&#10;  default_service      &#61; string&#10;  default_url_redirect &#61; map&#40;any&#41;&#10;  host_rules           &#61; list&#40;any&#41;&#10;  path_matchers        &#61; list&#40;any&#41;&#10;  tests                &#61; list&#40;map&#40;string&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [backend_services](outputs.tf#L22) | Backend service resources. |  |
| [forwarding_rule](outputs.tf#L55) | The forwarding rule. |  |
| [health_checks](outputs.tf#L17) | Health-check resources. |  |
| [ip_address](outputs.tf#L41) | The reserved IP address. |  |
| [ssl_certificate_link_ids](outputs.tf#L34) | The SSL certificate. |  |
| [target_proxy](outputs.tf#L46) | The target proxy. |  |
| [url_map](outputs.tf#L29) | The url-map. |  |

<!-- END TFDOC -->
