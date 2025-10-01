# Net-VPC-Factory Module

This module implements VPC network and subnet creation using a factory pattern for FAST (Google Cloud Foundation Architecture) framework. It supports production and development environments with context interpolation.

## Features

- **Environment Support**: Dedicated support for `prod` and `dev` environments
- **Context Interpolation**: Full support for `$vpc_ids:env`, `$vpc_subnet_ids:env/subnet-name`, `$project_ids:key`, and other namespace references
- **Subnet Factory**: Creates subnets from YAML configuration files with hierarchical organization
- **Cloud Router Integration**: Full BGP configuration and routing support for VPCs
- **Tag Management**: Automatic and custom tag support with context resolution

## Current Implementation Focus

This module currently focuses on **subnet creation only**. VPCs are assumed to exist and are referenced through context interpolation (`$vpc_ids:env`). The module creates subnets based on YAML configuration files in the hierarchical structure:

```
data/vpcs/environments/{env}/subnets/{subnet-name}.yaml
```

## Usage

```hcl
module "net_vpc_factory" {
  source = "../../modules/net-vpc-factory"

  # Data directory configuration
  data_dir = var.factories_config.data_dir

  # Context from previous stage (stage 1 - resman)
  context = var.context

  # Factory configuration
  factories_config = var.factories_config

  # VPC configurations (can be file-based, variable-based, or both)
  vpcs_input = {
    # Example variable-based VPC configuration
    custom-vpc = {
      project_id      = "my-project-id"
      network_name    = "custom-network"
      description     = "Custom VPC network"
      routing_mode    = "GLOBAL"
      environment     = "custom"

      cloud_routers = {
        main-router = {
          name   = "custom-vpc-router"
          region = "us-central1"
          bgp = {
            asn = 65000
            advertise_mode = "CUSTOM"
          }
        }
      }
    }
  }

  # Prefix for resource naming
  prefix = var.prefix
}
```

## Configuration Files

The module supports hierarchical configuration files following the project-factory pattern:

```
data/vpcs/
├── environments/
│   ├── prod/
│   │   └── main-vpc.yaml
│   └── dev/
│       └── main-vpc.yaml
├── shared/
│   └── common-vpc.yaml
└── legacy/
    └── old-vpc.yaml
```

**Key Features:**
- **Hierarchical Structure**: Use `**/*.yaml` pattern to support nested directories
- **Flexible Naming**: Any `.yaml` file name (not limited to `.config.yaml`)
- **Environment Detection**: Environment is derived from parent directory name
- **Exclusions**: Files starting with `_` or `.config.yaml` files are ignored

### Example Configuration

See IMPLEMENTATION.md for complete configuration examples for both prod and dev environments.

## Outputs

- `vpcs`: VPC networks context for downstream stages
- `cloud_routers`: Cloud Routers context for NAT and VPN modules
- `context`: Enhanced context with VPC network information

## Reference Patterns

- **VPC Networks**: `$vpc_ids:prod`, `$vpc_ids:dev`
- **VPC Names**: `$vpc_names:prod`, `$vpc_names:dev`
- **Cloud Routers**: `$cloud_routers:env-router-name`
- **Subnets**: `$vpc_subnet_ids:env/subnet-name`

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.4 |
| google | >= 4.65.0 |
| google-beta | >= 4.65.0 |