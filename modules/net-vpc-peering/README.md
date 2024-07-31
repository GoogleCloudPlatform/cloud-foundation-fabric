# Google Network Peering

This module allows creation of a [VPC Network Peering](https://cloud.google.com/vpc/docs/vpc-peering) between two networks.

The resources created/managed by this module are:

- one network peering from `local network` to `peer network`
- one network peering from `peer network` to `local network`

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Basic Usage](#basic-usage)
  - [Multiple Peerings](#multiple-peerings)
  - [Route Configuration](#route-configuration)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Examples

### Basic Usage

Basic usage of this module is as follows:

```hcl
module "peering" {
  source        = "./fabric/modules/net-vpc-peering"
  prefix        = "name-prefix"
  local_network = "projects/project-1/global/networks/vpc-1"
  peer_network  = "projects/project-1/global/networks/vpc-2"
}
# tftest modules=1 resources=2
```

### Multiple Peerings

If you need to create more than one peering for the same VPC Network `(A -> B, A -> C)` you use a `depends_on` for second one to keep order of peering creation (It is not currently possible to create more than one peering connection for a VPC Network at the same time).

```hcl
module "peering-a-b" {
  source        = "./fabric/modules/net-vpc-peering"
  prefix        = "name-prefix"
  local_network = "projects/project-a/global/networks/vpc-a"
  peer_network  = "projects/project-b/global/networks/vpc-b"
}

module "peering-a-c" {
  source        = "./fabric/modules/net-vpc-peering"
  prefix        = "name-prefix"
  local_network = "projects/project-a/global/networks/vpc-a"
  peer_network  = "projects/project-c/global/networks/vpc-c"
  depends_on    = [module.peering-a-b]
}
# tftest modules=2 resources=4
```

### Route Configuration

You can control export/import of routes in both the local and peer via the `routes_config` variable. Defaults are to import and export from both sides, when the peer side only configured if the peering is managed by the module via `peer_create_peering`.

```hcl
module "peering" {
  source        = "./fabric/modules/net-vpc-peering"
  prefix        = "name-prefix"
  local_network = "projects/project-1/global/networks/vpc-1"
  peer_network  = "projects/project-1/global/networks/vpc-2"
  routes_config = {
    local = {
      import = false
    }
  }
}
# tftest modules=1 resources=2  inventory=route-config.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [local_network](variables.tf#L17) | Resource link of the network to add a peering to. | <code>string</code> | ✓ |  |
| [peer_network](variables.tf#L38) | Resource link of the peer network. | <code>string</code> | ✓ |  |
| [name](variables.tf#L22) | Optional names for the the peering resources. If not set, peering names will be generated based on the network names. | <code title="object&#40;&#123;&#10;  local &#61; optional&#40;string&#41;&#10;  peer  &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [peer_create_peering](variables.tf#L32) | Create the peering on the remote side. If false, only the peering from this network to the remote network is created. | <code>bool</code> |  | <code>true</code> |
| [prefix](variables.tf#L43) | Optional name prefix for the network peerings. | <code>string</code> |  | <code>null</code> |
| [routes_config](variables.tf#L53) | Control import/export for local and remote peer. Remote configuration is only used when creating remote peering. | <code title="object&#40;&#123;&#10;  local &#61; optional&#40;object&#40;&#123;&#10;    export        &#61; optional&#40;bool, true&#41;&#10;    import        &#61; optional&#40;bool, true&#41;&#10;    public_export &#61; optional&#40;bool&#41;&#10;    public_import &#61; optional&#40;bool&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  peer &#61; optional&#40;object&#40;&#123;&#10;    export        &#61; optional&#40;bool, true&#41;&#10;    import        &#61; optional&#40;bool, true&#41;&#10;    public_export &#61; optional&#40;bool&#41;&#10;    public_import &#61; optional&#40;bool&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [stack_type](variables.tf#L73) | IP version(s) of traffic and routes that are allowed to be imported or exported between peer networks. Possible values: IPV4_ONLY, IPV4_IPV6. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [local_network_peering](outputs.tf#L17) | Network peering resource. |  |
| [peer_network_peering](outputs.tf#L22) | Peer network peering resource. |  |
<!-- END TFDOC -->
