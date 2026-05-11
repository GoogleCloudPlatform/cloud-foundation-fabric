# Internal Application Load Balancer Module

This module allows managing Internal HTTP/HTTPS Load Balancers (L7 ILBs). It's designed to expose the full configuration of the underlying resources, and to facilitate common usage patterns by providing sensible defaults, and optionally managing prerequisite resources like health checks, instance groups, etc.

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
    - [Private Service Connect NEG creation with Cross-project PSC and back-end](#private-service-connect-neg-creation-with-cross-project-psc-and-back-end)
    - [Internet NEG creation](#internet-neg-creation)
  - [URL Map](#url-map)
  - [SSL Certificates](#ssl-certificates)
  - [Backend Authenticated TLS](#backend-authenticated-tls)
  - [PSC service attachment](#psc-service-attachment)
  - [Context](#context)
  - [Complex example](#complex-example)
- [Deploying changes to load balancer configurations](#deploying-changes-to-load-balancer-configurations)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
- [Fixtures](#fixtures)
<!-- END TOC -->

### Minimal Example

An HTTP ILB with a backend service pointing to a GCE instance group:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = "$project_ids:myprj"
  region     = "$locations:ew1"
  context = {
    locations   = { ew1 = "europe-west1" }
    networks    = { myvpc = "projects/myprj/global/networks/myvpc" }
    project_ids = { myprj = "myprj" }
    subnets     = { mysubnet = "projects/myprj/regions/europe-west1/subnetworks/mysubnet" }
  }
  backend_service_configs = {
    default = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
      }]
    }
  }
  vpc_config = {
    network    = "$networks:myvpc"
    subnetwork = "$subnets:mysubnet"
  }
}
# tftest modules=1 resources=5
```

An HTTPS ILB needs a few additional fields:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
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
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=5
```

### Cross-project backend services

When using Shared VPC, this module also allows configuring [cross-project backend services](https://cloud.google.com/load-balancing/docs/l7-internal/l7-internal-shared-vpc#cross-project):

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = "prj-host"
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      project_id = "prj-svc"
      backends = [{
        group = "projects/prj-svc/zones/europe-west1-a/instanceGroups/my-ig"
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
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=5
```

### Health Checks

You can leverage externally defined health checks for backend services, or have the module create them for you. By default a simple HTTP health check is created, and used in backend services.

Health check configuration is controlled via the `health_check_configs` variable, which behaves in a similar way to other LB modules in this repository.

Defining different health checks from the default is very easy. You can for example replace the default HTTP health check with a TCP one and reference it in you backend service:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
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
  source     = "./fabric/modules/net-lb-app-int"
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
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=4
```

### Instance Groups

The module can optionally create unmanaged instance groups, which can then be referred to in backends via their key:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      port_name = "http"
      backends = [
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
      named_ports = { http = 80 }
    }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=6
```

### Network Endpoint Groups (NEGs)

Network Endpoint Groups (NEGs) can be used as backends, by passing their id as the backend group in a backends service configuration:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        balancing_mode = "RATE"
        group          = "projects/myprj/zones/europe-west1-a/networkEndpointGroups/my-neg"
        max_rate = {
          per_endpoint = 1
        }
      }]
    }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=5
```

Similarly to instance groups, NEGs can also be managed by this module which supports GCE, hybrid, serverless and Private Service Connect NEGs:

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

module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        balancing_mode = "RATE"
        group          = "my-neg"
        max_rate = {
          per_endpoint = 1
        }
      }]
    }
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
# tftest modules=1 resources=8 inventory=zonal-neg.yaml
```

#### Hybrid NEG creation

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        balancing_mode = "RATE"
        group          = "my-neg"
        max_rate = {
          per_endpoint = 1
        }
      }]
    }
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
# tftest modules=1 resources=7
```

#### Serverless NEG creation

This is a simple example where both the Cloud Run service and the load balancer are in the same project.

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        group = "my-neg"
      }]
      health_checks = []
      protocol      = "HTTPS"
    }
  }
  health_check_configs = {}
  neg_configs = {
    my-neg = {
      cloudrun = {
        region = "europe-west1"
        target_service = {
          name = "my-run-service"
        }
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

For cross-project referencing, both the load balancer and the cloud run projects need to be service projects of the same Shared VPC host. Then specify the Cloud Run project for both the backend service and NEG.

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        group = "my-neg"
      }]
      health_checks = []
      protocol      = "HTTPS"
      project_id    = "cr-project-id"
    }
  }
  health_check_configs = {}
  neg_configs = {
    my-neg = {
      project_id = "cr-project-id"
      cloudrun = {
        region = "europe-west1"
        target_service = {
          name = "my-run-service"
        }
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

For cross-project referencing, both the load balancer and the cloud run projects need to be service projects of the same Shared VPC host. Then specify the Cloud Run project for both the backend service and NEG.

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        group = "my-neg"
      }]
      health_checks = []
      protocol      = "HTTPS"
      project_id    = "cr-project-id"
    }
  }
  health_check_configs = {}
  neg_configs = {
    my-neg = {
      project_id = "cr-project-id"
      cloudrun = {
        region = "europe-west1"
        target_service = {
          name = "my-run-service"
        }
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

Cloud Run NEGs can also be created via a URL mask, which allows targeting accessing multiple services or revisions. In this case, a tag can be optionally specified to target a specific revision.

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        group = "my-neg"
      }]
      health_checks = []
      protocol      = "HTTPS"
    }
  }
  health_check_configs = {}
  neg_configs = {
    my-neg = {
      cloudrun = {
        region         = "europe-west1"
        target_urlmask = "example.com/<service>"
        tag            = "my-tag"
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

#### Private Service Connect NEG creation

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = var.project_id
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [{
        group = "my-neg"
      }]
      health_checks = []
    }
  }
  health_check_configs = {}
  neg_configs = {
    my-neg = {
      psc = {
        region         = var.region
        target_service = "${var.region}-cloudkms.googleapis.com"
      }
    }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=5 e2e
```

#### Private Service Connect NEG creation with Cross-project PSC and back-end

This example shows how to create the load balancer in one project `prj-host` while using a shared VPC deployed in the `prj-svc` project. Please note that the load balancer and its front-end will be created in the `prj-host` project and the back-end will be created in the `prj-svc` project. This is useful for situations where a shared VPC is being used that has been deployed in another project. Two subnetworks are needed, one for the loab balancer and another one for the PSC endpoint.

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = "prj-host"
  region     = "us-central1"

  backend_service_configs = {
    default = {
      project_id = "prj-svc"
      backends = [{
        group = "neg-01"
      }]
      health_check_configs = {}
      neg_configs = {
        neg-01 = {
          project_id  = "prj-svc"
          description = "Network Endpoint Group for service accessed using Private Service Connect"
          psc = {
            region         = "us-central1"
            target_service = "projects/producer_project/regions/us-central1/serviceAttachments/project_id"
            network        = var.vpc.self_link
            subnetwork     = "projects/prj-svc/regions/us-central1/subnetworks/psc_subnet"
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
```

#### Internet NEG creation

This example shows how to create and manage internet NEGs:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  project_id = var.project_id
  name       = "ilb-test"
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [
        { group = "neg-0" }
      ]
      health_checks = []
    }
  }
  # with a single internet NEG the implied default health check is not needed
  health_check_configs = {}
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

### URL Map

The module exposes the full URL map resource configuration, with some minor changes to the interface to decrease verbosity, and support for aliasing backend services via keys.

The default URL map configuration sets the `default` backend service as the default service for the load balancer as a convenience. Just override the `urlmap_config` variable to change the default behaviour:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
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
      log_config = {
        enable      = true
        sample_rate = 0.5
      }
    }
    audio = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig-3"
      }]
      log_config = {
        enable = false
      }
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
        path_rules = [
          {
            paths   = ["/video", "/video/*"]
            service = "video"
          },
          {
            paths   = ["/audio", "/audio/*"]
            service = "audio"
          }
        ]
      }
    }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}

# tftest modules=1 resources=7 inventory=urlmap.yaml
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
  source     = "./fabric/modules/net-lb-app-int"
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
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=8
```

### Backend Authenticated TLS

This example shows how to configure Backend Authenticated TLS using the `tls_settings` block.

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = var.project_id
  region     = "europe-west1"
  backend_service_configs = {
    default = {
      backends = [{
        group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
      }]
      tls_settings = {
        # authentication_config = "projects/myprj/locations/europe-west1/backendTlsPolicies/my-policy"
        sni               = "backend.example.com"
        subject_alt_names = ["backend.example.com"]
      }
    }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
}
# tftest modules=1 resources=5 inventory=tls-settings.yaml
```

### PSC service attachment

The optional `service_attachment` variable allows [publishing Private Service Connect service](https://cloud.google.com/vpc/docs/configure-private-service-connect-producer) by configuring service attachment for the forwarding rule.

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = var.project_id
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [{
        group = module.compute-vm-group-b.group.id
      }]
    }
  }
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
  service_attachment = {
    nat_subnets          = [var.subnet_psc_1.self_link]
    automatic_connection = false
    consumer_accept_lists = {
      # map of `project_id` => `connection_limit`
      (var.project_id) = 10
    }
  }
}
# tftest modules=3 resources=10 fixtures=fixtures/compute-vm-group-bc.tf e2e
```

### Context

The module supports the contexts interpolation. For example:

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-test-0"
  project_id = "$project_ids:test"
  region     = "$locations:ew8"
  vpc_config = {
    network    = "$networks:test"
    subnetwork = "$subnets:test"
  }
  address = "$addresses:test"
  backend_service_configs = {
    default = {
      backends = [
        { group = "projects/foo-test-0/zones/europe-west8-b/instanceGroups/ig-b" },
        { group = "ig-c" }
      ]
    }
    neg-cloudrun = {
      backends      = [{ group = "neg-cloudrun" }]
      health_checks = []
    }
    neg-gce = {
      backends       = [{ group = "neg-gce" }]
      balancing_mode = "RATE"
      max_rate       = { per_endpoint = 10 }
    }
    neg-hybrid = {
      backends       = [{ group = "neg-hybrid" }]
      balancing_mode = "RATE"
      max_rate       = { per_endpoint = 10 }
    }
    neg-internet = {
      backends      = [{ group = "neg-internet" }]
      health_checks = []
    }
    neg-psc = {
      backends      = [{ group = "neg-psc" }]
      health_checks = []
    }
  }
  group_configs = {
    ig-c = {
      zone = "$locations:ew8-c"
      instances = [
        "projects/foo-test-0/zones/europe-west8-c/instances/vm-c"
      ]
      named_ports = { http = 80 }
    }
  }
  health_check_configs = {
    default = {
      http = {
        host               = "hello.example.org"
        port_specification = "USE_SERVING_PORT"
      }
    }
  }
  neg_configs = {
    neg-cloudrun = {
      cloudrun = {
        region = "$locations:ew8"
        target_service = {
          name = "hello"
        }
      }
    }
    neg-gce = {
      gce = {
        network    = "$networks:test"
        subnetwork = "$subnets:test"
        zone       = "$locations:ew8-b"
        endpoints = {
          e-0 = {
            instance   = "nginx-ew8-b"
            ip_address = "$addresses:test"
            port       = 80
          }
        }
      }
    }
    neg-hybrid = {
      hybrid = {
        network = "$networks:test"
        zone    = "$locations:ew8-b"
        endpoints = {
          e-0 = {
            ip_address = "$addresses:test-hybrid"
            port       = 80
          }
        }
      }
    }
    neg-internet = {
      internet = {
        region   = "$locations:ew8"
        use_fqdn = true
        endpoints = {
          e-0 = {
            destination = "hello.example.org"
            port        = 80
          }
        }
      }
    }
    neg-psc = {
      psc = {
        region         = "$locations:ew8"
        target_service = "projects/foo-test-0/regions/europe-west8/serviceAttachments/sa"
        network        = "$networks:test"
        subnetwork     = "$subnets:test"
      }
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
        path_rules = [
          { paths = ["/cloudrun", "/cloudrun/*"], service = "neg-cloudrun" },
          { paths = ["/gce", "/gce/*"], service = "neg-gce" },
          { paths = ["/hybrid", "/hybrid/*"], service = "neg-hybrid" },
          { paths = ["/internet", "/internet/*"], service = "neg-internet" },
          { paths = ["/psc", "/psc/*"], service = "neg-psc" },
        ]
      }
    }
  }
  context = {
    addresses = {
      test        = "10.0.0.10"
      test-hybrid = "192.168.0.3"
    }
    locations = {
      ew8   = "europe-west8"
      ew8-b = "europe-west8-b"
      ew8-c = "europe-west8-c"
    }
    networks = {
      test = "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
    }
    project_ids = {
      test = "foo-test-0"
    }
    subnets = {
      test = "projects/foo-dev-net-spoke-0/regions/europe-west8/subnetworks/gce"
    }
  }
}
# tftest modules=1 resources=19 inventory=context.yaml
```

### Complex example

This example mixes group and NEG backends, and shows how to set HTTPS for specific backends.

```hcl
module "ilb-l7" {
  source     = "./fabric/modules/net-lb-app-int"
  name       = "ilb-l7-test-0"
  project_id = "prj-gce"
  region     = "europe-west8"
  backend_service_configs = {
    default = {
      backends = [
        { group = "nginx-ew8-b" },
        { group = "nginx-ew8-c" },
      ]
    }
    gce-neg = {
      backends = [{
        balancing_mode = "RATE"
        group          = "neg-nginx-ew8-c"
        max_rate = {
          per_endpoint = 1
        }
      }]
    }
    home = {
      backends = [{
        balancing_mode = "RATE"
        group          = "neg-home-hello"
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
    nginx-ew8-b = {
      zone = "europe-west8-b"
      instances = [
        "projects/prj-gce/zones/europe-west8-b/instances/nginx-ew8-b"
      ]
      named_ports = { http = 80 }
    }
    nginx-ew8-c = {
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
        host = "hello.home.example.com"
        port = 443
      }
    }
  }
  neg_configs = {
    neg-nginx-ew8-c = {
      gce = {
        zone = "europe-west8-c"
        endpoints = {
          e-0 = {
            instance   = "nginx-ew8-c"
            ip_address = "10.24.32.26"
            port       = 80
          }
        }
      }
    }
    neg-home-hello = {
      hybrid = {
        zone = "europe-west8-b"
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
    network    = "projects/prj-host/global/networks/shared-vpc"
    subnetwork = "projects/prj-host/regions/europe-west8/subnetworks/gce"
  }
}
# tftest modules=1 resources=14
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
| [health-check.tf](./health-check.tf) | Health check resources. | <code>google_compute_health_check</code> · <code>google_compute_region_health_check</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_compute_forwarding_rule</code> · <code>google_compute_network_endpoint</code> · <code>google_compute_network_endpoint_group</code> · <code>google_compute_region_network_endpoint</code> · <code>google_compute_region_network_endpoint_group</code> · <code>google_compute_region_ssl_certificate</code> · <code>google_compute_region_target_http_proxy</code> · <code>google_compute_region_target_https_proxy</code> · <code>google_compute_service_attachment</code> |
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
| [name](variables.tf#L91) | Load balancer name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L193) | Project id. | <code>string</code> | ✓ |  |
| [region](variables.tf#L211) | The region where to allocate the ILB resources. | <code>string</code> | ✓ |  |
| [vpc_config](variables.tf#L254) | VPC-level configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [address](variables.tf#L17) | Optional IP address used for the forwarding rule. | <code>string</code> |  | <code>null</code> |
| [backend_service_configs](variables-backend-service.tf#L19) | Backend service level configuration. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L23) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L36) | Optional description used for resources. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [global_access](variables.tf#L43) | Allow client access from all regions. | <code>bool</code> |  | <code>null</code> |
| [group_configs](variables.tf#L49) | Optional unmanaged groups to create. Can be referenced in backends via key or outputs. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_check_configs](variables-health-check.tf#L19) | Optional auto-created health check configurations, use the output self-link to set it in the auto healing policy. Refer to examples for usage. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [http_proxy_config](variables.tf#L63) | HTTP proxy configuration. Only used for non-classic load balancers. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [https_proxy_config](variables.tf#L73) | HTTPS proxy configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L85) | Labels set on resources. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [neg_configs](variables.tf#L96) | Optional network endpoint groups to create. Can be referenced in backends via key or outputs. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [network_tier_premium](variables.tf#L176) | Use premium network tier. Defaults to true. | <code>bool</code> |  | <code>true</code> |
| [ports](variables.tf#L183) | Optional ports for HTTP load balancer. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [protocol](variables.tf#L198) | Protocol supported by this load balancer. | <code>string</code> |  | <code>&#34;HTTP&#34;</code> |
| [service_attachment](variables.tf#L216) | PSC service attachment. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [service_directory_registration](variables.tf#L231) | Service directory namespace and service used to register this load balancer. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [ssl_certificates](variables.tf#L240) | SSL target proxy certificates (only if protocol is HTTPS). | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
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
| [id](outputs.tf#L60) | Fully qualified forwarding rule id. |  |
| [neg_ids](outputs.tf#L66) | Autogenerated network endpoint group ids. |  |
| [psc_neg_ids](outputs.tf#L73) | Autogenerated PSC network endpoint group ids. |  |
| [regional_neg_ids](outputs.tf#L80) | Autogenerated regional network endpoint group ids. |  |
| [service_attachment_id](outputs.tf#L87) | Id of the service attachment. |  |
| [url_map_id](outputs.tf#L94) | Fully qualified URL map ID (resource path) for use in IAM conditions and API calls. |  |

## Fixtures

- [compute-vm-group-bc.tf](../../tests/fixtures/compute-vm-group-bc.tf)
<!-- END TFDOC -->
