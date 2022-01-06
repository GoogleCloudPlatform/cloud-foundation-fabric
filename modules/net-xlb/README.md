# Global External Load Balancer Module

The module allows managing External Global HTTP/HTTPS Load Balancers (XLB), integrating the global forwarding rule, the url-map, the backends (supporting buckets and groups), and optional health checks and SSL certificates (both managed and unmanaged). It's designed to be a simple match for the [`gcs`](../gcs) and the [`compute-vm`](../compute-vm) modules, which can be used to manage GCS buckets, instance templates and instance groups.

## Examples

### GCS Bucket Minimal Example

This is a minimal example, which creates a global HTTP load balancer, pointing the path `/` to an existing GCS bucket called `xlb-test-backend`. A health check for HTTP `/` is automatically created.

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  backends_configs = {
    my_bucket_backend = {
      type        = "bucket"
      bucket_name = "xlb-test-gcs-backend"
    }
  }
}
```

### Group Minimal Example

A very similar coniguration also applies to GCE instance groups:

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  backends_configs = {
    my_group_backend = {
      type = "group"
      backends = [
       {
        group = "xlb-test-group-backend"
       } 
      ]
    }
  }
}
```

### Mixing Backends

Backends can be multiple, group and bucket backends can be mixed and group backends support multiple groups.

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  backends_configs = {
    my_group_backend = {
      type = "group"
      backends = [
       {
        group = "xlb-test-group-backend"
       } 
      ]
    },
    my_other_group_backend = {
      type = "group"
      backends = [
       {
        group = "xlb-another-group-backend"
       } 
      ]
    },
    my_bucket_backend = {
      type        = "bucket"
      bucket_name = "xlb-test-gcs-backend"
    }
  }
}
```

### Url-map

The url-map can be customized with lots of different configurations. This includes leveraging multiple backends in different parts of the configuration.
Given its complexity, it's left to the user passing the right data structure.

For simplicity, *if no configurations are passed* the first backend service defined (in alphabetical order) is used as the *default_service*, thus answering to the root (*/*) path.

Backend services can be specified as needed in the url-map configuration, referencing the id used to declare them in the backend services map. If a corresponding backend service is found their object id is automatically used; otherwise, it is assumed that the string passed is the id of an already existing backend and it is given to the provider as it was passed.

To specify a backend (for example, as the default service):

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  url_map_configs = {
    default_service = "my_group_backend"
  }

  backends_configs = {
    my_group_backend = {
      type = "group"
      backends = [
       {
        group = "xlb-test-group-backend"
       } 
      ]
    }
  }
}
```

### Reserve a static IP address

Optionally, a static IP address can be reserved:

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  reserve_ip_address = true

  backends_configs = {
    my_group_backend = {
      type = "group"
      backends = [
       {
        group = "xlb-test-group-backend"
       } 
      ]
    }
  }
}
```

### HTTPS And SSL Certificates

HTTPS is disabled by default but it can be optionally enabled.
The module supports both managed and unmanaged certificates, and they can be either created with other resources or attached, if already existing.

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  https = true

  ssl_certificate_configs = {
    source_type = "create"
    type        = "managed"
    domains = [
      "my_test_domain.com"
    ]
  }

  backends_configs = {
    my_group_backend = {
      type = "group"
      backends = [
       {
        group = "xlb-test-group-backend"
       } 
      ]
    }
  }
}
```

To attach an existing certificate:

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  https = true

  ssl_certificate_configs = {
    source_type = "attach"
    ids = [
      "my-cert-id-1",
      "my-cert-id-2"
    ]
  }

  ...
}
```

### Health Checks

Group backend services can optionally have one or multiple health checks.

Health checks can be either contextually created:

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  backends_configs = {
    my_group_backend = {
      type = "group"
      backends = [
        {
          group = "xlb-test-group-backend"
        }
      ]
      health_check = {
        source_type = "create"
        id          = "hc_1"
      }
    }
  }

  health_checks_configs = {
    hc_1 = {
      check = {
        host = "test"
      }
      type    = "http"
      logging = true
    },
    my_hc_2 = {
      check = {
        port_specification = "USE_SERVING_PORT"
      }
      type    = "http"
    }
  }

  ...
}
```

Or existing health checks can be attached.

```hcl
module "xlb" {
  source     = "./modules/net-xlb"
  name       = "xlb-test"
  project_id = var.project_id

  backends_configs = {
    my_group_backend = {
      type = "group"
      backends = [
        {
          group = "xlb-test-group-backend"
        }
      ]
      health_check = {
        source_type = "attach"
        id          = "my_existing_hc_id"
      }
    }
  }

  ...
}
```

## Components And Files Mapping

An External Global Load Balancer is made of multiple components, that change depending on the configurations. Sometimes, it may be tricky to understand what they are, and how they relate to each other. Following, we provide a very brief overview to become more familiar with them.

* The global load balancer ([global_forwarding_rule.tf](global_forwarding_rule.tf)) binds a frontend public Virtual IP (VIP) (ip_address.tf)[ip_address.tf] to an HTTP(S) target proxy ((target_proxy.tf)[target_proxy.tf]).

* If the target proxy ((target_proxy.tf)[target_proxy.tf]) is HTTPS, it requires one or more -managed or unmanaged- SSL certificates ((ssl_certificates.tf)[ssl_certificates.tf]).

* Target proxies ((target_proxy.tf)[target_proxy.tf]) leverage url-maps ((url_map.tf)[url_map.tf]): set of L7 rules, which create a mapping between specific hostnames, URIs (and more) to one or more backends services ((backend_services.tf)[backend_services.tf]).

* Backends services ((backend_services.tf)[backend_services.tf]) can either link to a bucket or -one or multiple- groups, which can be GCE instance groups or NEGs. It is assumed in this module that buckets and groups are previously created through other modules, and passed in as input variables.

* Backends services ((backend_services.tf)[backend_services.tf]) support one or more health checks ((health_cheks.tf)[health_checks.tf]), used to verify that the backend is indeed healthy, so that traffic can be forwarded to it. Health checks currently supported in this module are HTTP, HTTPS, HTTP2, SSL, TCP.

## Conventions

There are few considerations to keep in mind, in order to use more effectively the module.

### Variables, locals and defaults

Deliberately, most of the input variables are typed as *any*.
While this makes a little bit more difficult for users to undestand what variables should be passed in ingress, it allows them to don't specify each argument, when only one or few values need to be overridden.

Default values can be found in the *local* blocks of each component.

### Argument Blocks

When multiple argument blocks are used in the provider, these are specified as a list (usually named using the plural of the word used for the block argument).

For example, if the provider declares multiple `backend` blocks, like this:

```hcl
...

backend {
  ...
}

backend {
  ...
}

...
```

These can be declared as a list of maps, as an input variable of the module, under the corresponding configuration section. For example:

```hcl
...

backends = [
  {
    ...
  },
  {
    ...
  },
  ...
]

...
```

### SSL Certificates Limitations

While multiple certificates could be associated to an HTTPS target proxy, the module currently supports the creation of one certificate only.

This might anyway support multiple domains, specified through the list variable `ssl_certificate_configs.domains`.

By default, the common name used to generate unamanaged certificates is the first domain name specified in `ssl_certificate_configs.domains`.
