# External Global (HTTP/S) Load Balancer Module

The module allows managing External Global HTTP/HTTPS Load Balancers (XGLB), integrating the global forwarding rule, the url-map, the backends (supporting buckets and groups), and optional health checks and SSL certificates (both managed and unmanaged). It's designed to be a simple match for the [`gcs`](../gcs) and the [`compute-vm`](../compute-vm) modules, which can be used to manage GCS buckets, instance templates and instance groups.

## Examples

### GCS Bucket Minimal Example

This is a minimal example, which creates a global HTTP load balancer, pointing the path `/` to an existing GCS bucket called `my_test_bucket`.

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  backend_services_config = {
    my-bucket-backend = {
      bucket_config = {
        bucket_name = "my_test_bucket"
        options     = null
      }
      group_config = null
      enable_cdn   = false
      cdn_config   = null
    }
  }
}
# tftest:modules=1:resources=4
```

### Group Backend Service Minimal Example

A very similar coniguration also applies to GCE instance groups:

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  backend_services_config = {
    my-group-backend = {
      bucket_config = null
      enable_cdn    = false
      cdn_config    = null
      group_config = {
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
}
# tftest:modules=1:resources=5
```

### Health Checks For Group Backend Services

Group backend services support health checks.
If no health checks are specified, a default HTTP health check is created and associated to each group backend service. The default health check configuration can be modified through the `health_checks_config_defaults` variable.

Alternatively, one or more health checks can be either contextually created or attached, if existing. If the id of the health checks specified is equal to one of the keys of the `health_checks_config` variable, the health check is contextually created; otherwise, the health check id is used as is, assuming an health check alredy exists.

For example, to contextually create a health check and attach it to the backend service:

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  backend_services_config = {
    my-group-backend = {
      bucket_config = null
      enable_cdn    = false
      cdn_config    = null
      group_config = {
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
# tftest:modules=1:resources=5
```

### Mixing Backends

Backends can be multiple, group and bucket backends can be mixed and group backends support multiple groups.

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  backend_services_config = {
    my-group-backend = {
      bucket_config = null
      enable_cdn    = false
      cdn_config    = null
      group_config = {
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
    },
    another-group-backend = {
      bucket_config = null
      enable_cdn    = false
      cdn_config    = null
      group_config = {
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
    },
    a-bucket-backend = {
      bucket_config = {
        bucket_name = "my_test_bucket"
        options     = null
      }
      group_config = null
      enable_cdn   = false
      cdn_config   = null
    }
  }
}
# tftest:modules=1:resources=7
```

### Url-map

The url-map can be customized with lots of different configurations. This includes leveraging multiple backends in different parts of the configuration.
Given its complexity, it's left to the user passing the right data structure.

For simplicity, *if no configurations are given* the first backend service defined (in alphabetical order, with priority to bucket backend services, if any) is used as the *default_service*, thus answering to the root (*/*) path.

Backend services can be specified as needed in the url-map configuration, referencing the id used to declare them in the backend services map. If a corresponding backend service is found, their object id is automatically used; otherwise, it is assumed that the string passed is the id of an already existing backend and it is given to the provider as it was passed.

In this example, we're using one backend service as the default backend

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  url_map_config = {
    default_service      = "my-group-backend"
    default_route_action = null
    default_url_redirect = null
    tests                = null
    header_action        = null
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
    my-group-backend = {
      bucket_config = null
      enable_cdn    = false
      cdn_config    = null
      group_config = {
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
    },
    my-example-page = {
      bucket_config = null
      enable_cdn    = false
      cdn_config    = null
      group_config = {
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
}
# tftest:modules=1:resources=6
```

### Reserve a static IP address

Optionally, a static IP address can be reserved:

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  reserve_ip_address = true

  backend_services_config = {
    my-group-backend = {
      bucket_config = null
      enable_cdn    = false
      cdn_config    = null
      group_config = {
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
}
# tftest:modules=1:resources=6
```

### HTTPS And SSL Certificates

HTTPS is disabled by default but it can be optionally enabled.
The module supports both managed and unmanaged certificates, and they can be either created contextually with other resources or attached, if already existing.

If no `ssl_certificates_config` variable is specified, a managed certificate for the domain *example.com* is automatically created.

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  https = true

  backend_services_config = {
    my-group-backend = {
      bucket_config = null
      enable_cdn    = false
      cdn_config    = null
      group_config = {
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
}
# tftest:modules=1:resources=6
```

Otherwise, SSL certificates can be explicitely defined. In this case, they'll need to be referenced from the `target_proxy_https_config.ssl_certificates` variable.

If the ids specified in the `target_proxy_https_config` variable are not found in the `ssl_certificates_config` map, they are used as is, assuming the ssl certificates already exist.

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  https = true

  ssl_certificates_config = {
    my-domain = {
      domains = [
        "my-domain.com"
      ],
      unmanaged_config = null
    }
  }

  target_proxy_https_config = {
    ssl_certificates = [
      "my-domain",
      "an-existing-cert"
    ]
  }

  backend_services_config = {
    my-group-backend = {
      bucket_config = null
      enable_cdn    = false
      cdn_config    = null
      group_config = {
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
}
# tftest:modules=1:resources=6
```

Using unamanged certificates is also possible. Here is an example:

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  https = true

  ssl_certificates_config = {
    my-domain = {
      domains = [
        "my-domain.com"
      ],
      unmanaged_config = {
        tls_private_key      = nonsensitive(tls_private_key.self_signed_key.private_key_pem)
        tls_self_signed_cert = nonsensitive(tls_self_signed_cert.self_signed_cert.cert_pem)
      }
    }
  }

  target_proxy_https_config = {
    ssl_certificates = [
      "my-domain"
    ]
  }

  backend_services_config = {
    my-group-backend = {
      bucket_config = null
      enable_cdn    = false
      cdn_config    = null
      group_config = {
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
# tftest:modules=1:resources=6
```

## Components And Files Mapping

An External Global Load Balancer is made of multiple components, that change depending on the configurations. Sometimes, it may be tricky to understand what they are, and how they relate to each other. Following, we provide a very brief overview to become more familiar with them.

* The global load balancer ([global_forwarding_rule.tf](global_forwarding_rule.tf)) binds a frontend public Virtual IP (VIP) (ip_address.tf)[ip_address.tf] to an HTTP(S) target proxy ((target_proxy.tf)[target_proxy.tf]).

* If the target proxy ((target_proxy.tf)[target_proxy.tf]) is HTTPS, it requires one or more -managed or unmanaged- SSL certificates ((ssl_certificates.tf)[ssl_certificates.tf]).

* Target proxies ((target_proxy.tf)[target_proxy.tf]) leverage url-maps ((url_map.tf)[url_map.tf]): set of L7 rules, which create a mapping between specific hostnames, URIs (and more) to one or more backends services ((backend_services.tf)[backend_services.tf]).

* Backends services ((backend_services.tf)[backend_services.tf]) can either link to a bucket or -one or multiple- groups, which can be GCE instance groups or NEGs. It is assumed in this module that buckets and groups are previously created through other modules, and passed in as input variables.

* Backends services ((backend_services.tf)[backend_services.tf]) support one or more health checks ((health_cheks.tf)[health_checks.tf]), used to verify that the backend is indeed healthy, so that traffic can be forwarded to it. Health checks currently supported in this module are HTTP, HTTPS, HTTP2, SSL, TCP.
