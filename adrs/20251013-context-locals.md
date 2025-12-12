# Using single local `ctx` for context interpolations

**authors:** [Wiktor Niesiobedzki](https://github.com/wiktorn)
**date:** Oct 13, 2025

## Status

Draft

## Context

Terraform build dependency graph using variables and locals as nodes. If those are complex structures, such as lists, maps or objects, they can contain references to multiple resources. Because of that, any access to a complex variable creates an implicit dependency on all resources referenced within this variable. For example:

```hcl
locals {
  ctx = {
    folder  = google_folder.this.id
    project = google_project.this.id
  }
}

resource "terraform_data" "this" {
  input = local.ctx.folder
}
```

Creates implicit dependencies like this:
* `terraform_data.this` depends on `local.ctx`
* `local.ctx` depends on `google_folder.this`
* `local.ctx` depends on `google_project.this`

This may result in unnecessary dependencies and eventually, in dependency cycles.


## Decision:
Use single `local.ctx` to store context and single `context` variable to pass context between modules.


## Consequences

This may result in dependency cycles when calling the module, for example when creating custom roles that are needed for IAM grants in the same organization / project. This can be easily work around, by separating the module calls into two:
* one that does primary setup
* second that does the IAM, and uses the resources created in the first call

In some specific cases, it might be necessary to have a separate context local for specific type of resource to avoid dependency cycles.

## Reasoning

The primary reason is to make module calls concise and easy to use. As of now, the dependency cycles are occurring rarely and are easily fixed by separating the module calls.

## Alternatives Considered:

### Separating `local.ctx` by type of context
Currently, `local.ctx` is build like this (example from `modules/project`):
```hcl
locals {
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
}
```

To use separate local this needs to be changed to:
```hcl
locals {
  ctx_custom_roles          = {for k, v in var.context_custom_roles : "${local.ctx_p}custom_roles:${k}" => v}
  ctx_folder_ids            = {for k, v in var.context_folder_ids : "${local.ctx_p}folder_ids:${k}" => v}
  ctx_kms_keys              = {for k, v in var.context_kms_keys : "${local.ctx_p}kms_keys:${k}" => v}
  ctx_iam_principals        = {for k, v in var.context_iam_principals : "${local.ctx_p}iam_principals:${k}" => v}
  ctx_notification_channels = {
    for k, v in var.context_notification_channels :"${local.ctx_p}notification_channels:${k}" => v
  }
  ctx_logging_bucket_names  = {
    for k, v in var.context_logging_bucket_names : "${local.ctx_p}logging_bucket_names:${k}" => v
  }
  ctx_project_ids           = {for k, v in var.context_project_ids : "${local.ctx_p}project_ids:${k}" => v}
  ctx_tag_keys              = {for k, v in var.context_tag_keys : "${local.ctx_p}tag_keys:${k}" => v}
  ctx_tag_values            = {for k, v in var.context_tag_values : "${local.ctx_p}tag_values:${k}" => v}
  ctx_vpc_sc_perimeters     = {for k, v in var.context_vpc_sc_perimeters : "${local.ctx_p}vpc_sc_perimeters:${k}" => v}
}
```

Which is way more verbose. Note, that to disentangle the dependency tree, we need also separate input variables in the module, and the callers will need to pass context separately, which increases the burden of the module user.


## Implementation:

At the time of writing this ADR, all modules and FAST stages already use single `context` variable and `local.ctx`.
