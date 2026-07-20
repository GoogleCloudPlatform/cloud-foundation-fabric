# Internal Proxy Network Load Balancer Module

This module allows managing Internal TCP proxy Load Balancers. It's designed to expose the full configuration of the underlying resources, and to facilitate common usage patterns by providing sensible defaults, and optionally managing prerequisite resources like health checks, instance groups, etc.

Due to the complexity of the underlying resources, changes to the configuration that involve recreation of resources are best applied in stages, starting by disabling the configuration in the urlmap that references the resources that need recreation, then doing the same for the backend service, etc.

## Examples

<!-- BEGIN TOC -->

- [Examples](#examples)
  - [Minimal Example](#minimal-example)
  - [Health Checks](#health-checks)
  - [Specify an existing IP address](#specify-an-existing-ip-address)
  - [Specify multiple ports](#specify-multiple-ports)
  - [Instance Groups](#instance-groups)
  - [Network Endpoint Groups (NEGs)](#network-endpoint-groups-negs)
    - [Zonal NEG creation](#zonal-neg-creation)
    - [Hybrid NEG creation](#hybrid-neg-creation)
    - [Private Service Connect NEG creation](#private-service-connect-neg-creation)
    - [Internet NEG creation](#internet-neg-creation)
  - [Context](#context)
- [Deploying changes to load balancer configurations](#deploying-changes-to-load-balancer-configurations)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)

<!-- END TOC -->

### Minimal Example

An Regional internal proxy Network Load Balancer with a backend service pointing to an existing GCE instance group:

```hcl
module "int-tcp-proxy" {
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
# tftest inventory=minimal.yaml
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
# tftest inventory=health-check-config.yaml
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
# tftest inventory=health-check-link.yaml
```

### Specify an existing IP address

You can pass your forwarding rules existing IP addresses to use.

```hcl
module "address" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    ilb = {
      purpose    = "INTERNAL"
      region     = "europe-west1"
      subnetwork = var.subnet.self_link
    }
  }
}

module "int-tcp-proxy" {
  source     = "./fabric/modules/net-lb-proxy-int"
  name       = "int-tcp-proxy"
  project_id = var.project_id
  region     = "europe-west1"
  forwarding_rules_config = {
    "" = {
      ip_address = module.address.internal_addresses["ilb"].address
    }
  }
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
# tftest inventory=address.yaml
```

### Specify multiple ports

To make your load balancer listen on multiple ports you will need to create multiple forwarding rules listening on the same IP of type `SHARED_LOADBALANCER_VIP` (created outside the module).

```hcl
module "address" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    ilb = {
      purpose    = "SHARED_LOADBALANCER_VIP"
      region     = "europe-west1"
      subnetwork = var.subnet.self_link
    }
  }
}

module "int-tcp-proxy" {
  source     = "./fabric/modules/net-lb-proxy-int"
  name       = "int-tcp-proxy"
  project_id = var.project_id
  region     = "europe-west1"
  forwarding_rules_config = {
    http = {
      ip_address = module.address.internal_addresses["ilb"].address
      port       = 80
    }
    https = {
      ip_address = module.address.internal_addresses["ilb"].address
      port       = 443
    }
  }
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
# tftest inventory=ports.yaml
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
# tftest inventory=group-config.yaml
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
# tftest inventory=neg-link.yaml
```

Similarly to instance groups, NEGs can also be managed by this module which supports GCE, hybrid and Private Service Connect NEGs:

#### Zonal NEG creation

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
      gce = {
        zone = "europe-west1-b"
        endpoints = {
          e-0 = {
            instance   = "test-1"
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
# tftest inventory=zonal-neg.yaml
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
# tftest inventory=hybrid-neg.yaml
```

#### Private Service Connect NEG creation

```hcl
module "address-ilb" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    ilb-01 = {
      purpose    = "SHARED_LOADBALANCER_VIP"
      region     = var.region
      subnetwork = module.vpc.subnets["${var.region}/sub-consumer-0"].id
    }
  }
}

module "int-tcp-proxy" {
  source     = "./fabric/modules/net-lb-proxy-int"
  name       = "int-tcp-proxy"
  project_id = var.project_id
  region     = var.region
  forwarding_rules_config = {
    http = {
      ip_address = module.address-ilb.internal_addresses["ilb-01"].address
      port       = 80
    }
    https = {
      ip_address = module.address-ilb.internal_addresses["ilb-01"].address
      port       = 443
    }
  }
  backend_service_config = {
    backends = [{
      group = "my-neg"
    }]
  }
  neg_configs = {
    my-neg = {
      psc = {
        network        = module.vpc.id
        subnetwork     = module.vpc.subnets["${var.region}/sub-consumer-0"].id
        region         = var.region
        producer_port  = 80
        target_service = module.ilb-producer.service_attachment_ids["default"]
      }
    }
  }
  vpc_config = {
    network    = module.vpc.id
    subnetwork = module.vpc.subnets["${var.region}/sub-consumer-0"].id
  }
}

module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "net-consumer-0"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "sub-consumer-0"
      region        = var.region
    }
  ]
  subnets_proxy_only = [
    {
      name          = "sub-proxy-consumer-0"
      region        = var.region
      ip_cidr_range = "10.0.1.0/26"
      active        = true
    }
  ]
}

# PRODUCER - What the PSC NEG points to

module "ilb-producer" {
  source        = "./fabric/modules/net-lb-int"
  project_id    = var.project_id
  region        = "europe-west1"
  name          = "ilb-producer"
  service_label = "ilb-producer"
  vpc_config = {
    network    = module.vpc-producer.id
    subnetwork = module.vpc-producer.subnets["${var.region}/sub-producer-0"].id
  }
  forwarding_rules_config = {
    default = {}
  }
  service_attachments = {
    default = {
      nat_subnets          = [module.vpc-producer.subnets_psc["${var.region}/sub-psc-producer-0"].id]
      automatic_connection = true
    }
  }
}

module "vpc-producer" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "net-producer-0"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "sub-producer-0"
      region        = var.region
    }
  ]
  subnets_proxy_only = [
    {
      name          = "sub-proxy-producer-0"
      region        = var.region
      ip_cidr_range = "10.0.1.0/26"
      active        = true
    }
  ]
  subnets_psc = [
    {
      name          = "sub-psc-producer-0"
      region        = var.region
      ip_cidr_range = "10.0.2.0/26"
    }
  ]
}
# tftest inventory=psc-neg.yaml
```

#### Internet NEG creation

This example shows how to create and manage internet NEGs:

```hcl
module "ilb-tcp-proxy" {
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
# tftest inventory=internet-neg.yaml e2e
```

### Context

The module supports the contexts interpolation. For example:

```hcl
module "tcp-proxy" {
  source     = "./fabric/modules/net-lb-proxy-int"
  name       = "ilb-test"
  project_id = "$project_ids:test"
  region     = "$locations:ew8"
  forwarding_rules_config = {
    "" = {
      ip_address = "$addresses:test"
    }
  }
  backend_service_config = {
    backends = [{
      group = "projects/myprj/zones/europe-west1-a/instanceGroups/my-ig"
    }]
  }
  group_configs = {
    default = {
      zone = "$locations:ew8-b"
      instances = [
        "projects/myprj/zones/europe-west1-b/instances/vm-a"
      ]
      named_ports = { http = 80 }
    }
  }
  vpc_config = {
    network    = "$networks:test"
    subnetwork = "$subnets:test"
  }
  context = {
    addresses = {
      test = "10.0.0.10"
    }
    locations = {
      ew8   = "europe-west8"
      ew8-b = "europe-west8-b"
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
# tftest inventory=context.yaml
```

## Deploying changes to load balancer configurations

For deploying changes to load balancer configuration please refer to [net-lb-app-ext README.md](../net-lb-app-ext/README.md#deploying-changes-to-load-balancer-configurations)

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | resources |
|---|---|---|
| [backend-service.tf](./backend-service.tf) | Backend service resources. | <code>google_compute_region_backend_service</code> · <code>terraform_data</code> |
| [groups.tf](./groups.tf) | None | <code>google_compute_instance_group</code> |
| [health-check.tf](./health-check.tf) | Health check resource. | <code>google_compute_region_health_check</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_compute_forwarding_rule</code> · <code>google_compute_network_endpoint</code> · <code>google_compute_network_endpoint_group</code> · <code>google_compute_region_network_endpoint</code> · <code>google_compute_region_network_endpoint_group</code> · <code>google_compute_region_target_tcp_proxy</code> · <code>google_compute_service_attachment</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L213) | Load balancer name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L277) | Project id. | <code>string</code> | ✓ |  |
| [region](variables.tf#L282) | The region where to allocate the ILB resources. | <code>string</code> | ✓ |  |
| [vpc_config](variables.tf#L303) | VPC-level configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [backend_service_config](variables.tf#L17) | Backend service level configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L65) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L78) | Optional description used for resources. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [forwarding_rules_config](variables.tf#L84) | The optional forwarding rules configuration. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [group_configs](variables.tf#L100) | Optional unmanaged groups to create. Can be referenced in backends via key or outputs. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_check](variables.tf#L114) | Name of existing health check to use, disables auto-created health check. | <code>string</code> |  | <code>null</code> |
| [health_check_config](variables.tf#L120) | Optional auto-created health check configurations, use the output self-link to set it in the auto healing policy. Refer to examples for usage. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [labels](variables.tf#L207) | Labels set on resources. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [neg_configs](variables.tf#L218) | Optional network endpoint groups to create. Can be referenced in backends via key or outputs. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_attachment](variables.tf#L287) | PSC service attachment. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [address](outputs.tf#L17) | Forwarding rules addresses. |  |
| [backend_service](outputs.tf#L25) | Backend resource. |  |
| [backend_service_id](outputs.tf#L30) | Backend id. |  |
| [backend_service_self_link](outputs.tf#L35) | Backend self link. |  |
| [forwarding_rules](outputs.tf#L40) | Forwarding rule resources. |  |
| [group_self_links](outputs.tf#L45) | Optional unmanaged instance group self links. |  |
| [groups](outputs.tf#L52) | Optional unmanaged instance group resources. |  |
| [health_check](outputs.tf#L57) | Auto-created health-check resource. |  |
| [health_check_id](outputs.tf#L62) | Auto-created health-check id. |  |
| [health_check_self_link](outputs.tf#L67) | Auto-created health-check self link. |  |
| [ids](outputs.tf#L72) | Fully qualified forwarding rule ids. |  |
| [neg_ids](outputs.tf#L79) | Autogenerated network endpoint group ids. |  |
| [service_attachment_id](outputs.tf#L86) | Id of the service attachment. |  |
<!-- END TFDOC -->
