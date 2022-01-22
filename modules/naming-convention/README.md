# Naming Convention Module

This module allows defining a naming convention in a single place, and enforcing it by pre-creating resource names based on a set of tokens (environment, team name, etc.).

It implements a fairly common naming convention with optional prefix or suffix, but is really meant to be forked, and modified to adapt to individual use cases: just replace the `environment` and `team` variables with whatever makes sense for you, and edit the few lines in `main.tf` marked by comments.

The module also supports labels, generating sets of per-resource labels that combine the passed in tokens with optional resource-level labels.

It's completely static, using no provider resources, so its outputs are safe to use where dynamic values are not supported, like in `for_each` statements.

## Example

In its default configuration, the module supports an option prefix and suffix, and two tokens: one for the environment, and one for the team name.

```hcl
module "names-org" {
  source     = "./modules/naming-convention"
  prefix      = "myco"
  environment = "dev"
  team        = "cloud"
  resources = {
    bucket = ["tf-org", "tf-sec", "tf-log"]
    project = ["tf", "sec", "log"]
  }
  labels = {
    project = {
      tf = {scope = "global"}
    }
  }
}

module "project-tf" {
  source = "./modules/project"
  # myco-cloud-dev-tf
  name   = module.names-org.names.project.tf
  # { environment = "dev", scope = "global", team = "cloud" }
  labels = module.names-org.labels.project.tf
}
```

You can also enable resource type naming, useful with some legacy CMDB setups. When doing this, resource type names become part of the final resource names and are usually shorted (e.g. `prj` instead of `project`):

```hcl
module "names-org" {
  source     = "./modules/naming-convention"
  prefix      = "myco"
  environment = "dev"
  team        = "cloud"
  resources = {
    bkt = ["tf-org", "tf-sec", "tf-log"]
    prj = ["tf", "sec", "log"]
  }
  labels = {
    prj = {
      tf = {scope = "global"}
    }
  }
  use_resource_prefixes = true
}

module "project-tf" {
  source = "./modules/project"
  # prj-myco-cloud-dev-tf
  name   = module.names-org.names.prj.tf
}
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [environment](variables.tf#L17) | Environment abbreviation used in names and labels. | <code>string</code> | ✓ |  |
| [resources](variables.tf#L34) | Short resource names by type. | <code>map&#40;list&#40;string&#41;&#41;</code> | ✓ |  |
| [team](variables.tf#L51) | Team name. | <code>string</code> | ✓ |  |
| [labels](variables.tf#L22) | Per-resource labels. | <code>map&#40;map&#40;map&#40;string&#41;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L28) | Optional name prefix. | <code>string</code> |  | <code>null</code> |
| [separator_override](variables.tf#L39) | Optional separator override for specific resource types. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [suffix](variables.tf#L45) | Optional name suffix. | <code>string</code> |  | <code>null</code> |
| [use_resource_prefixes](variables.tf#L56) | Prefix names with the resource type. | <code>bool</code> |  | <code>false</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [labels](outputs.tf#L17) | Per resource labels. |  |
| [names](outputs.tf#L22) | Per resource names. |  |

<!-- END TFDOC -->
