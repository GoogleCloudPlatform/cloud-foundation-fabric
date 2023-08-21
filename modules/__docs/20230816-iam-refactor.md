# Refactor IAM interface

**authors:** [Ludo](https://github.com/ludoo), [Julio](https://github.com/juliocc)
**last modified:** August 17, 2023

## Status

Implemented in [#1595](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/1595).

## Context

The IAM interface in our modules has evolved organically to progressively support more functionality, resulting in a large variable surface, lack of support for some key features like conditions, and some fragility for specific use cases.

We currently support, with uneven coverage across modules:

- authoritative `iam` in `ROLE => [PRINCIPALS]` format
- authoritative `group_iam` in `GROUP => [ROLES]` format
- legacy additive `iam_additive` in `ROLE => [PRINCIPALS]` format which breaks for dynamic values
- legacy additive `iam_additive_members` in `PRINCIPAL => [ROLES]` format which breaks for dynamic values
- new additive `iam_members` in `KEY => {role: ROLE, member: MEMBER, condition: CONDITION}` format which works with dynamic values and supports conditions
- policy authoritative `iam_policy`
- specific support for third party resource bindings in the service account module

## Proposal

### Authoritative bindings

These tend to work well in practice, and the current `iam` and `group_iam` variables are simple to use with good coverage across modules.

The only small use case that they do not cover is IAM conditions, which are easy to implement but would render the interface more verbose for the majority of cases where conditions are not needed.

The **proposal** for authoritative bindings is to

- leave the current interface in place (`iam` and `group_iam`)
- expand coverage so that all modules who have iam resources expose both
- add a new `iam_bindings` variable to support authoritative IAM with conditions

The new `iam_bindings` variable will look like this:

```hcl
variable "iam_bindings" {
  description = "Authoritative IAM bindings with support for conditions, in {ROLE => { members = [], condition = {}}} format."
  type = map(object({
    members   = list(string)
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
}
```

This variable will not be internally merged in modules with `iam` or `group_iam`.

### Additive bindings

Additive bindings have evolved to mimick authoritative ones, but the result is an interface which is bloated (no one uses `iam_additive_members`), and hard to understand and use without triggering dynamic errors. Coverage is also spotty and uneven across modules, and the interface needs to support aliasing of project service accounts in the project module to work around dynamic errors.

The `iam_additive` variable is used in a special patterns in data blueprints, to allow code to not mess up existing IAM bindings in an external project on destroy. This pattern only works in a limited set of cases, where principals are passed in via static variables or refer to "magic" static outputs in our modules. This is a simple example of the pattern:

```hcl
locals {
  iam = {
    "roles/viewer" = [
      module.sa.iam_email,
      var.group.admins
    ]
  }
}
module "project" {
  iam          = (
    var.project_create == null ? {} : local.iam
  )
  iam_additive = (
    var.project_create != null ? {} : local.iam
  )
}
```

The **proposal** for authoritative bindings is to

- remove `iam_additive` and `iam_additive_members` from the interface
- add a new `iam_bindings_additive` variable

Once new variables are in place, migrate existing blueprints to using `iam_bindings_additive` using one of the two available patterns:

- the flat verbose one where bindings are declared in the module call
- the more complex one that moves roles out to `locals` and uses them in `for` loops

The new variable will closely follow the type of the authoritative `iam_bindings` variable described above:

```hcl
variable "iam_bindings_additive" {
  description = "Additive IAM bindings with support for conditions, in {KEY => { role = ROLE, members = [], condition = {}}} format."
  type = map(object({
    member    = string
    role      = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
}
```

### IAM policy

The **proposal** is to remove the IAM policy variable and resources, as its coverage is very uneven and we never used it in practice. This will also simplify data access log management, which is currently split between its own variable/resource and the IAM policy ones.

## Decision

The proposal above summarizes the state of discussions between the authors, and implementation will be tested.

## Consequences

### FAST

IAM implementation in the bootstrap stage and matching multitenant bootstrap has radically changed, with the addition of a new [`organization-iam.tf`](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master/fast/stages/0-bootstrap/organization-iam.tf) file which contains IAM binding definitions in an abstracted format, that is then converted to the specific formats required by the `iam`, `iam_bindings` and `iam_bindings_additive` variables.

This brings several advantages over the previous handling of IAM:

- authoritative and additive bindings are now grouped by principal in an easy to read and change format that serves as its own documentation
- support for IAM conditions has removed the need for standalone resources and made the intent behind those more explicit
- some subtle bugs on the intersection of user-specified bindings and internally-specified ones have been addressed

### Blueprints

A few data blueprints that leverage `iam_additive` have been refactored to use the new variable. This is most notable in data blueprints, where extra files have been added to the more complex examples like data foundations, to abstract IAM bindings in a way similar to what is described above for FAST.
