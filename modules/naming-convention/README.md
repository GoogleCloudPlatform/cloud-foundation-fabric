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
# tftest:modules=0:resources=0
```

This will allow you to reference names and labels when creating resources:

```hcl
module "project-tf" {
  source = "./modules/project"
  # myco-cloud-dev-tf
  name   = module.names-org.names.project.tf-org
  # { environment = "dev", scope = "global", team = "cloud" }
  labels = module.names-org.labels.project.tf
}
```

You can also enable resource type naming, useful with some legacy CMDB setups:

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
# tftest:modules=0:resources=0
```

Which will result in names prefixed by their respective resource types:

```hcl
module "project-tf" {
  source = "./modules/project"
  # prj-myco-cloud-dev-tf
  name   = module.names-org.names.prj.tf-org
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| environment | None | <code title="">string</code> | ✓ |  |
| resources | None | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> | ✓ |  |
| team | None | <code title="">string</code> | ✓ |  |
| *labels* | None | <code title="map&#40;map&#40;map&#40;string&#41;&#41;&#41;">map(map(map(string)))</code> |  | <code title="">{}</code> |
| *prefix* | None | <code title="">string</code> |  | <code title="">null</code> |
| *suffix* | None | <code title="">string</code> |  | <code title="">null</code> |
| *use_resource_prefixes* | None | <code title="">bool</code> |  | <code title="">false</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| labels | None |  |
| names | None |  |
<!-- END TFDOC -->
