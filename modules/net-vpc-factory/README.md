# Networking Factory

This module implements end-to-end creation processes for networking, including projects, VPCs, connectivity, routing, DNS and firewalls, leveraging a YAML syntax.

The factory is implemented as a thin data translation layer for the underlying modules, so that no "magic" or hidden side effects are implemented in code, and debugging or integration of new features are simple.

The code is meant to be executed by a high level service accounts with powerful permissions:


- Project Creator on the nodes (folder or org) where projects will be defined if projects are created by the factory, or
- Owner on the projects used to deploy the infrastructure
- XPN Admin on the nodes (folder or org) where projects are deployed, in case projects will be marked as "host projects" 
- TODO(sruffilli) 

<!-- BEGIN TOC -->
<!-- END TOC -->

## Factory configuration

At a high level, the factory consumes all YAML files in a directory (whose path is `var.factories_config.vpcs`).
Each file defines a single project, which can either be created by the factory or pre-created extarnally, and all the network infrastructure to be deployed in that project, including

- Project
  - NCC Hubs
  - VPCs
    - Connectivity (including VPNs, VPC peerings, NCC VPC Spokes and NCC VPN hybrid spokes)
    - DNS policies
    - DNS zones
    - Firewall rules/policies (via a sub-factory)
    - NAT (public or private)
    - PSA configuration
    - Routes (including PBRs)
    - Subnets (via a sub-factory)

## Projects

`var.network_project_config.project_config` (and/or the `project_config` of each YAML file) implements a large subset of the [project module](../project/) variable interface, which allows amongst the rest for project creation or reuse, services enablement and IAM/Organization policies definition.

Below a valid YAML file which simply creates a project, enables a few services, configures the project as a host project and adds an authoritative role binding:

```yaml
project_config:
  name: net-dev-01
  services:
    - compute.googleapis.com
    - dns.googleapis.com
    - networkmanagement.googleapis.com
    - networksecurity.googleapis.com
    - servicenetworking.googleapis.com
    - stackdriver.googleapis.com
    - vpcaccess.googleapis.com
  shared_vpc_host_config:
    enabled: true
  iam:
    roles/owner:
      - group:foobar-admins@example.com
```

## VPCs

`var.network_project_config.vpc_config` implements a large subset of the [net-vpc module](../net-vpc/) variable interface, which allows amongst the rest for the creation of VPCs, subnets, and routes.

Below a valid YAML file which simply creates a project, enables a few services, configures the project as a host project and adds an authoritative role binding:

```yaml
project_config:
  name: net-dev-01
  services:
    - compute.googleapis.com
    - dns.googleapis.com
    - networkmanagement.googleapis.com
    - networksecurity.googleapis.com
    - servicenetworking.googleapis.com
    - stackdriver.googleapis.com
    - vpcaccess.googleapis.com
  shared_vpc_host_config:
    enabled: true
  iam:
    roles/owner:
      - group:foobar-admins@example.com
```

## Connectivity

## DNS

## Firewalls

## IAM

<!-- BEGIN TFDOC -->

<!-- END TFDOC -->

## TODO

- PSC Endpoints management

## Tests

