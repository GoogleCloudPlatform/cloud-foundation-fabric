# Google Network Peering

This module allows creation of a [VPC Network Peering](https://cloud.google.com/vpc/docs/vpc-peering) between two networks.

The resources created/managed by this module are:

- one network peering from `local network` to `peer network`
- one network peering from `peer network` to `local network`

## Usage

Basic usage of this module is as follows:

```hcl
module "peering" {
  source = "modules/net-vpc-peering"

  prefix        = "name-prefix"
  local_network = "<FIRST NETWORK SELF LINK>"
  peer_network  = "<SECOND NETWORK SELF LINK>"
}
```

If you need to create more than one peering for the same VPC Network `(A -> B, A -> C)` you have to use output from the first module as a dependency for the second one to keep order of peering creation (It is not currently possible to create more than one peering connection for a VPC Network at the same time).

```hcl
module "peering-a-b" {
  source = "modules/net-vpc-peering"

  prefix        = "name-prefix"
  local_network = "<A NETWORK SELF LINK>"
  peer_network  = "<B NETWORK SELF LINK>"
}

module "peering-a-c" {
  source = "modules/net-vpc-peering"

  prefix        = "name-prefix"
  local_network = "<A NETWORK SELF LINK>"
  peer_network  = "<C NETWORK SELF LINK>"

  module_depends_on = [module.peering-a-b.complete]
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| local_network | Resource link of the network to add a peering to. | <code title="">string</code> | ✓ |  |
| peer_network | Resource link of the peer network. | <code title="">string</code> | ✓ |  |
| *export_local_custom_routes* | Export custom routes to peer network from local network. | <code title="">bool</code> |  | <code title="">false</code> |
| *export_peer_custom_routes* | Export custom routes to local network from peer network. | <code title="">bool</code> |  | <code title="">false</code> |
| *module_depends_on* | List of modules or resources this module depends on. | <code title="">list</code> |  | <code title="">[]</code> |
| *prefix* | Name prefix for the network peerings | <code title="">string</code> |  | <code title="">network-peering</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| complete | Output to be used as a module dependency. |  |
| local_network_peering | Network peering resource. |  |
| peer_network_peering | Peer network peering resource. |  |
<!-- END TFDOC -->