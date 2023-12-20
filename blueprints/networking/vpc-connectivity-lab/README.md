# Network Sandbox

This blueprint creates a networking playground showing a number of different VPC connectivity options:

* Hub and spoke via HA VPN
* Hub and spoke via VPC peering
* Interconnecting two networks via a network virtual appliance (aka NVA)

On top of that, this blueprint implements Policy Based Routing (aka PBR) to show how to implement an Intrusion Prevention System (IPS) within the `hub` VPC.

The blueprint has been purposefully kept simple to show how to use and wire the VPC and VPN-HA modules together, and so that it can be used as a basis for experimentation.

This is the high level diagram of this blueprint:

![High-level diagram](diagram.png "High-level diagram")

## Prerequisites

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->

<!-- END TFDOC -->

## Test
