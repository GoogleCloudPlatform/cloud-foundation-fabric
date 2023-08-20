# Refactor IAM interface

**authors:** [Ludo](https://github.com/ludoo), [Julio](https://github.com/juliocc)
**last modified:** August 17, 2023

## Status

Discussed.

## Context

Our modules IAM interface has evolved organically to progressively support more functionality, resulting in a large variable surface, lack of support for some key features like conditions, and some fragility for specific use cases.

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

A few data blueprints that leverage `iam_additive` will need to be refactored to use the new variable, using one of the following patterns:

```hcl
locals {
  network_sa_roles = [
    "roles/compute.orgFirewallPolicyAdmin",
    "roles/compute.xpnAdmin"
  ]
}

module "organization" {
  source          = "../../../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  iam_bindings_additive = merge(
    # IAM bindings via locals pattern
    {
      for r in local.network_sa_roles : "network_sa-${r}" : {
        member = module.branch-network-sa.iam_email
        role   = r
      }
    },
    # IAM bindings via explicit reference pattern
    {
      security_sa = {
        member = module.branch-security-sa.iam_email
        role   = "roles/accesscontextmanager.policyAdmin"
      }
    }
  )
}
```
