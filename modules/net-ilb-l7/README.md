# Internal (HTTP/S) Load Balancer Module

The module allows managing Internal HTTP/HTTPS Load Balancers (HTTP(S) ILBs), integrating the forwarding rule, the url-map, the backends, optional health checks and SSL certificates.
It's designed to be a simple match for the [`vpc`](../net-vpc) and the [`compute-mig`](../compute-mig) modules, which can be used to manage VPCs and instance groups.

## Examples

### Minimal Example

An HTTP ILB with a backend service pointing to a GCE instance group:

```hcl
module "ilb" {
  source     = "./modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"

  backend_services_config = {
    my-backend-svc = {
      enable_cdn    = false
      cdn_config    = null
      backends = [
        {
          group   = "my_test_mig"
          options = null
        }
      ]
      health_checks = []
      log_config = null
      options = null
    }
  }
}
# tftest modules=1 resources=5
```

### Defining Health Checks

If no health checks are specified, a default health check is created and associated to each backend service without health checks already associated. The default health check configuration can be modified through the `health_checks_config_defaults` variable.

If the `health_checks_config_defaults` variable is set to null, no default health checks will be automatically associted to backend services.

Alternatively, one or more health checks can be either contextually created or attached, if existing. If the id of the health checks specified is equal to one of the keys of the `health_checks_config` variable, the health check is contextually created; otherwise, the health check id is used as is, assuming an health check with that id alredy exists.

For example, to contextually create a health check and attach it to the backend service:

```hcl
module "glb" {
  source     = "./modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"

  backend_services_config = {
    my-backend-svc = {
      enable_cdn    = false
      cdn_config    = null
      backends = [
        {
          group   = "my_test_group"
          options = null
        }
      ],
      health_checks = ["hc_1"]
      log_config = null
      options = null
    }
  }

  health_checks_config = {
    hc_1 = {
      type    = "http"
      logging = true
      options = {
        timeout_sec = 40
      }
      check = {
        port_specification = "USE_SERVING_PORT"
      }
    }
  }
}
# tftest modules=1 resources=5
```

### Network Endpoint Groups and Serverless Backends

Network Endpoint Groups (including for serverless backends) can also be used, as shown in the example below.

```hcl
module "ilb" {
  source     = "./modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"

  # This is important as serverless backends require no HCs
  health_checks_config_defaults = null

  backend_services_config = {
    my-serverless-backend-svc = {
      enable_cdn    = false
      cdn_config    = null
      backends = [
        {
          group   = google_compute_region_network_endpoint_group.serverless-neg.id
          options = null
        }
      ],
      health_checks = []
      log_config = null
      options = null
    }
  }
}

resource "google_compute_region_network_endpoint_group" "serverless-neg" {
  name                  = "my-serverless-neg"
  project               = var.project_id
  region                = "europe-west1"
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = "my-cloud-run-service"
  }
}
# tftest modules=1 resources=4
```

### Url-map

The url-map can be customized with lots of different configurations. This includes leveraging multiple backends in different parts of the configuration.
Given its complexity, it's left to the user passing the right data structure.

For simplicity, *if no configurations are given* the first backend service defined (in alphabetical order, with priority to bucket backend services, if any) is used as the *default_service*, thus answering to the root (*/*) path.

Backend services can be specified as needed in the url-map configuration, referencing the id used to declare them in the backend services map. If a corresponding backend service is found, their object id is automatically used; otherwise, it is assumed that the string passed is the id of an already existing backend and it is given to the provider as it was passed.

In this example, we're using a backend service as the default backend

```hcl
module "ilb" {
  source     = "./modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"

  url_map_config = {
    default_service      = "my-backend-svc"
    default_url_redirect = null
    tests                = null
    host_rules           = []
    path_matchers = [
      {
        name = "my-example-page"
        path_rules = [
          {
            paths   = ["/my-example-page"]
            service = "another-group-backend"
          }
        ]
      }
    ]
  }

  backend_services_config = {
    my-backend-svc = {
      enable_cdn    = false
      cdn_config    = null
      backends = [
        {
          group   = "my_test_group"
          options = null
        }
      ],
      health_checks = []
      log_config = null
      options = null
    },
    my-example-page = {
      enable_cdn    = false
      cdn_config    = null
      backends = [
        {
          group   = "my_other_test_group"
          options = null
        }
      ],
      health_checks = []
      log_config = null
      options = null
    }
  }
}
# tftest modules=1 resources=6
```

### Reserve a static IP address

Optionally, a static IP address can be reserved:

```hcl
module "ilb" {
  source     = "./modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"

  static_ip_config = {
    reserve = true
    options = null
  }

  backend_services_config = {
    my-backend-svc = {
      enable_cdn    = false
      cdn_config    = null
      backends = [
        {
          group   = "my_test_group"
          options = null
        }
      ],
      health_checks = []
      log_config = null
      options = null
    }
  }
}
# tftest modules=1 resources=6
```

### HTTPS And SSL Certificates

HTTPS is disabled by default but it can be optionally enabled.

When HTTPS is enabled, if the ids specified in the `target_proxy_https_config` variable are not found in the `ssl_certificates_config` map, they are used as is, assuming the ssl certificates already exist:

```hcl
module "ilb" {
  source     = "./modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"

  https = true

  target_proxy_https_config = {
    ssl_certificates = [
      "an-existing-cert"
    ]
  }

  backend_services_config = {
    my-backend-svc = {
      enable_cdn    = false
      cdn_config    = null
      backends = [
        {
          group   = "my_test_group"
          options = null
        }
      ]
      health_checks = []
      log_config = null
      options = null
    }
  }
}
# tftest modules=1 resources=5
```

Otherwise, unamanged certificates can also be contextually created:

```hcl
module "ilb" {
  source     = "./modules/net-ilb-l7"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"

  https = true

  ssl_certificates_config = {
    my-domain = {
      domains = [
        "my-domain.com"
      ],
      tls_private_key      = nonsensitive(tls_private_key.self_signed_key.private_key_pem)
      tls_self_signed_cert = nonsensitive(tls_self_signed_cert.self_signed_cert.cert_pem)
    }
  }

  target_proxy_https_config = {
    ssl_certificates = [
      "my-domain"
    ]
  }

  backend_services_config = {
    my-backend-svc = {
      enable_cdn    = false
      cdn_config    = null
      backends = [
        {
          group   = "my_test_group"
          options = null
        }
      ],
      health_checks = []
      log_config = null
      options = null
    }
  }
}

resource "tls_private_key" "self_signed_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "self_signed_cert" {
  key_algorithm         = tls_private_key.self_signed_key.algorithm
  private_key_pem       = tls_private_key.self_signed_key.private_key_pem
  validity_period_hours = 12
  early_renewal_hours   = 3
  dns_names             = ["example.com"]
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
  subject {
    common_name  = "example.com"
    organization = "My Test Org"
  }
}
# tftest modules=1 resources=6
```

## Components And Files Mapping

An Internal HTTP Load Balancer is made of multiple components, that change depending on the configurations. Sometimes, it may be tricky to understand what they are, and how they relate to each other. Following, we provide a very brief overview to become more familiar with them.

- The global load balancer [forwarding rule](forwarding-rule.tf) binds a frontend public Virtual IP (VIP) to an HTTP(S) [target proxy](target-proxy.tf).
- If the target proxy is HTTPS, it requires one or more unmanaged [SSL certificates](ssl-certificates.tf).
- Target proxies  leverage [url-maps](url-map.tf): a set of L7 rules that create a mapping between specific hostnames, URIs (and more) to one or more [backends services](backend-services.tf).
- [Backend services](backend-services.tf) link to one or multiple infrastructure groups (GCE instance groups or NEGs). It is assumed in this module that groups have been previously created through other modules, and referenced in the input variables.
- Backend services support one or more [health checks](health-checks.tf), used to verify that the backend is indeed healthy, so that traffic can be forwarded to it. Health checks currently supported in this module are HTTP, HTTPS, HTTP2, SSL, TCP.

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->

## Files

| name | description | resources |
|---|---|---|
| [backend-services.tf](./backend-services.tf) | Bucket and group backend services. | <code>google_compute_region_backend_service</code> |
| [forwarding-rule.tf](./forwarding-rule.tf) | IP Address and forwarding rule. | <code>google_compute_address</code> · <code>google_compute_forwarding_rule</code> |
| [health-checks.tf](./health-checks.tf) | Health checks. | <code>google_compute_region_health_check</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [ssl-certificates.tf](./ssl-certificates.tf) | SSL certificates. | <code>google_compute_ssl_certificate</code> |
| [target-proxy.tf](./target-proxy.tf) | HTTP and HTTPS target proxies. | <code>google_compute_region_target_http_proxy</code> · <code>google_compute_region_target_https_proxy</code> |
| [url-map.tf](./url-map.tf) | URL maps. | <code>google_compute_region_url_map</code> |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L17) | Load balancer name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L22) | Project id. | <code>string</code> | ✓ |  |
| [region](variables.tf#L163) | The region where to allocate the ILB resources. | <code>string</code> | ✓ |  |
| [backend_services_config](variables.tf#L27) | The backends services configuration. | <code title="map&#40;object&#40;&#123;&#10;  enable_cdn &#61; bool&#10;&#10;&#10;  cdn_config &#61; object&#40;&#123;&#10;    cache_mode                   &#61; string&#10;    client_ttl                   &#61; number&#10;    default_ttl                  &#61; number&#10;    max_ttl                      &#61; number&#10;    negative_caching             &#61; bool&#10;    negative_caching_policy      &#61; map&#40;number&#41;&#10;    serve_while_stale            &#61; bool&#10;    signed_url_cache_max_age_sec &#61; string&#10;  &#125;&#41;&#10;&#10;&#10;  backends &#61; list&#40;object&#40;&#123;&#10;    group &#61; string &#35; IG or NEG FQDN address&#10;    options &#61; object&#40;&#123;&#10;      balancing_mode               &#61; string &#35; Can be UTILIZATION, RATE, CONNECTION&#10;      capacity_scaler              &#61; number &#35; Valid range is &#91;0.0,1.0&#93;&#10;      max_connections              &#61; number&#10;      max_connections_per_instance &#61; number&#10;      max_connections_per_endpoint &#61; number&#10;      max_rate                     &#61; number&#10;      max_rate_per_instance        &#61; number&#10;      max_rate_per_endpoint        &#61; number&#10;      max_utilization              &#61; number&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;  health_checks &#61; list&#40;string&#41;&#10;&#10;&#10;  log_config &#61; object&#40;&#123;&#10;    enable      &#61; bool&#10;    sample_rate &#61; number &#35; must be in &#91;0, 1&#93;&#10;  &#125;&#41;&#10;&#10;&#10;  options &#61; object&#40;&#123;&#10;    affinity_cookie_ttl_sec         &#61; number&#10;    custom_request_headers          &#61; list&#40;string&#41;&#10;    custom_response_headers         &#61; list&#40;string&#41;&#10;    connection_draining_timeout_sec &#61; number&#10;    locality_lb_policy              &#61; string&#10;    port_name                       &#61; string&#10;    protocol                        &#61; string&#10;    session_affinity                &#61; string&#10;    timeout_sec                     &#61; number&#10;&#10;&#10;    circuits_breakers &#61; object&#40;&#123;&#10;      max_requests_per_connection &#61; number &#35; Set to 1 to disable keep-alive&#10;      max_connections             &#61; number &#35; Defaults to 1024&#10;      max_pending_requests        &#61; number &#35; Defaults to 1024&#10;      max_requests                &#61; number &#35; Defaults to 1024&#10;      max_retries                 &#61; number &#35; Defaults to 3&#10;    &#125;&#41;&#10;&#10;&#10;    consistent_hash &#61; object&#40;&#123;&#10;      http_header_name  &#61; string&#10;      minimum_ring_size &#61; string&#10;      http_cookie &#61; object&#40;&#123;&#10;        name &#61; string&#10;        path &#61; string&#10;        ttl &#61; object&#40;&#123;&#10;          seconds &#61; number&#10;          nanos   &#61; number&#10;        &#125;&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#10;&#10;&#10;    iap &#61; object&#40;&#123;&#10;      oauth2_client_id            &#61; string&#10;      oauth2_client_secret        &#61; string&#10;      oauth2_client_secret_sha256 &#61; string&#10;    &#125;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [forwarding_rule_config](variables.tf#L111) | Forwarding rule configurations. | <code title="object&#40;&#123;&#10;  allow_global_access &#61; bool&#10;  ip_version          &#61; string&#10;  network_tier        &#61; string&#10;  port_range          &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  allow_global_access &#61; true&#10;  ip_version          &#61; &#34;IPV4&#34;&#10;  network_tier        &#61; &#34;PREMIUM&#34;&#10;  port_range &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |
| [health_checks_config](variables.tf#L128) | Custom health checks configuration. | <code title="map&#40;object&#40;&#123;&#10;  type    &#61; string      &#35; http https tcp ssl http2&#10;  check   &#61; map&#40;any&#41;    &#35; actual health check block attributes&#10;  options &#61; map&#40;number&#41; &#35; interval, thresholds, timeout&#10;  logging &#61; bool&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_checks_config_defaults](variables.tf#L139) | Auto-created health check default configuration. | <code title="object&#40;&#123;&#10;  check   &#61; map&#40;any&#41; &#35; actual health check block attributes&#10;  logging &#61; bool&#10;  options &#61; map&#40;number&#41; &#35; interval, thresholds, timeout&#10;  type    &#61; string      &#35; http https tcp ssl http2&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  type    &#61; &#34;http&#34;&#10;  logging &#61; false&#10;  options &#61; &#123;&#125;&#10;  check &#61; &#123;&#10;    port_specification &#61; &#34;USE_SERVING_PORT&#34;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [https](variables.tf#L157) | Whether to enable HTTPS. | <code>bool</code> |  | <code>false</code> |
| [ssl_certificates_config](variables.tf#L168) | The SSL certificate configuration. | <code title="map&#40;object&#40;&#123;&#10;  domains              &#61; list&#40;string&#41;&#10;  tls_private_key      &#61; string&#10;  tls_self_signed_cert &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [static_ip_config](variables.tf#L178) | Static IP address configuration. | <code title="object&#40;&#123;&#10;  reserve &#61; bool&#10;  options &#61; object&#40;&#123;&#10;    address    &#61; string&#10;    subnetwork &#61; string &#35; The subnet id&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  reserve &#61; false&#10;  options &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |
| [target_proxy_https_config](variables.tf#L193) | The HTTPS target proxy configuration. | <code title="object&#40;&#123;&#10;  ssl_certificates &#61; list&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [url_map_config](variables.tf#L201) | The url-map configuration. | <code title="object&#40;&#123;&#10;  default_service      &#61; string&#10;  default_url_redirect &#61; map&#40;any&#41;&#10;  host_rules           &#61; list&#40;any&#41;&#10;  path_matchers        &#61; list&#40;any&#41;&#10;  tests                &#61; list&#40;map&#40;string&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [backend_services](outputs.tf#L22) | Backend service resources. |  |
| [forwarding_rule](outputs.tf#L52) | The forwarding rule. |  |
| [health_checks](outputs.tf#L17) | Health-check resources. |  |
| [ip_address](outputs.tf#L39) | The reserved IP address. |  |
| [ssl_certificates](outputs.tf#L34) | The SSL certificate. |  |
| [target_proxy](outputs.tf#L44) | The target proxy. |  |
| [url_map](outputs.tf#L29) | The url-map. |  |

<!-- END TFDOC -->
