# Networking Factory

The factory is implemented as a thin data translation layer for the underlying modules, so that no "magic" or hidden side effects are implemented in code, and debugging or integration of new features are simple.

The code is meant to be executed by a service account or a user with a wide set of permissions:

- roles/resourcemanager.projectCreator (only if creating projects)
- roles/billing.user (only if creating projects)
- roles/resourcemanager.folderViewer (if parent is folder)
- roles/orgpolicy.policyAdmin (at the organization level, in case you're configuring Org Policies)
- roles/compute.xpnAdmin (at the parent folder level, if Shared VPC is used)

This factory module acts as a wrapper around several core Terraform modules:

- [`../project`](../project/): For managing GCP projects.
- [`../net-vpc`](../net-vpc): For managing VPC networks, subnets, routes, PSA, etc.
- [`../net-vpc-firewall`](../net-vpc-firewall/): For managing VPC firewall rules.
- [`../net-vpn-ha`](../net-vpn-ha): For managing Cloud HA VPN connections.
- [`../net-cloudnat`](../net-cloudnat/): For managing Cloud NAT instances.
- [`../dns`](../dns): For managing Cloud DNS zones and record sets.

## TOC

<!-- BEGIN TOC -->
- [TOC](#toc)
- [Factory configuration](#factory-configuration)
  - [Configuration Methods](#configuration-methods)
  - [Cross-Referencing Resources](#cross-referencing-resources)
- [Projects](#projects)
- [VPCs](#vpcs)
  - [Subnets](#subnets)
  - [Firewall Rules](#firewall-rules)
  - [Cloud NAT](#cloud-nat)
  - [Routes](#routes)
  - [Private Service Access (PSA)](#private-service-access-psa)
  - [VPC DNS Policy](#vpc-dns-policy)
- [Connectivity](#connectivity)
  - [VPC Peering](#vpc-peering)
  - [Cloud VPN](#cloud-vpn)
    - [GCP to OnPrem](#gcp-to-onprem)
    - [GCP to GCP VPN](#gcp-to-gcp-vpn)
  - [Network Connectivity Center (NCC)](#network-connectivity-center-ncc)
    - [NCC VPC Spokes](#ncc-vpc-spokes)
    - [NCC VPN Spokes](#ncc-vpn-spokes)
- [DNS](#dns)
  - [Private Zone](#private-zone)
  - [Forwarding Zone](#forwarding-zone)
  - [Peering Zone](#peering-zone)
  - [Public Zone with DNSSEC](#public-zone-with-dnssec)
- [Variables](#variables)
- [Outputs](#outputs)
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
- **Direct Variable Input (Discouraged):** The module also defines `var.network_project_config`. While it's *technically possible* to populate this variable directly in a .tfvars file, this is **not the recommended approach**. It bypasses the intended factory pattern and makes managing multiple project configurations cumbersome. The variable definition primarily serves as **documentation** for the structure expected within the YAML configuration files.

### Cross-Referencing Resources

A key capability of this factory is establishing relationships between resources defined across different VPCs or projects. This is achieved through cross-referencing using logical keys within the YAML configuration. These keys strictly follow the pattern `project_key/vpc_key/resource_key` for resources like VPCs, VPN gateways, routers, or NCC hubs/groups. During Terraform execution, the factory code translates these logical keys into the actual resource IDs or self-links required by the underlying modules. This mechanism avoids hardcoding resource IDs and enables the declarative definition of complex topologies. It's extensively used in configurations for:

VPC Peering: Specifying the peer_network (e.g., `peer_network: net-land-01/hub`).

DNS Peering/Forwarding: Defining peer_network or client_networks for DNS zones (e.g., `client_networks: [net-dev-01/dev-spoke]`).

GCP-to-GCP HA VPN: Referencing the peer HA VPN gateway using its logical key (e.g., `peer_gateways.default.gcp: net-dev-01/dev-spoke/to-hub`).

Network Connectivity Center (NCC): Linking spokes to hubs (`ncc_config.hub: net-land-01/hub`) and groups (`ncc_config.group: net-land-01/hub/default`), or auto-accepting spokes in hub groups (`auto_accept: [net-prod-01, net-dev-01]`).

## Projects

The `project_config` block within each YAML file implements a large subset of the [project module](../project/) variable interface, which allows for project creation or reuse, services enablement and IAM/Organization policies definition.

Below is a valid YAML file which simply creates a project, enables a minimal set of services, configures the project as a host project, adds an authoritative
role binding and sets an Organization Policy at the project level:

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
  org_policies:
    compute.restrictLoadBalancerCreationForTypes:
      rules:
        - allow:
            values:
              - EXTERNAL_HTTP_HTTPS
# tftest-file id=project-config path=recipes/examples/project-config.yaml schema=network-project.schema.json
```

## VPCs

The `vpc_config` block within each project's YAML file defines one or more VPCs to be created in that project. It implements a large subset of the [net-vpc module](../net-vpc/) variable interface, allowing for the creation of VPCs, subnets, routes, etc.

Below is a valid YAML file excerpt with a minimal set of configurations creating a project and two VPCs, and pointing to sub-factories for subnets and firewall rules:

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
    subnets_factory_config:
      subnets_folder: data/subnets/net-00
    firewall_factory_config:
      rules_folder: data/firewall/net-00
# tftest-file id=vpc-config path=recipes/examples/vpc-config.yaml schema=network-project.schema.json
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
# tftest-file id=nat-config path=recipes/examples/nat-config.yaml schema=network-project.schema.json
```

### Routes

Static routes and Policy-Based Routes (PBRs) are configured within the `vpc_config.<vpc_name>.routes` and `vpc_config.<vpc_name>.policy_based_routes` blocks.

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
# tftest-file id=routes-config path=recipes/examples/routes-config.yaml schema=network-project.schema.json
```

Refer to the [net-vpc](../net-vpc/) module documentation for details on routes and policy_based_routes.

### Private Service Access (PSA)

PSA configuration is managed via `vpc_config.<vpc_name>.psa_config`.

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
    psa_config:
      - ranges:
          global-psa-range: 10.100.0.0/24
        peered_domains: ["onprem.example."]
# tftest-file id=psa-config path=recipes/examples/psa-config.yaml schema=network-project.schema.json
```

Refer to the [net-vpc](../net-vpc) module documentation for details on psa_config.

### VPC DNS Policy

Configure VPC-level DNS behavior, such as enabling inbound query forwarding or logging, using the `dns_policy` block.

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=vpc-dns-policy
```

```yaml
project_config:
  name: vpc-dns-policy
  services:
    - compute.googleapis.com
    - dns.googleapis.com
vpc_config:
  net-dns-policy-demo:
    dns_policy:
      inbound: true
      logging: true
# tftest-file id=vpc-dns-policy path=recipes/examples/vpc-dns-policy.yaml schema=network-project.schema.json
```

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
    peering_config:
      to-prod:
        peer_network: net-prod-01/prod-spoke
      to-dev:
        peer_network: net-dev-01/dev-spoke
        stack_type: IPV4_IPV6
        
# tftest-file id=peerings-hub path=recipes/examples/net-land-01.yaml schema=network-project.schema.json
```

Dev Spoke:

```yaml
project_config:
  name: net-dev-01
  services:
    - compute.googleapis.com
vpc_config:
  dev-spoke:
    peering_config:
      to-hub:
        peer_network: net-land-01/hub
        stack_type: IPV4_IPV6

# tftest-file id=peerings-dev path=recipes/examples/net-dev-01.yaml schema=network-project.schema.json
```

Prod Spoke:

```yaml
project_config:
  name: net-prod-01
  services:
    - compute.googleapis.com
vpc_config:
  prod-spoke:
    peering_config:
      to-hub:
        peer_network: net-land-01/hub

# tftest-file id=peerings-prod path=recipes/examples/net-prod-01.yaml schema=network-project.schema.json
```

### Cloud VPN

The example below implements a Hub-and-spoke design, where spokes are connected to the Hub via HA-VPN:

#### GCP to OnPrem

This example demonstrates connecting an on-premises network to GCP via HA-VPN. The `vpn_config` implements the same interface as module [net-vpn-ha](../net-vpn-ha/).

In this example, the configuration `vpc_config.net-00.routers` creates a router named `vpn-router` in europe-west8, and `vpc_config.net-00.vpn_config.to-onprem.router_config.name` refers to it, using the key `<project_key>/<vpc_key>/<router_key>` (e.g., prj-01/net-00/vpn-router.
Per module `net-vpn-ha`, omitting the `router_config` configuration results in the router being automatically created and managed by the VPN module itself.

Note that - given the limit of 5 Cloud Routers per VPC per region - we recommend creating routers as required and using them across multiple VPNs/Interconnects by setting and referencing the pre-created router.

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
# tftest-file id=vpn-config path=recipes/examples/vpn-config.yaml schema=network-project.schema.json
```

#### GCP to GCP VPN

These examples demonstrates VPC to VPC connectivity via HA VPN.
In this examples, project `net-land-01` has a VPC named `hub` and project `net-dev-01` has a VPC named `dev-spoke`; the two VPCs are connected together via HA VPN. In order to do so, the `vpc_config.vpn_config.to-hub.peer_gateways.default.gcp` on each side is configured by cross-referencing the VPN gateway in the other side, whose reference is `<project_id>/<vpc_name>/<vpn_name>`.

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
# tftest-file id=vpn-hub path=recipes/examples/net-land-01.yaml schema=network-project.schema.json
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
# tftest-file id=vpn-spoke path=recipes/examples/net-dev-01.yaml schema=network-project.schema.json
```

### Network Connectivity Center (NCC)

#### NCC VPC Spokes

This example demonstrates how to create an NCC hub, and how to connect multiple spokes to it. On the `net-land-01` project, `ncc_hub_config.groups.default.auto_accept` is configured to automatically accept the listed spoke projects.
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
# tftest-file id=ncc-hub path=recipes/examples/net-land-01.yaml schema=network-project.schema.json
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
# tftest-file id=ncc-dev path=recipes/examples/net-dev-01.yaml schema=network-project.schema.json
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
# tftest-file id=ncc-prod path=recipes/examples/net-prod-01.yaml schema=network-project.schema.json
```

#### NCC VPN Spokes

This example shows how to connect HA VPN tunnels, typically used for on-premises or other cloud connections, as spokes in an NCC Hub. This enables transitive routing between VPC spokes and the VPN connection via the NCC Hub.

The key is the `ncc_spoke_config` block within the `vpn_config` definition on the hub project (`net-land-01/hub`).

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=ncc-vpn
```

```yaml
project_config:
  name: net-land-01
  services:
    - compute.googleapis.com
    - networkmanagement.googleapis.com
ncc_hub_config:
  name: hub
vpc_config:
  hub:
    mtu: 1500
    routers:
      vpn-router:
        region: europe-west8
        asn: 64514
    vpn_config:
      to-onprem:
        ncc_spoke_config:
          hub: net-land-01/hub
        region: europe-west8
        peer_gateways:
          default:
            external:
              redundancy_type: SINGLE_IP_INTERNALLY_REDUNDANT
              interfaces:
                - 8.8.8.8
        router_config:
          create: false
          name: net-land-01/hub/vpn-router
        tunnels:
          remote-0:
            bgp_peer:
              address: 169.254.128.1
              asn: 64513
            bgp_session_range: "169.254.128.2/30"
            peer_external_gateway_interface: 0
            shared_secret: "mySecret"
            vpn_gateway_interface: 0
          remote-1:
            bgp_peer:
              address: 169.254.128.5
              asn: 64513
            bgp_session_range: "169.254.128.6/30"
            peer_external_gateway_interface: 0
            shared_secret: "mySecret"
            vpn_gateway_interface: 1
# tftest-file id=ncc-vpn path=recipes/examples/net-land-01.yaml schema=network-project.schema.json
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
# tftest-file id=dns-private path=recipes/examples/net-land-01.yaml schema=network-project.schema.json
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
# tftest-file id=dns-fwd path=recipes/examples/net-land-01.yaml schema=network-project.schema.json
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
# tftest-file id=dns-peering path=recipes/examples/net-land-01.yaml schema=network-project.schema.json
```

All of the above combined implements a DNS hub-and-spoke design, where the DNS configuration is mostly centralised in the `net-land-01/hub` VPC, including private zones and forwarding to onprem, and spokes (in this case `net-dev-01/dev-spoke`) "delegate" the root zone (`.`, which is DNS for "*") to the central location via DNS peering.

### Public Zone with DNSSEC

This example demonstrates creating a public DNS zone and enabling DNSSEC.

```hcl
module "net-vpc-factory" {
  source           = "./fabric/modules/net-vpc-factory"
  billing_account  = "123456-789012-345678"
  parent_id        = "folders/123456789012"
  prefix           = "myprefix"
  factories_config = { vpcs = "recipes/examples" }
}
# tftest files=dns-public-dnssec
```

```yaml
project_config:
  name: net-dns-public
  services:
    - compute.googleapis.com
    - dns.googleapis.com
vpc_config:
  hub:
    dns_zones:
      public-example-com:
        zone_config:
          domain: my-public-domain.example.com.
          public:
            dnssec_config:
              state: "on"
        recordsets:
          "A www":
            records: ["192.0.2.1"]
# tftest-file id=dns-public-dnssec path=recipes/examples/net-dns-public.yaml schema=network-project.schema.json
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [billing_account](variables.tf#L17) | Billing account id. | <code>string</code> | ✓ |  |
| [parent_id](variables.tf#L374) | Root node for the projects created by the factory. Must be either organizations/XXXXXXXX or folders/XXXXXXXX. | <code>string</code> | ✓ |  |
| [prefix](variables.tf#L379) | Prefix used for projects. | <code>string</code> | ✓ |  |
| [factories_config](variables.tf#L22) | Configuration for network resource factories. | <code title="object&#40;&#123;&#10;  vpcs                 &#61; optional&#40;string, &#34;recipes&#47;hub-and-spoke-ncc&#34;&#41;&#10;  firewall_policy_name &#61; optional&#40;string, &#34;net-default&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  vpcs &#61; &#34;recipes&#47;hub-and-spoke-ncc&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [network_project_config](variables.tf#L33) | Consolidated configuration for project, VPCs and their associated resources. | <code title="map&#40;object&#40;&#123;&#10;  project_config &#61; object&#40;&#123;&#10;    name                    &#61; string&#10;    prefix                  &#61; optional&#40;string&#41;&#10;    parent                  &#61; optional&#40;string&#41;&#10;    billing_account         &#61; optional&#40;string&#41;&#10;    deletion_policy         &#61; optional&#40;string, &#34;DELETE&#34;&#41;&#10;    default_service_account &#61; optional&#40;string, &#34;keep&#34;&#41;&#10;    auto_create_network     &#61; optional&#40;bool, false&#41;&#10;    project_create          &#61; optional&#40;bool, true&#41;&#10;    shared_vpc_host_config &#61; optional&#40;object&#40;&#123;&#10;      enabled          &#61; bool&#10;      service_projects &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    &#125;&#41;&#41;&#10;    services &#61; optional&#40;list&#40;string&#41;, &#41;&#10;    org_policies &#61; optional&#40;map&#40;object&#40;&#123;&#10;      inherit_from_parent &#61; optional&#40;bool&#41;&#10;      reset               &#61; optional&#40;bool&#41;&#10;      rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;        allow &#61; optional&#40;object&#40;&#123;&#10;          all    &#61; optional&#40;bool&#41;&#10;          values &#61; optional&#40;list&#40;string&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        deny &#61; optional&#40;object&#40;&#123;&#10;          all    &#61; optional&#40;bool&#41;&#10;          values &#61; optional&#40;list&#40;string&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        enforce &#61; optional&#40;bool&#41;&#10;        condition &#61; optional&#40;object&#40;&#123;&#10;          description &#61; optional&#40;string&#41;&#10;          expression  &#61; optional&#40;string&#41;&#10;          location    &#61; optional&#40;string&#41;&#10;          title       &#61; optional&#40;string&#41;&#10;        &#125;&#41;, &#123;&#125;&#41;&#10;      &#125;&#41;&#41;, &#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    metric_scopes &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    iam           &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;      members &#61; list&#40;string&#41;&#10;      role    &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;      member &#61; string&#10;      role   &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    iam_by_principals_additive &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    iam_by_principals          &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#10;  ncc_hub_config &#61; optional&#40;object&#40;&#123;&#10;    name            &#61; string&#10;    description     &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    preset_topology &#61; optional&#40;string, &#34;MESH&#34;&#41;&#10;    export_psc      &#61; optional&#40;bool, true&#41;&#10;    groups &#61; optional&#40;map&#40;object&#40;&#123;&#10;      labels      &#61; optional&#40;map&#40;string&#41;&#41;&#10;      description &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;      auto_accept &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  vpc_config &#61; optional&#40;map&#40;object&#40;&#123;&#10;    auto_create_subnetworks &#61; optional&#40;bool, false&#41;&#10;    create_googleapis_routes &#61; optional&#40;object&#40;&#123;&#10;      private      &#61; optional&#40;bool, true&#41;&#10;      private-6    &#61; optional&#40;bool, false&#41;&#10;      restricted   &#61; optional&#40;bool, true&#41;&#10;      restricted-6 &#61; optional&#40;bool, false&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    delete_default_routes_on_create &#61; optional&#40;bool, false&#41;&#10;    description                     &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    dns_policy &#61; optional&#40;object&#40;&#123;&#10;      inbound &#61; optional&#40;bool&#41;&#10;      logging &#61; optional&#40;bool&#41;&#10;      outbound &#61; optional&#40;object&#40;&#123;&#10;        private_ns &#61; list&#40;string&#41;&#10;        public_ns  &#61; list&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    dns_zones &#61; optional&#40;map&#40;object&#40;&#123;&#10;      force_destroy &#61; optional&#40;bool&#41;&#10;      description   &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;      iam           &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;      zone_config &#61; object&#40;&#123;&#10;        domain &#61; string&#10;        forwarding &#61; optional&#40;object&#40;&#123;&#10;          forwarders      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;          client_networks &#61; optional&#40;list&#40;string&#41;, &#41;&#10;        &#125;&#41;&#41;&#10;        peering &#61; optional&#40;object&#40;&#123;&#10;          client_networks &#61; optional&#40;list&#40;string&#41;, &#41;&#10;          peer_network    &#61; string&#10;        &#125;&#41;&#41;&#10;        public &#61; optional&#40;object&#40;&#123;&#10;          dnssec_config &#61; optional&#40;object&#40;&#123;&#10;            non_existence &#61; optional&#40;string, &#34;nsec3&#34;&#41;&#10;            state         &#61; string&#10;            key_signing_key &#61; optional&#40;object&#40;&#10;              &#123; algorithm &#61; string, key_length &#61; number &#125;&#41;,&#10;              &#123; algorithm &#61; &#34;rsasha256&#34;, key_length &#61; 2048 &#125;&#10;            &#41;&#10;            zone_signing_key &#61; optional&#40;object&#40;&#10;              &#123; algorithm &#61; string, key_length &#61; number &#125;&#41;,&#10;              &#123; algorithm &#61; &#34;rsasha256&#34;, key_length &#61; 1024 &#125;&#10;            &#41;&#10;          &#125;&#41;&#41;&#10;          enable_logging &#61; optional&#40;bool, false&#41;&#10;        &#125;&#41;&#41;&#10;        private &#61; optional&#40;object&#40;&#123;&#10;          client_networks             &#61; optional&#40;list&#40;string&#41;, &#41;&#10;          service_directory_namespace &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#10;      recordsets &#61; optional&#40;map&#40;object&#40;&#123;&#10;        ttl     &#61; optional&#40;number, 300&#41;&#10;        records &#61; optional&#40;list&#40;string&#41;&#41;&#10;        geo_routing &#61; optional&#40;list&#40;object&#40;&#123;&#10;          location &#61; string&#10;          records  &#61; optional&#40;list&#40;string&#41;&#41;&#10;          health_checked_targets &#61; optional&#40;list&#40;object&#40;&#123;&#10;            load_balancer_type &#61; string&#10;            ip_address         &#61; string&#10;            port               &#61; string&#10;            ip_protocol        &#61; string&#10;            network_url        &#61; string&#10;            project            &#61; string&#10;            region             &#61; optional&#40;string&#41;&#10;          &#125;&#41;&#41;&#41;&#10;        &#125;&#41;&#41;&#41;&#10;        wrr_routing &#61; optional&#40;list&#40;object&#40;&#123;&#10;          weight  &#61; number&#10;          records &#61; list&#40;string&#41;&#10;        &#125;&#41;&#41;&#41;&#10;      &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    &#125;&#41;&#41;&#41;&#10;    firewall_policy_enforcement_order &#61; optional&#40;string, &#34;AFTER_CLASSIC_FIREWALL&#34;&#41;&#10;    ipv6_config &#61; optional&#40;object&#40;&#123;&#10;      enable_ula_internal &#61; optional&#40;bool&#41;&#10;      internal_range      &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    mtu  &#61; optional&#40;number&#41;&#10;    name &#61; string&#10;    nat_config &#61; optional&#40;map&#40;object&#40;&#123;&#10;      region         &#61; string&#10;      router_create  &#61; optional&#40;bool, true&#41;&#10;      router_name    &#61; optional&#40;string&#41;&#10;      router_network &#61; optional&#40;string&#41;&#10;      router_asn     &#61; optional&#40;number&#41;&#10;      type           &#61; optional&#40;string, &#34;PUBLIC&#34;&#41;&#10;      addresses      &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;      endpoint_types &#61; optional&#40;list&#40;string&#41;&#41;&#10;      logging_filter &#61; optional&#40;string&#41;&#10;      config_port_allocation &#61; optional&#40;object&#40;&#123;&#10;        enable_endpoint_independent_mapping &#61; optional&#40;bool, true&#41;&#10;        enable_dynamic_port_allocation      &#61; optional&#40;bool, false&#41;&#10;        min_ports_per_vm                    &#61; optional&#40;number&#41;&#10;        max_ports_per_vm                    &#61; optional&#40;number, 65536&#41;&#10;      &#125;&#41;, &#123;&#125;&#41;&#10;      config_source_subnetworks &#61; optional&#40;object&#40;&#123;&#10;        all                 &#61; optional&#40;bool, true&#41;&#10;        primary_ranges_only &#61; optional&#40;bool&#41;&#10;        subnetworks &#61; optional&#40;list&#40;object&#40;&#123;&#10;          self_link        &#61; string&#10;          all_ranges       &#61; optional&#40;bool, true&#41;&#10;          primary_range    &#61; optional&#40;bool, false&#41;&#10;          secondary_ranges &#61; optional&#40;list&#40;string&#41;&#41;&#10;        &#125;&#41;&#41;, &#91;&#93;&#41;&#10;      &#125;&#41;, &#123;&#125;&#41;&#10;      config_timeouts &#61; optional&#40;object&#40;&#123;&#10;        icmp            &#61; optional&#40;number&#41;&#10;        tcp_established &#61; optional&#40;number&#41;&#10;        tcp_time_wait   &#61; optional&#40;number&#41;&#10;        tcp_transitory  &#61; optional&#40;number&#41;&#10;        udp             &#61; optional&#40;number&#41;&#10;      &#125;&#41;, &#123;&#125;&#41;&#10;      rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;        description   &#61; optional&#40;string&#41;&#10;        match         &#61; string&#10;        source_ips    &#61; optional&#40;list&#40;string&#41;&#41;&#10;        source_ranges &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;, &#91;&#93;&#41;&#10;&#10;&#10;    &#125;&#41;&#41;&#41;&#10;    network_attachments &#61; optional&#40;map&#40;object&#40;&#123;&#10;      subnet                &#61; string&#10;      automatic_connection  &#61; optional&#40;bool, false&#41;&#10;      description           &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;      producer_accept_lists &#61; optional&#40;list&#40;string&#41;&#41;&#10;      producer_reject_lists &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    policy_based_routes &#61; optional&#40;map&#40;object&#40;&#123;&#10;      description         &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;      labels              &#61; optional&#40;map&#40;string&#41;&#41;&#10;      priority            &#61; optional&#40;number&#41;&#10;      next_hop_ilb_ip     &#61; optional&#40;string&#41;&#10;      use_default_routing &#61; optional&#40;bool, false&#41;&#10;      filter &#61; optional&#40;object&#40;&#123;&#10;        ip_protocol &#61; optional&#40;string&#41;&#10;        dest_range  &#61; optional&#40;string&#41;&#10;        src_range   &#61; optional&#40;string&#41;&#10;      &#125;&#41;, &#123;&#125;&#41;&#10;      target &#61; optional&#40;object&#40;&#123;&#10;        interconnect_attachment &#61; optional&#40;string&#41;&#10;        tags                    &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;, &#123;&#125;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    psa_config &#61; optional&#40;list&#40;object&#40;&#123;&#10;      deletion_policy  &#61; optional&#40;string, null&#41;&#10;      ranges           &#61; map&#40;string&#41;&#10;      export_routes    &#61; optional&#40;bool, false&#41;&#10;      import_routes    &#61; optional&#40;bool, false&#41;&#10;      peered_domains   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;      range_prefix     &#61; optional&#40;string&#41;&#10;      service_producer &#61; optional&#40;string, &#34;servicenetworking.googleapis.com&#34;&#41;&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    routers &#61; optional&#40;map&#40;object&#40;&#123;&#10;      region &#61; string&#10;      asn    &#61; optional&#40;number&#41;&#10;      custom_advertise &#61; optional&#40;object&#40;&#123;&#10;        all_subnets &#61; bool&#10;        ip_ranges   &#61; map&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      keepalive &#61; optional&#40;number&#41;&#10;      name      &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#41;&#10;    routes &#61; optional&#40;map&#40;object&#40;&#123;&#10;      description   &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;      dest_range    &#61; string&#10;      next_hop_type &#61; string&#10;      next_hop      &#61; string&#10;      priority      &#61; optional&#40;number&#41;&#10;      tags          &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    routing_mode &#61; optional&#40;string, &#34;GLOBAL&#34;&#41;&#10;    subnets_factory_config &#61; optional&#40;object&#40;&#123;&#10;      context &#61; optional&#40;object&#40;&#123;&#10;        regions &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;      &#125;&#41;, &#123;&#125;&#41;&#10;      subnets_folder &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    firewall_factory_config &#61; optional&#40;object&#40;&#123;&#10;      cidr_tpl_file &#61; optional&#40;string&#41;&#10;      rules_folder  &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    vpn_config &#61; optional&#40;map&#40;object&#40;&#123;&#10;      name   &#61; string&#10;      region &#61; string&#10;      ncc_spoke_config &#61; optional&#40;object&#40;&#123;&#10;        hub         &#61; string&#10;        description &#61; string&#10;        labels      &#61; map&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      peer_gateways &#61; map&#40;object&#40;&#123;&#10;        external &#61; optional&#40;object&#40;&#123;&#10;          redundancy_type &#61; string&#10;          interfaces      &#61; list&#40;string&#41;&#10;          description     &#61; optional&#40;string, &#34;Terraform managed external VPN gateway&#34;&#41;&#10;          name            &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;        gcp &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      router_config &#61; object&#40;&#123;&#10;        asn    &#61; optional&#40;number&#41;&#10;        create &#61; optional&#40;bool, true&#41;&#10;        custom_advertise &#61; optional&#40;object&#40;&#123;&#10;          all_subnets &#61; bool&#10;          ip_ranges   &#61; map&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;        keepalive     &#61; optional&#40;number&#41;&#10;        name          &#61; optional&#40;string&#41;&#10;        override_name &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#10;      stack_type &#61; optional&#40;string&#41;&#10;      tunnels &#61; map&#40;object&#40;&#123;&#10;        bgp_peer &#61; object&#40;&#123;&#10;          address        &#61; string&#10;          asn            &#61; number&#10;          route_priority &#61; optional&#40;number, 1000&#41;&#10;          custom_advertise &#61; optional&#40;object&#40;&#123;&#10;            all_subnets &#61; bool&#10;            ip_ranges   &#61; map&#40;string&#41;&#10;          &#125;&#41;&#41;&#10;          md5_authentication_key &#61; optional&#40;object&#40;&#123;&#10;            name &#61; string&#10;            key  &#61; optional&#40;string&#41;&#10;          &#125;&#41;&#41;&#10;          ipv6 &#61; optional&#40;object&#40;&#123;&#10;            nexthop_address      &#61; optional&#40;string&#41;&#10;            peer_nexthop_address &#61; optional&#40;string&#41;&#10;          &#125;&#41;&#41;&#10;          name &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#10;        bgp_session_range               &#61; string&#10;        ike_version                     &#61; optional&#40;number, 2&#41;&#10;        name                            &#61; optional&#40;string&#41;&#10;        peer_external_gateway_interface &#61; optional&#40;number&#41;&#10;        peer_router_interface_name      &#61; optional&#40;string&#41;&#10;        peer_gateway                    &#61; optional&#40;string, &#34;default&#34;&#41;&#10;        router                          &#61; optional&#40;string&#41;&#10;        shared_secret                   &#61; optional&#40;string&#41;&#10;        vpn_gateway_interface           &#61; number&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    peering_config &#61; optional&#40;map&#40;object&#40;&#123;&#10;      peer_network &#61; string&#10;      routes_config &#61; optional&#40;object&#40;&#123;&#10;        export        &#61; optional&#40;bool, true&#41;&#10;        import        &#61; optional&#40;bool, true&#41;&#10;        public_export &#61; optional&#40;bool&#41;&#10;        public_import &#61; optional&#40;bool&#41;&#10;        &#125;&#10;      &#41;, &#123;&#125;&#41;&#10;      stack_type &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    ncc_config &#61; optional&#40;object&#40;&#123;&#10;      hub                   &#61; string&#10;      description           &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;      labels                &#61; optional&#40;map&#40;string&#41;&#41;&#10;      group                 &#61; optional&#40;string&#41;&#10;      exclude_export_ranges &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;      include_export_ranges &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [project_reuse](variables.tf#L384) | Reuse existing project if not null. If name and number are not passed in, a data source is used. | <code title="object&#40;&#123;&#10;  use_data_source &#61; optional&#40;bool, true&#41;&#10;  attributes &#61; optional&#40;object&#40;&#123;&#10;    name             &#61; string&#10;    number           &#61; number&#10;    services_enabled &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [host_project_ids](outputs.tf#L17) | Network project ids. |  |
| [host_project_numbers](outputs.tf#L22) | Network project numbers. |  |
| [subnet_ids](outputs.tf#L27) | IDs of subnets created within each VPC. |  |
| [subnet_proxy_only_self_links](outputs.tf#L32) | IDs of proxy-only subnets created within each VPC. |  |
| [subnet_psc_self_links](outputs.tf#L42) | IDs of PSC subnets created within each VPC. |  |
| [vpc_self_links](outputs.tf#L52) | Self-links for the VPCs created on each project. |  |
| [vpn_gateway_endpoints](outputs.tf#L57) | External IP Addresses for the GCP VPN gateways. |  |
<!-- END TFDOC -->
