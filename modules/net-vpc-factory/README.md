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

Below a valid YAML file which simply creates a project, enables a minimal set of services, configures the project as a host project and adds an authoritative role binding:

```yaml
project_config:
  name: prj-01
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
```

## VPCs

`var.network_project_config.vpc_config` implements a large subset of the [net-vpc module](../net-vpc/) variable interface, which allows amongst the rest for the creation of VPCs, subnets, and routes. In order to 

Below a valid YAML file with a minimal set of configurations creating a project and a VPC, enabling Cloud NAT on europe-west8, and creates subnets and firewall rules based on the pertinent sub-factories:

```yaml
project_config:
  name: prj-01
  services:
    - compute.googleapis.com
vpc_config:
  net-00:
    delete_default_routes_on_create: false
    mtu: 1500
    nat_config:
      nat-ew8:
        region: europe-west8
    subnets_factory_config:
      subnets_folder: data/subnets/foobar
    firewall_factory_config:
      rules_folder: data/firewall/foobar
```

## Connectivity

This module supports various connectivity options:

### VPC Peering

VPC peering allows you to connect VPC networks so that resources in different networks can communicate with each other using internal IP addresses.

```yaml
project_config:
  name: prj-01
  services:
    - compute.googleapis.com
vpc_config:
  net-00:
    peering_config:
      to-hub:
        peer_network: prj-hub-01/hub-vpc
```

### Cloud VPN

Cloud VPN securely connects your on-premises network to your VPC network through an IPsec VPN connection. The module supports HA VPN gateways and tunnels.

#### GCP to OnPrem

This example demonstrates connecting an on-premises network to a GCP VPC via HA-VPN. The `vpn_config` implements the same interface of module [net-vpn-ha](../net-vpn-ha/).

In this example, the configuration `vpc_config.routers` creates a router named `vpn-router` in europe-west8, and `vpc_config.vpn_config.to-onprem.router_config.name` refers to it, as `$project_id/$vpc_name/$router_name.`
Per module `net-vpn-ha`, omitting the `router_config` configuration results in the router being automatically created and managed.

Note that - given the limit of 5 Cloud Routers per VPC per region, we recommend creating as fewer routers as required, and use the across multiple VPNs/Interconnects.

```yaml
project_config:
  name: prj-01
  services:
    - compute.googleapis.com
vpc_config:
  net-00:
    delete_default_routes_on_create: false
    mtu: 1500
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
```

#### GCP to GCP VPN

This examples demonstrates connecting a GCP VPC to a GCP VPC via HA-VPN.
In this examples, project `net-land-01` has a VPC named `hub`, and project `net-dev-01` has a VPC named `dev-spoke`, and the two VPCs are connected together via a HA VPN. In order to do so, the `vpc_config.vpn_config.to-hub.peer_gateways.default.gcp` on each side is configured by cross-referencing the VPN gateway in the other side, whose reference is `$project_id/$vpc_name/$vpn_name`.

HUB: 

```yaml
project_config:
  name: net-land-01
  services:
    - compute.googleapis.com
vpc_config:
  hub:
    mtu: 1500
    routers:
      vpn-router:
        region: europe-west8
        asn: 64514
    vpn_config:
      to-dev:
        region: europe-west8
        peer_gateways:
          default:
            gcp: net-dev-01/dev-spoke/to-hub
        router_config:
          create: false
          name: net-land-01/hub/vpn-router
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
```

DEV-SPOKE:

```yaml
project_config:
  name: net-dev-01
  services:
    - compute.googleapis.com
vpc_config:
  dev-spoke:
    delete_default_routes_on_create: false
    mtu: 1500
    routers:
      vpn-router:
        region: europe-west8
        asn: 64520
    vpn_config:
      to-hub:
        region: europe-west8
        peer_gateways:
          default:
            gcp: net-land-01/hub/to-dev
        router_config:
          create: false
          name: net-dev-01/dev-spoke/vpn-router
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

```

### Network Connectivity Center (NCC)

This minimal example demonstrates how to create an NCC hub, and how to connect multiple spokes to it. On the `net-land-01` project, `ncc_hub_config.groups.default.auto_accept` is configured to automatically accept the required spoke projects.
On the spokes definition, `vpc_config.$env-spoke.ncc_config` cross references the hub and the default group.

NCC Hub:

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
    mtu: 1500
    ncc_config:
      hub: net-land-01/hub
      group: net-land-01/hub/default
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
    mtu: 1500
    ncc_config:
      hub: net-land-01/hub
      group: net-land-01/hub/default
```

## DNS

## Firewalls

## IAM

<!-- BEGIN TFDOC -->

<!-- END TFDOC -->

## TODO

- PSC Endpoints management

## Tests

