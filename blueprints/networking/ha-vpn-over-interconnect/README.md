# HA VPN over Interconnect

This blueprint creates a complete HA VPN over Interconnect setup, which leverages IPSec to encrypt all traffic transiting through purposedly-created VLAN Attachments.

This blueprint supports Dedicated Interconnect - in case Partner Interconnect is used instead (hence the VLAN Attachments are already created), simply refer to the [net-ipsec-over-interconnect](../../../modules/net-ipsec-over-interconnect/) module documentation.

TODO(sruffilli): add a diagram

## Managed resources and services

This blueprint creates two distinct sets of resources:

- Underlay
  - A Cloud Router dedicated to the underlay networking, which exchanges and routes the VPN gateways ranges
  - Two VLAN Attachments, each created from a distinct Dedicated Interconnect connected to two different EADs in the same Metro
- Overlay
  - foo
  - bar

## Prerequisites

A single pre-existing project and a VPC is used in this blueprint to keep variables and complexity to a minimum.

The provided project needs a valid billing account and the Compute APIs enabled.

The two Dedicated Interconnect connections should already exist, either in the same project or in any other project belonging to the same GCP Organization.

<!-- BEGIN TFDOC -->

<!-- END TFDOC -->

## Test

```hcl
TODO
```
