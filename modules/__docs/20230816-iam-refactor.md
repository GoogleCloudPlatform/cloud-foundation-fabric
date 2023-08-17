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

- leave the current interface in place
- expand coverage so that all modules who have iam resources expose both
- repurpose the recently added `iam_members` variable to support authoritative IAM with conditions, and move its current functionality to a new variable described later

The repurposed `iam_members` variable will look like this:

```hcl
variable "iam_members" {
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

The `iam_additive` variable has a special use case for data blueprints, where it is used when optional project creation is not set so as not to alter existing IAM bindings in the project on destroy. The assumption is that this type of usage is potentially unsafe, and tests are not catching errors as we never test blueprints with existint projects. This is a simple example of the pattern:

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

A new `iam_members` variable has been recently introduced, which addresses the legacy variables shortcomings by making loop keys static, and adds support for conditions. It comes at the cost of a slightly more verbose interface, but allows error-free and explicit code and the use of `for` loops for both roles and members if needed.

This is an example of `iam_members` supporting conditions:

```hcl
module "project" {
  source = "./fabric/modules/project"
  name   = "project-example"
  iam_members = {
    one-delegated-grant = {
      member = "user:one@example.org"
      role   = "roles/resourcemanager.projectIamAdmin"
      condition = {
        title      = "delegated_network_user_one"
        expression = <<-END
          api.getAttribute(
            'iam.googleapis.com/modifiedGrantsByRole', []
          ).hasOnly([
            'roles/compute.networkAdmin'
          ])
        END
      }
    }
  }
}
# tftest skip
```

The **proposal** for authoritative bindings is to

- assess usage of `iam_additive` in data blueprints to confirm the implementation is unsafe
- once the assumption has been confirmed, remove `iam_additive` and `iam_additive_members` from the interface
- rename the recently added `iam_members` variable to `iam_members_additive` keeping its type

Once new variables are in place, migrate existing blueprints to using `iam_members_additive` using one of the two available patterns:

- the flat verbose one where bindings are declared in the module call
- the more complex one that moves roles out to `locals` and uses them in `for` loops

Some refactoring will also be needed for principals passed in via variables. This a simple example showing both patterns:

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
  iam_members = merge(
    # IAM bindings via locals
    {
      for r in local.network_sa_roles : "network_sa-${r}" : {
        member = module.branch-network-sa.iam_email
        role   = r
      }
    },
    # IAM bindings via explicit reference
    {
      security_sa = {
        member = module.branch-security-sa.iam_email
        role   = "roles/accesscontextmanager.policyAdmin"
      }
    }
  )
}
```

### IAM policy

The **proposal** is to remove the IAM policy variable and resources, as its coverage is very uneven and we never used it in practice. This will also simplify data access log management, which is currently split between its own variable/resource and the IAM policy ones.

## Decision

The proposal above summarizes the state of discussions between the authors, and implementation will be tested.

## Consequences

TBD
