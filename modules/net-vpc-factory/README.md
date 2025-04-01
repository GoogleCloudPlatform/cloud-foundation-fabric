# Networking Factory

<!-- TOC -->

- [Networking Factory](#networking-factory)
  - [Factory configuration](#factory-configuration)
    - [Configuration Methods](#configuration-methods)
  - [Projects](#projects)
  - [VPCs](#vpcs)
    - [Subnets](#subnets)
    - [Firewall Rules](#firewall-rules)
    - [Cloud NAT](#cloud-nat)
    - [Routes](#routes)
    - [Private Service Access (PSA)](#private-service-access-psa)
  - [Connectivity](#connectivity)
    - [VPC Peering](#vpc-peering)
    - [Cloud VPN](#cloud-vpn)
      - [GCP to OnPrem](#gcp-to-onprem)
      - [GCP to GCP VPN](#gcp-to-gcp-vpn)
    - [Network Connectivity Center (NCC)](#network-connectivity-center-ncc)
  - [DNS](#dns)
    - [Private Zone](#private-zone)
    - [Forwarding Zone](#forwarding-zone)
    - [Peering Zone](#peering-zone)
  - [TODO](#todo)
  - [Tests](#tests)

<!-- /TOC -->

The factory is implemented as a thin data translation layer for the underlying modules, so that no "magic" or hidden side effects are implemented in code, and debugging or integration of new features are simple.

The code is meant to be executed by a high level service accounts with powerful permissions:

- Project Creator on the nodes (folder or org) where projects will be defined if projects are created by the factory, or
- Owner on the projects used to deploy the infrastructure
- XPN Admin on the nodes (folder or org) where projects are deployed, in case projects will be marked as "host projects"
- TODO(sruffilli) Finalize the list of required roles 

This factory module acts as a wrapper around several core Terraform modules:

`../project`: For managing GCP projects.
`../net-vpc`: For managing VPC networks, subnets, routes, PSA, etc.
`../net-vpc-firewall`: For managing VPC firewall rules.
`../net-vpn-ha`: For managing Cloud HA VPN connections.
`../net-cloudnat`: For managing Cloud NAT instances.
`../dns`: For managing Cloud DNS zones and record sets.

<!-- BEGIN TOC -->
- [Networking Factory](#networking-factory)
  - [Factory configuration](#factory-configuration)
    - [Configuration Methods](#configuration-methods)
  - [Projects](#projects)
  - [VPCs](#vpcs)
    - [Subnets](#subnets)
    - [Firewall Rules](#firewall-rules)
    - [Cloud NAT](#cloud-nat)
    - [Routes](#routes)
    - [Private Service Access (PSA)](#private-service-access-psa)
  - [Connectivity](#connectivity)
    - [VPC Peering](#vpc-peering)
    - [Cloud VPN](#cloud-vpn)
      - [GCP to OnPrem](#gcp-to-onprem)
      - [GCP to GCP VPN](#gcp-to-gcp-vpn)
    - [Network Connectivity Center (NCC)](#network-connectivity-center-ncc)
  - [DNS](#dns)
    - [Private Zone](#private-zone)
    - [Forwarding Zone](#forwarding-zone)
    - [Peering Zone](#peering-zone)
  - [TODO](#todo)
  - [Tests](#tests)
<!-- END TOC -->

## Factory configuration

At a high level, the factory consumes all YAML files in a directory (whose path is `var.factories_config.vpcs`).
Each file defines a single project, which can either be created by the factory or pre-created externally, and all the network infrastructure to be deployed in that project, including

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

### Configuration Methods

- **YAML Factory:** The primary method is to define project and network configurations within individual YAML files placed in the directory specified by `var.factories_config.vpcs`. This factory approach allows for modular and organized management of complex setups.
- **Direct Variable Input (Discouraged):** The module also defines a complex variable `var.network_project_config`. While it's *technically possible* to populate this variable directly (e.g., in a `.tfvars` file), this is **not the recommended approach**. It bypasses the intended factory pattern and makes managing multiple project configurations cumbersome. The variable definition primarily serves as **documentation** for the structure expected within the YAML configuration files.


## Projects

The `project_config` block within each YAML file implements a large subset of the [project module](../project/) variable interface, which allows amongst the rest for project creation or reuse, services enablement and IAM/Organization policies definition.

Below a valid YAML file which simply creates a project, enables a minimal set of services, configures the project as a host project and adds an authoritative 
role binding:

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=project-config
```

```yaml
project_config:
  name: project-config
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
      - group:prj-admins@example.com
# tftest-file id=project-config path=recipes/examples/project-config.yaml
```

## VPCs

The vpc_config block within each project's YAML file defines one or more VPCs to be created in that project. It implements a large subset of the [net-vpc module](../net-vpc/) variable interface, allowing for the creation of VPCs, subnets, routes, etc.

Below a valid YAML file excerpt with a minimal set of configurations creating a project and two VPCs, and pointing to sub-factories for subnets and firewall rules:

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=vpc-config
```

```yaml
project_config:
  name: vpc-config
  services:
    - compute.googleapis.com
vpc_config:
  net-00:
    delete_default_routes_on_create: false
    subnets_factory_config:
      subnets_folder: data/subnets/net-00
    firewall_factory_config:
      rules_folder: data/firewall/net-00
  net-01:
    delete_default_routes_on_create: false
# tftest-file id=vpc-config path=recipes/examples/vpc-config.yaml
```

### Subnets

Subnets are managed via the `vpc_config.<vpc_name>.subnets_factory_config` parameter within the project's YAML file. This leverages the [`net-vpc`](../net-vpc/) module for subnet creation and management. Please refer to its documentation for detailed information on subnet configuration options and the expected YAML structure within the subnets_folder.

### Firewall Rules

Firewall rules are managed via the `vpc_config.<vpc_name>.firewall_factory_config` parameter, which leverages the [net-vpc-firewall](../net-vpc-firewall/) module for firewall rule creation and management. Please refer to its documentation for detailed information on firewall rule configuration options and the expected YAML structure within the rules_folder.

### Cloud NAT

Cloud NAT is configured via the `vpc_config.<vpc_name>.nat_config` block. This uses the [net-cloudnat](../net-cloudnat/) module.

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=nat-config
```

```yaml
project_config:
  name: nat-config
  services:
    - compute.googleapis.com
vpc_config:
  net-00:
    delete_default_routes_on_create: false
    nat_config:
      nat-ew8:
        region: europe-west8
    subnets_factory_config:
      subnets_folder: data/subnets/foobar
    firewall_factory_config:
      rules_folder: data/firewall/foobar
# tftest-file id=nat-config path=recipes/examples/nat-config.yaml
```

### Routes

Static routes and Policy-Based Routes (PBRs) are configured within the vpc_config.<vpc_name> block.

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=routes-config
```

```yaml
project_config:
  name: routes-config
  services:
    - compute.googleapis.com
vpc_config:
  net-00:
    delete_default_routes_on_create: false
    nat_config:
      nat-ew8:
        region: europe-west8
    subnets_factory_config:
      subnets_folder: data/subnets/foobar
    firewall_factory_config:
      rules_folder: data/firewall/foobar
    routes:
      default-internet:
        dest_range: 0.0.0.0/0
        next_hop_type: gateway
        next_hop: default-internet-gateway
        priority: 1000
    policy_based_routes:
      pbr-to-nva:
        filter:
          src_range: 10.0.1.0/24
          dest_range: 0.0.0.0/0
        next_hop_ilb_ip: 10.0.100.5
        priority: 100
# tftest-file id=routes-config path=recipes/examples/routes-config.yaml
```

Refer to the [net-vpc](../net-vpc/) module documentation for details on routes and policy_based_routes.

### Private Service Access (PSA)

PSA configuration for services like Cloud SQL is managed via `vpc_config.<vpc_name>.psa_config`.

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=psa-config
```

```yaml
project_config:
  name: psa-config
  services:
    - compute.googleapis.com
vpc_config:
  net-00:
    delete_default_routes_on_create: false
    psa_config:
      - ranges:
          global-psa-range: 10.100.0.0/24
        peered_domains: ["onprem.example."]
# tftest-file id=psa-config path=recipes/examples/psa-config.yaml
```

Refer to the [net-vpc](../net-vpc) module documentation for details on psa_config.

## Connectivity

This module supports various connectivity options:

### VPC Peering

The example below implements a Hub-and-spoke design, where spokes are connected to the Hub via VPC Peerings:

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=peerings-hub,peerings-dev,peerings-prod
```

Hub:

```yaml
project_config:
  name: net-land-01
  services:
    - compute.googleapis.com
vpc_config:
  hub:
    peering_configs:
      to-prod:
        peer_network: net-prod-01/prod-spoke
      to-dev:
        peer_network: net-dev-01/dev-spoke
# tftest-file id=peerings-hub path=recipes/examples/net-land-01.yaml
```

Dev Spoke:

```yaml
project_config:
  name: net-dev-01
  services:
    - compute.googleapis.com
vpc_config:
  dev-spoke:
    peering_configs:
      to-hub:
        peer_network: net-land-01/hub

# tftest-file id=peerings-dev path=recipes/examples/net-dev-01.yaml
```

Prod Spoke:

```yaml
project_config:
  name: net-prod-01
  services:
    - compute.googleapis.com
vpc_config:
  prod-spoke:
    peering_configs:
      to-hub:
        peer_network: net-land-01/hub

# tftest-file id=peerings-prod path=recipes/examples/net-prod-01.yaml
```

### Cloud VPN

The example below implements a Hub-and-spoke design, where spokes are connected to the Hub via HA-VPN:

#### GCP to OnPrem

This example demonstrates connecting an on-premises network to a GCP VPC via HA-VPN. The `vpn_config` implements the same interface as module [net-vpn-ha](../net-vpn-ha/).

In this example, the configuration `vpc_config.net-00.routers` creates a router named `vpn-router` in europe-west8, and `vpc_config.net-00.vpn_config.to-onprem.router_config.name` refers to it, using the key `<project_key>/<vpc_key>/<router_key>` (e.g., prj-01/net-00/vpn-router.
Per module `net-vpn-ha`, omitting the `router_config` configuration results in the router being automatically created and managed by the VPN module itself.

Note that - given the limit of 5 Cloud Routers per VPC per region, we recommend creating fewer routers as required and using them across multiple VPNs/Interconnects by setting and referencing the pre-created router.

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=vpn-config
```

```yaml
project_config:
  name: prj-01
  services:
    - compute.googleapis.com
vpc_config:
  net-00:
    delete_default_routes_on_create: false
    routers:
      vpn-router:
        region: europe-west8
        asn: 64514
    vpn_config:
      to-onprem:
        region: europe-west8
        peer_gateways:
          default:
            external:
              redundancy_type: SINGLE_IP_INTERNALLY_REDUNDANT
              interfaces:
                - 8.8.8.8
        router_config:
          create: false
          name: prj-01/net-00/vpn-router
        tunnels:
          remote-0:
            bgp_peer:
              address: 169.254.1.1
              asn: 64513
            bgp_session_range: "169.254.1.2/30"
            peer_external_gateway_interface: 0
            shared_secret: "mySecret"
            vpn_gateway_interface: 0
          remote-1:
            bgp_peer:
              address: 169.254.2.1
              asn: 64513
            bgp_session_range: "169.254.2.2/30"
            peer_external_gateway_interface: 0
            shared_secret: "mySecret"
            vpn_gateway_interface: 1
# tftest-file id=vpn-config path=recipes/examples/vpn-config.yaml
```

#### GCP to GCP VPN

This examples demonstrates connecting a GCP VPC to a GCP VPC via HA-VPN.
In this examples, project `net-land-01` has a VPC named `hub`, and project `net-dev-01` has a VPC named `dev-spoke`, and the two VPCs are connected together via a HA VPN. In order to do so, the `vpc_config.vpn_config.to-hub.peer_gateways.default.gcp` on each side is configured by cross-referencing the VPN gateway in the other side, whose reference is `$project_id/$vpc_name/$vpn_name`.

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=vpn-hub,vpn-spoke
```

Hub:

```yaml
project_config:
  name: net-land-01
  services:
    - compute.googleapis.com
vpc_config:
  hub:
    vpn_config:
      to-dev:
        region: europe-west12
        peer_gateways:
          default:
            gcp: net-dev-01/dev-spoke/to-hub
        router_config:
          asn: 64521
        tunnels:
          remote-0:
            shared_secret: foobar
            bgp_peer:
              address: 169.254.2.2
              asn: 64520
            bgp_session_range: "169.254.2.1/30"
            vpn_gateway_interface: 0
          remote-1:
            shared_secret: foobar
            bgp_peer:
              address: 169.254.2.6
              asn: 64520
            bgp_session_range: "169.254.2.5/30"
            vpn_gateway_interface: 1
# tftest-file id=vpn-hub path=recipes/examples/net-land-01.yaml
```

Dev Spoke:

```yaml
project_config:
  name: net-dev-01
  services:
    - compute.googleapis.com
vpc_config:
  dev-spoke:
    vpn_config:
      to-hub:
        region: europe-west12
        peer_gateways:
          default:
            gcp: net-land-01/hub/to-dev
        router_config:
          asn: 64520
        tunnels:
          remote-0:
            shared_secret: foobar
            bgp_peer:
              address: 169.254.2.1
              asn: 64521
            bgp_session_range: "169.254.2.2/30"
            vpn_gateway_interface: 0
          remote-1:
            shared_secret: foobar
            bgp_peer:
              address: 169.254.2.5
              asn: 64521
            bgp_session_range: "169.254.2.6/30"
            vpn_gateway_interface: 1
# tftest-file id=vpn-spoke path=recipes/examples/net-dev-01.yaml
```

### Network Connectivity Center (NCC)

This minimal example demonstrates how to create an NCC hub, and how to connect multiple spokes to it. On the `net-land-01` project, `ncc_hub_config.groups.default.auto_accept` is configured to automatically accept the listed spoke projects.
On the spokes definition, `vpc_config.$env-spoke.ncc_config` cross references the hub and the default group.

NCC Hub:

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=ncc-hub,ncc-dev,ncc-prod
```

```yaml
project_config:
  name: net-land-01
  services:
    - compute.googleapis.com
    - networkmanagement.googleapis.com
ncc_hub_config:
  name: hub
  groups:
    default:
      auto_accept:
        - net-prod-01
        - net-dev-01
# tftest-file id=ncc-hub path=recipes/examples/net-land-01.yaml
```

Dev Spoke:

```yaml
project_config:
  name: net-dev-01
  services:
    - compute.googleapis.com
    - networkmanagement.googleapis.com
vpc_config:
  dev-spoke:
    ncc_config:
      hub: net-land-01/hub
# tftest-file id=ncc-dev path=recipes/examples/net-dev-01.yaml
```

Prod Spoke:

```yaml
project_config:
  name: net-prod-01
  services:
    - compute.googleapis.com
    - networkmanagement.googleapis.com
vpc_config:
  prod-spoke:
    ncc_config:
      hub: net-land-01/hub
      group: net-land-01/hub/default
# tftest-file id=ncc-prod path=recipes/examples/net-prod-01.yaml
```

## DNS

This module supports the creation of forwarding zones, peering zones, public and private zones, and recordsets within these zones. `vpc_config.$vpc.dns_zones` implements a large subset of the [net-dns](../dns/) module variable interface.

Below a few configuration examples:

### Private Zone

This example demonstrates how to create a private zone for the internal.example.com domain, and how to add a record set to it.

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=dns-private
```

```yaml
project_config:
  name: net-land-01
  services:
    - compute.googleapis.com
    - dns.googleapis.com
vpc_config:
  hub:
    dns_zones:
      internal-example:
        zone_config:
          domain: internal.example.com.
          private:
            client_networks:
              - net-land-01/hub
        recordsets:
          "A localhost":
            records: ["127.0.0.1"]
# tftest-file id=dns-private path=recipes/examples/net-land-01.yaml
```

### Forwarding Zone

This example demonstrates how to create a forwarding zone that forwards queries for the `example.com` domain to on-premises DNS servers.

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=dns-fwd
```

```yaml
project_config:
  name: net-land-01
  services:
    - compute.googleapis.com
    - dns.googleapis.com
vpc_config:
  hub:
    dns_zones:
      onprem-fwd:
        zone_config:
          domain: example.com.
          forwarding:
            forwarders:
              "10.0.0.1": default
              "10.0.0.2": default
            client_networks:
              - net-land-01/hub
# tftest-file id=dns-fwd path=recipes/examples/net-land-01.yaml
```

### Peering Zone

This example demonstrates how to create a peering zone that allows the dev-spoke VPC to resolve names in the net-land-01 project's hub VPC.

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=dns-peering
```

```yaml
project_config:
  name: net-dev-01
  services:
    - compute.googleapis.com
    - dns.googleapis.com
vpc_config:
  dev-spoke:
    dns_zones:
      root-peering:
        zone_config:
          domain: .
          peering:
            peer_network: net-land-01/hub
            client_networks:
              - net-dev-01/dev-spoke
# tftest-file id=dns-peering path=recipes/examples/net-land-01.yaml
```

All of the above combined implements a DNS hub-and-spoke design, where the DNS configuration is mostly centralised in the `net-land-01/hub` VPC, including private zones and forwarding to onprem, and spokes (in this case `net-dev-01/dev-spoke`) "delegate" the root zone (`.`, which is DNS for "*") to the central location via DNS peering.

<!-- BEGIN TFDOC -->
<!-- END TFDOC -->

## TODO

- PSC Endpoints management
- BUG: do not use filename as main key, use project_id instead!
- Implement 
  - iam_admin_delegated
  - iam_viewer
  - essential_contacts

## Tests

