# VPC module

This module allows creation and management of VPC networks including subnetworks and subnetwork IAM bindings, and most features and options related to VPCs and subnets.

## Examples

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Simple VPC](#simple-vpc)
  - [Subnet Options](#subnet-options)
  - [Subnet IAM](#subnet-iam)
  - [Peering](#peering)
  - [Shared VPC](#shared-vpc)
  - [Private Service Networking](#private-service-networking)
  - [Private Service Networking with peering routes and peered Cloud DNS domains](#private-service-networking-with-peering-routes-and-peered-cloud-dns-domains)
  - [Private Service Networking with multiple service providers](#private-service-networking-with-multiple-service-providers)
  - [Subnets for Private Service Connect, Proxy-only subnets](#subnets-for-private-service-connect-proxy-only-subnets)
  - [PSC Network Attachments](#psc-network-attachments)
  - [DNS Policies](#dns-policies)
  - [Subnet Factory](#subnet-factory)
  - [Custom Routes](#custom-routes)
  - [Policy Based Routes](#policy-based-routes)
  - [Private Google Access routes](#private-google-access-routes)
  - [Allow Firewall Policy to be evaluated before Firewall Rules](#allow-firewall-policy-to-be-evaluated-before-firewall-rules)
  - [IPv6](#ipv6)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

### Simple VPC

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-network"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "production"
      region        = "europe-west1"
      secondary_ip_ranges = {
        pods     = "172.16.0.0/20"
        services = "192.168.0.0/24"
      }
    },
    {
      ip_cidr_range = "10.0.16.0/24"
      name          = "production"
      region        = "europe-west2"
    }
  ]
}
# tftest modules=1 resources=5 inventory=simple.yaml e2e
```

### Subnet Options

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-network"
  subnets = [
    # simple subnet
    {
      name          = "simple"
      region        = "europe-west1"
      ip_cidr_range = "10.0.0.0/24"
    },
    # custom description and PGA disabled
    {
      name                  = "no-pga"
      region                = "europe-west1"
      ip_cidr_range         = "10.0.1.0/24",
      description           = "Subnet b"
      enable_private_access = false
    },
    # secondary ranges
    {
      name          = "with-secondary-ranges"
      region        = "europe-west1"
      ip_cidr_range = "10.0.2.0/24"
      secondary_ip_ranges = {
        a = "192.168.0.0/24"
        b = "192.168.1.0/24"
      }
    },
    # enable flow logs
    {
      name          = "with-flow-logs"
      region        = "europe-west1"
      ip_cidr_range = "10.0.3.0/24"
      flow_logs_config = {
        flow_sampling        = 0.5
        aggregation_interval = "INTERVAL_10_MIN"
      }
    }
  ]
}
# tftest modules=1 resources=7 inventory=subnet-options.yaml e2e
```

### Subnet IAM

Subnet IAM variables follow our general interface, with extra keys/members for the subnet to which each binding will be applied.

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-network"
  subnets = [
    {
      name          = "subnet-1"
      region        = "europe-west1"
      ip_cidr_range = "10.0.1.0/24"
      iam = {
        "roles/compute.networkUser" = [
          "group:${var.group_email}"
        ]
      }
      iam_bindings = {
        subnet-1-iam = {
          members = ["group:${var.group_email}"]
          role    = "roles/compute.networkUser"
          condition = {
            expression = "resource.matchTag('123456789012/env', 'prod')"
            title      = "test_condition"
          }
        }
      }
    },
    {
      name          = "subnet-2"
      region        = "europe-west1"
      ip_cidr_range = "10.0.2.0/24"
      iam_bindings_additive = {
        subnet-2-iam = {
          member = "group:${var.group_email}"
          role   = "roles/compute.networkUser"
          subnet = "europe-west1/subnet-2"
        }
      }
    }
  ]
}
# tftest modules=1 resources=8 inventory=subnet-iam.yaml e2e
```

### Peering

A single peering can be configured for the VPC, so as to allow management of simple scenarios, and more complex configurations like hub and spoke by defining the peering configuration on the spoke VPCs. Care must be taken so as a single peering is created/changed/destroyed at a time, due to the specific behaviour of the peering API calls.

If you only want to create the "local" side of the peering, use `peering_create_remote_end` to `false`. This is useful if you don't have permissions on the remote project/VPC to create peerings.

```hcl
module "vpc-hub" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "vpc-hub"
  subnets = [{
    ip_cidr_range = "10.0.0.0/24"
    name          = "subnet-1"
    region        = "europe-west1"
  }]
}

module "vpc-spoke-1" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "vpc-spoke1"
  subnets = [{
    ip_cidr_range = "10.0.1.0/24"
    name          = "subnet-2"
    region        = "europe-west1"
  }]
  peering_config = {
    peer_vpc_self_link = module.vpc-hub.self_link
    import_routes      = true
  }
}
# tftest modules=2 resources=10 inventory=peering.yaml
```

### Shared VPC

[Shared VPC](https://cloud.google.com/vpc/docs/shared-vpc) is a project-level functionality which enables a project to share its VPCs with other projects. The `shared_vpc_host` variable is here to help with rapid prototyping, we recommend leveraging the project module for production usage.

```hcl

module "service-project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "prj1"
  prefix          = var.prefix
  parent          = var.folder_id
  services = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com"
  ]
}

module "vpc-host" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-host-network"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "subnet-1"
      region        = "europe-west1"
      secondary_ip_ranges = {
        pods     = "172.16.0.0/20"
        services = "192.168.0.0/24"
      }
      iam = {
        "roles/compute.networkUser" = [
          "serviceAccount:${var.service_account.email}"
        ]
        "roles/compute.securityAdmin" = [
          "serviceAccount:${var.service_account.email}"
        ]
      }
    }
  ]
  shared_vpc_host = true
  shared_vpc_service_projects = [
    module.service-project.project_id
  ]
}
# tftest modules=2 resources=14 inventory=shared-vpc.yaml e2e
```

### Private Service Networking

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-network"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "production"
      region        = "europe-west1"
    }
  ]
  psa_configs = [{
    ranges = { myrange = "10.0.1.0/24" }
  }]
}
# tftest inventory=psa.yaml e2e
```

The module prefixes the PSA service to address range names, to disable this behaviour just set the `range_prefix` attribute in the PSA configuration:

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-network"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "production"
      region        = "europe-west1"
    }
  ]
  psa_configs = [{
    ranges       = { myrange = "10.0.1.0/24" }
    range_prefix = ""
  }]
}
# tftest inventory=psa-prefix.yaml e2e
```

Each PSA service can set a different prefix. Ranges will be allocated to the service they are defined in, as in the following example:

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-network"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "production"
      region        = "europe-west1"
    }
  ]
  psa_configs = [
    {
      ranges          = { myrange = "10.0.1.0/24" }
      range_prefix    = ""
      deletion_policy = "ABANDON"
    },
    {
      ranges           = { netapp = "10.0.2.0/24" }
      service_producer = "netapp.servicenetworking.goog"
      range_prefix     = ""
    }
  ]
}
# tftest inventory=psa-prefix-services.yaml e2e
```

### Private Service Networking with peering routes and peered Cloud DNS domains

Custom routes can be optionally exported/imported through the peering formed with the Google managed PSA VPC.

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-network"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "production"
      region        = "europe-west1"
    }
  ]
  psa_configs = [{
    ranges         = { myrange = "10.0.1.0/24" }
    export_routes  = true
    import_routes  = true
    peered_domains = ["gcp.example.com."]
  }]
}
# tftest modules=1 resources=8 inventory=psa-routes.yaml e2e
```

### Private Service Networking with multiple service providers

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-network"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "production"
      region        = "europe-west1"
    }
  ]
  psa_configs = [
    {
      ranges = { myrange = "10.0.1.0/24" }
      # service_producer = "servicenetworking.googleapis.com" # default value
      deletion_policy = "ABANDON"
    },
    {
      ranges           = { netapp = "10.0.2.0/24" }
      service_producer = "netapp.servicenetworking.goog"
      deletion_policy  = "ABANDON"
    }
  ]
}
# tftest modules=1 resources=10 inventory=psa-multiple-providers.yaml e2e
```

### Subnets for Private Service Connect, Proxy-only subnets

Along with common private subnets module supports creation more service specific subnets for the following purposes:

- [Proxy-only subnets](https://cloud.google.com/load-balancing/docs/proxy-only-subnets) for Regional HTTPS Internal HTTPS Load Balancers
- [Private Service Connect](https://cloud.google.com/vpc/docs/private-service-connect#psc-subnets) subnets

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-network"

  subnets_proxy_only = [
    {
      ip_cidr_range = "10.0.1.0/24"
      name          = "regional-proxy"
      region        = "europe-west1"
      active        = true
    },
    {
      ip_cidr_range = "10.0.4.0/24"
      name          = "global-proxy"
      region        = "australia-southeast2"
      active        = true
      global        = true
    }
  ]
  subnets_psc = [
    {
      ip_cidr_range = "10.0.3.0/24"
      name          = "psc"
      region        = "europe-west1"
    }
  ]
}
# tftest modules=1 resources=6 inventory=proxy-only-subnets.yaml e2e
```

### PSC Network Attachments

[Network attachments](https://cloud.google.com/vpc/docs/about-network-attachments) are only supported for subnets directly managed by the module. To create network attachments in service projects, refer to the [`net-address`](../net-address/) module documentation.

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-network"
  network_attachments = {
    prod-ew1 = {
      subnet = "europe-west1/production"
      producer_accept_lists = [
        "my-project-1"
      ]
    }
    prod-ew2 = {
      subnet               = "europe-west2/production"
      automatic_connection = true
    }
  }
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "production"
      region        = "europe-west1"
    },
    {
      ip_cidr_range = "10.0.16.0/24"
      name          = "production"
      region        = "europe-west2"
    }
  ]
}
# tftest modules=1 resources=7 inventory=network-attachments.yaml
```

### DNS Policies

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-network"
  dns_policy = {
    inbound = true
    outbound = {
      private_ns = ["10.0.0.1"]
      public_ns  = ["8.8.8.8"]
    }
  }
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "production"
      region        = "europe-west1"
    }
  ]
}
# tftest modules=1 resources=5 inventory=dns-policies.yaml e2e
```

### Subnet Factory

The `net-vpc` module includes a subnet factory (see [Resource Factories](../../blueprints/factories/)) for the massive creation of subnets leveraging one configuration file per subnet. The factory also supports proxy-only and PSC subnets via the `purpose` attribute. The `name` attribute is optional and defaults to the file name, allowing to use the same name for subnets in different regions. The `context` attribute of `var.factories_config` can optionally contain the map `regions`, which allows for the templatization of the `region` attribute (e.g. see `config/subnets/subnet-simple.yaml` below)

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-network"
  factories_config = {
    subnets_folder = "config/subnets"
    context = {
      regions = {
        primary   = "europe-west4"
        secondary = "europe-west8"
      }
    }
  }
}
# tftest modules=1 resources=10 files=subnet-simple,subnet-simple-2,subnet-detailed,subnet-proxy,subnet-proxy-global,subnet-psc inventory=factory.yaml
```

```yaml
name: simple
region: primary
ip_cidr_range: 10.0.1.0/24

# tftest-file id=subnet-simple path=config/subnets/subnet-simple.yaml schema=subnet.schema.json
```

```yaml
name: simple
region: europe-west8
ip_cidr_range: 10.0.2.0/24

# tftest-file id=subnet-simple-2 path=config/subnets/subnet-simple-2.yaml schema=subnet.schema.json
```

```yaml
region: europe-west1
description: Sample description
ip_cidr_range: 10.0.0.0/24
# optional attributes
enable_private_access: false  # defaults to true
iam:
  roles/compute.networkUser:
    - group:lorem@example.com
    - serviceAccount:fbz@prj.iam.gserviceaccount.com
    - user:foobar@example.com
secondary_ip_ranges:          # map of secondary ip ranges
  secondary-range-a: 192.168.0.0/24
flow_logs_config:             # enable, set to empty map to use defaults
  aggregation_interval: "INTERVAL_5_SEC"
  flow_sampling: 0.5
  metadata: "INCLUDE_ALL_METADATA"

# tftest-file id=subnet-detailed path=config/subnets/subnet-detailed.yaml schema=subnet.schema.json
```

```yaml
region: europe-west4
ip_cidr_range: 10.1.0.0/24
proxy_only: true

# tftest-file id=subnet-proxy path=config/subnets/subnet-proxy.yaml schema=subnet.schema.json
```

```yaml
region: australia-southeast2
ip_cidr_range: 10.4.0.0/24
proxy_only: true
global: true

# tftest-file id=subnet-proxy-global path=config/subnets/subnet-proxy-global.yaml schema=subnet.schema.json
```

```yaml
region: europe-west4
ip_cidr_range: 10.2.0.0/24
psc: true

# tftest-file id=subnet-psc path=config/subnets/subnet-psc.yaml schema=subnet.schema.json
```

### Custom Routes

VPC routes can be configured through the `routes` variable.

```hcl
locals {
  route_types = {
    gateway    = "global/gateways/default-internet-gateway"
    instance   = "zones/europe-west1-b/test"
    ip         = "192.168.0.128"
    ilb        = "regions/europe-west1/forwardingRules/test"
    vpn_tunnel = "regions/europe-west1/vpnTunnels/foo"
  }
}

module "vpc" {
  source     = "./fabric/modules/net-vpc"
  for_each   = local.route_types
  project_id = var.project_id
  name       = "my-network-with-route-${replace(each.key, "_", "-")}"
  routes = {
    next-hop = {
      description   = "Route to internal range."
      dest_range    = "192.168.128.0/24"
      tags          = null
      next_hop_type = each.key
      next_hop      = each.value
    }
    gateway = {
      dest_range    = "0.0.0.0/0",
      priority      = 100
      tags          = ["tag-a"]
      next_hop_type = "gateway",
      next_hop      = "global/gateways/default-internet-gateway"
    }
  }
  create_googleapis_routes = null
}
# tftest modules=5 resources=15 inventory=routes.yaml
```

### Policy Based Routes

Policy based routes can be configured through the `policy_based_routes` variable.

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-vpc"
  policy_based_routes = {
    skip-pbr-for-nva = {
      use_default_routing = true
      priority            = 100
      target = {
        tags = ["nva"]
      }
    }
    send-all-to-nva = {
      next_hop_ilb_ip = "10.0.0.253"
      priority        = 101
      filter = {
        src_range  = "10.0.0.0/8"
        dest_range = "0.0.0.0/0"
      }
      target = {
        interconnect_attachment = "europe-west8"
      }
    }
  }
  create_googleapis_routes = null
}
# tftest modules=1 resources=3 inventory=pbr.yaml
```

### Private Google Access routes

By default the VPC module creates IPv4 routes for the [Private Google Access ranges](https://cloud.google.com/vpc/docs/configure-private-google-access#config-routing). This behavior can be controlled through the `create_googleapis_routes` variable:

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-vpc"
  create_googleapis_routes = {
    restricted   = false
    restricted-6 = true
    private      = false
    private-6    = true
  }
}
# tftest modules=1 resources=3 inventory=googleapis.yaml e2e
```

### Allow Firewall Policy to be evaluated before Firewall Rules

```hcl
module "vpc" {
  source                            = "./fabric/modules/net-vpc"
  project_id                        = var.project_id
  name                              = "my-network"
  firewall_policy_enforcement_order = "BEFORE_CLASSIC_FIREWALL"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "production"
      region        = "europe-west1"
      secondary_ip_ranges = {
        pods     = "172.16.0.0/20"
        services = "192.168.0.0/24"
      }
    },
    {
      ip_cidr_range = "10.0.16.0/24"
      name          = "production"
      region        = "europe-west2"
    }
  ]
}
# tftest modules=1 resources=5 inventory=firewall_policy_enforcement_order.yaml e2e
```

### IPv6

A non-overlapping private IPv6 address space can be configured for the VPC via the `ipv6_config` variable. If an internal range is not specified, a unique /48 ULA prefix from the `fd20::/20` range is assigned.

```hcl
module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "my-network"
  ipv6_config = {
    # internal_range is optional
    enable_ula_internal = true
    # internal_range      = "fd20:6b2:27e5::/48"
  }
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "test"
      region        = "europe-west1"
      ipv6          = {}
    },
    {
      ip_cidr_range = "10.0.1.0/24"
      name          = "test"
      region        = "europe-west3"
      ipv6 = {
        access_type = "EXTERNAL"
      }
    }
  ]
}
# tftest modules=1 resources=5 inventory=ipv6.yaml e2e
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L98) | The name of the network being created. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L175) | The ID of the project where this VPC will be created. | <code>string</code> | ✓ |  |
| [auto_create_subnetworks](variables.tf#L17) | Set to true to create an auto mode subnet, defaults to custom mode. | <code>bool</code> |  | <code>false</code> |
| [create_googleapis_routes](variables.tf#L23) | Toggle creation of googleapis private/restricted routes. Disabled when vpc creation is turned off, or when set to null. | <code title="object&#40;&#123;&#10;  private      &#61; optional&#40;bool, true&#41;&#10;  private-6    &#61; optional&#40;bool, false&#41;&#10;  restricted   &#61; optional&#40;bool, true&#41;&#10;  restricted-6 &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [delete_default_routes_on_create](variables.tf#L34) | Set to true to delete the default routes at creation time. | <code>bool</code> |  | <code>false</code> |
| [description](variables.tf#L40) | An optional description of this resource (triggers recreation on change). | <code>string</code> |  | <code>&#34;Terraform-managed.&#34;</code> |
| [dns_policy](variables.tf#L46) | DNS policy setup for the VPC. | <code title="object&#40;&#123;&#10;  inbound &#61; optional&#40;bool&#41;&#10;  logging &#61; optional&#40;bool&#41;&#10;  outbound &#61; optional&#40;object&#40;&#123;&#10;    private_ns &#61; list&#40;string&#41;&#10;    public_ns  &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [factories_config](variables.tf#L59) | Paths to data files and folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  context &#61; optional&#40;object&#40;&#123;&#10;    regions &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  subnets_folder &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [firewall_policy_enforcement_order](variables.tf#L70) | Order that Firewall Rules and Firewall Policies are evaluated. Can be either 'BEFORE_CLASSIC_FIREWALL' or 'AFTER_CLASSIC_FIREWALL'. | <code>string</code> |  | <code>&#34;AFTER_CLASSIC_FIREWALL&#34;</code> |
| [ipv6_config](variables.tf#L82) | Optional IPv6 configuration for this network. | <code title="object&#40;&#123;&#10;  enable_ula_internal &#61; optional&#40;bool&#41;&#10;  internal_range      &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [mtu](variables.tf#L92) | Maximum Transmission Unit in bytes. The minimum value for this field is 1460 (the default) and the maximum value is 1500 bytes. | <code>number</code> |  | <code>null</code> |
| [network_attachments](variables.tf#L103) | PSC network attachments, names as keys. | <code title="map&#40;object&#40;&#123;&#10;  subnet                &#61; string&#10;  automatic_connection  &#61; optional&#40;bool, false&#41;&#10;  description           &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;  producer_accept_lists &#61; optional&#40;list&#40;string&#41;&#41;&#10;  producer_reject_lists &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [peering_config](variables.tf#L116) | VPC peering configuration. | <code title="object&#40;&#123;&#10;  peer_vpc_self_link &#61; string&#10;  create_remote_peer &#61; optional&#40;bool, true&#41;&#10;  export_routes      &#61; optional&#40;bool&#41;&#10;  import_routes      &#61; optional&#40;bool&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [policy_based_routes](variables.tf#L127) | Policy based routes, keyed by name. | <code title="map&#40;object&#40;&#123;&#10;  description         &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;  labels              &#61; optional&#40;map&#40;string&#41;&#41;&#10;  priority            &#61; optional&#40;number&#41;&#10;  next_hop_ilb_ip     &#61; optional&#40;string&#41;&#10;  use_default_routing &#61; optional&#40;bool, false&#41;&#10;  filter &#61; optional&#40;object&#40;&#123;&#10;    ip_protocol &#61; optional&#40;string&#41;&#10;    dest_range  &#61; optional&#40;string&#41;&#10;    src_range   &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  target &#61; optional&#40;object&#40;&#123;&#10;    interconnect_attachment &#61; optional&#40;string&#41;&#10;    tags                    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [psa_configs](variables.tf#L180) | The Private Service Access configuration. | <code title="list&#40;object&#40;&#123;&#10;  deletion_policy  &#61; optional&#40;string, null&#41;&#10;  ranges           &#61; map&#40;string&#41;&#10;  export_routes    &#61; optional&#40;bool, false&#41;&#10;  import_routes    &#61; optional&#40;bool, false&#41;&#10;  peered_domains   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  range_prefix     &#61; optional&#40;string&#41;&#10;  service_producer &#61; optional&#40;string, &#34;servicenetworking.googleapis.com&#34;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |
| [routes](variables.tf#L211) | Network routes, keyed by name. | <code title="map&#40;object&#40;&#123;&#10;  description   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;  dest_range    &#61; string&#10;  next_hop_type &#61; string &#35; gateway, instance, ip, vpn_tunnel, ilb&#10;  next_hop      &#61; string&#10;  priority      &#61; optional&#40;number&#41;&#10;  tags          &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [routing_mode](variables.tf#L232) | The network routing mode (default 'GLOBAL'). | <code>string</code> |  | <code>&#34;GLOBAL&#34;</code> |
| [shared_vpc_host](variables.tf#L242) | Enable shared VPC for this project. | <code>bool</code> |  | <code>false</code> |
| [shared_vpc_service_projects](variables.tf#L248) | Shared VPC service projects to register with this host. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [subnets](variables.tf#L254) | Subnet configuration. | <code title="list&#40;object&#40;&#123;&#10;  name                             &#61; string&#10;  ip_cidr_range                    &#61; string&#10;  region                           &#61; string&#10;  description                      &#61; optional&#40;string&#41;&#10;  enable_private_access            &#61; optional&#40;bool, true&#41;&#10;  allow_subnet_cidr_routes_overlap &#61; optional&#40;bool, null&#41;&#10;  flow_logs_config &#61; optional&#40;object&#40;&#123;&#10;    aggregation_interval &#61; optional&#40;string&#41;&#10;    filter_expression    &#61; optional&#40;string&#41;&#10;    flow_sampling        &#61; optional&#40;number&#41;&#10;    metadata             &#61; optional&#40;string&#41;&#10;    metadata_fields &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  ipv6 &#61; optional&#40;object&#40;&#123;&#10;    access_type &#61; optional&#40;string, &#34;INTERNAL&#34;&#41;&#10;  &#125;&#41;&#41;&#10;  secondary_ip_ranges &#61; optional&#40;map&#40;string&#41;&#41;&#10;  iam                 &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    role    &#61; string&#10;    members &#61; list&#40;string&#41;&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |
| [subnets_private_nat](variables.tf#L301) | List of private NAT subnets. | <code title="list&#40;object&#40;&#123;&#10;  name          &#61; string&#10;  ip_cidr_range &#61; string&#10;  region        &#61; string&#10;  description   &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |
| [subnets_proxy_only](variables.tf#L313) | List of proxy-only subnets for Regional HTTPS or Internal HTTPS load balancers. Note: Only one proxy-only subnet for each VPC network in each region can be active. | <code title="list&#40;object&#40;&#123;&#10;  name          &#61; string&#10;  ip_cidr_range &#61; string&#10;  region        &#61; string&#10;  description   &#61; optional&#40;string&#41;&#10;  active        &#61; optional&#40;bool, true&#41;&#10;  global        &#61; optional&#40;bool, false&#41;&#10;&#10;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    role    &#61; string&#10;    members &#61; list&#40;string&#41;&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |
| [subnets_psc](variables.tf#L347) | List of subnets for Private Service Connect service producers. | <code title="list&#40;object&#40;&#123;&#10;  name          &#61; string&#10;  ip_cidr_range &#61; string&#10;  region        &#61; string&#10;  description   &#61; optional&#40;string&#41;&#10;&#10;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    role    &#61; string&#10;    members &#61; list&#40;string&#41;&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |
| [vpc_create](variables.tf#L379) | Create VPC. When set to false, uses a data source to reference existing VPC. | <code>bool</code> |  | <code>true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified network id. |  |
| [internal_ipv6_range](outputs.tf#L29) | ULA range. |  |
| [name](outputs.tf#L34) | Network name. |  |
| [network](outputs.tf#L46) | Network resource. |  |
| [network_attachment_ids](outputs.tf#L58) | IDs of network attachments. |  |
| [project_id](outputs.tf#L66) | Project ID containing the network. Use this when you need to create resources *after* the VPC is fully set up (e.g. subnets created, shared VPC service projects attached, Private Service Networking configured). |  |
| [self_link](outputs.tf#L79) | Network self link. |  |
| [subnet_ids](outputs.tf#L91) | Map of subnet IDs keyed by name. |  |
| [subnet_ips](outputs.tf#L100) | Map of subnet address ranges keyed by name. |  |
| [subnet_ipv6_external_prefixes](outputs.tf#L107) | Map of subnet external IPv6 prefixes keyed by name. |  |
| [subnet_regions](outputs.tf#L115) | Map of subnet regions keyed by name. |  |
| [subnet_secondary_ranges](outputs.tf#L122) | Map of subnet secondary ranges keyed by name. |  |
| [subnet_self_links](outputs.tf#L133) | Map of subnet self links keyed by name. |  |
| [subnets](outputs.tf#L142) | Subnet resources. |  |
| [subnets_private_nat](outputs.tf#L151) | Private NAT subnet resources. |  |
| [subnets_proxy_only](outputs.tf#L156) | L7 ILB or L7 Regional LB subnet resources. |  |
| [subnets_psc](outputs.tf#L161) | Private Service Connect subnet resources. |  |
<!-- END TFDOC -->
