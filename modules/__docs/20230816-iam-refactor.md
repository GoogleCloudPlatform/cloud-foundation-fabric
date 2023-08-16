# Refactor IAM interface

**authors:** [Ludo](https://github.com/ludoo)
**date:** August 16, 2023

## Status

Proposed.

## Context

Our modules IAM interface has evolved organically to progressively support more functionality, resulting in a large variable surface, lack of support for some key features like conditions, and some fragility for specific use cases.

We currently support, with uneven coverage across modules:

- authoritative `iam` in `ROLE => [PRINCIPALS]` format
- authoritative `group_iam` in `GROUP => [ROLES]` format
- legacy additive `iam_additive` in `ROLE => [PRINCIPALS]` format which breaks for dynamic values
- legacy additive `iam_additive_members` in `PRINCIPAL => [ROLES]` format which breaks for dynamic values
- new additive `iam_members` in `KEY => {role: ROLE, member: MEMBER, condition: CONDITION}` format which works with dynamic values and supports conditions
- policy authoritative `iam_policy`
- specific support for thrid party resource bindings in the service account module

## Proposal

### Authoritative bindings

These tend to work well in practice, and the current `iam` and `group_iam` variables are simple to use and represent well the conceptual approach of separating human (group) and machine (service account) role assignment. Coverage is pretty good across modules.

Their main problem is lack of support for conditions, which are easy to implement but would render the interface more verbose for the majority of cases where conditions are not needed.

The **proposal** for authoritative bindings is to

- leave the current interface in place
- delegate support of conditions to a different variable (see below)
- expand coverage so that all modules who have iam resources expose both

### Additive bindings

Additive bindings have evolved to mimick authoritative ones, but the result is an interface which is bloated (no one uses `iam_additive_members`), and hard to understand and use without triggering dynamic errors. Coverage is also spotty and uneven across modules.

A new `iam_members` variable has been recently introduced, which addresses the legacy variables shortcomings by making loop keys static, and adds support for conditions. It comes at the cost of a slightly more verbose interface, but allows error-free and explicit code and the use of `for` loops for both roles and members if needed.

This is an example of `iam_members` supporting conditions:

```hcl
module "project" {
  source = "./fabric/modules/project"
  name   = "project-example"
  iam_members = {
    one-owner = {
      # both roles and members can safely use for loops
      member = "user:one@example.org"
      role   = "roles/owner"
    }
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

The **proposal** for additive bindings is to nuke the legacy interface out of existence, and only leave `iam_members` in place. This will have no appreciable impact on code readability, and remove a lot of potential sources of error.

One example of the legacy interface:

```hcl
module "organization" {
  source          = "../../../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  iam_additive = {
    "roles/accesscontextmanager.policyAdmin" = [
      module.branch-security-sa.iam_email
    ]
    "roles/compute.orgFirewallPolicyAdmin" = [
      module.branch-network-sa.iam_email
    ]
    "roles/compute.xpnAdmin" = [
      module.branch-network-sa.iam_email
    ]
  }
}
```

This is how the above example can be refactored with the new interface, showing both approaches to declaring bindings:

- the simple one where bindings are flat and declared in the module call, which might be preferred for simple usage
- and the more complex one that moves roles out to `locals` and uses them in `for` loops, which might be preferred for complex code like FAST where local variables offer more immediate readability of important data

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
    {
      for r in local.network_sa_roles : "network_sa-${r}" : {
        member = module.branch-network-sa.iam_email
        role   = r
      }
    },
    {
      security_sa = {
        member = module.branch-security-sa.iam_email
        role   = "roles/accesscontextmanager.policyAdmin"
      }
    }
  )
}
```

### Conditions for authoritative bindings

Directly supporting conditions in authoritative variables would greatly complicate their type to support the tiny minority of use cases where conditions are needed.

The type would need change from this:

```hcl
variable "iam" {
  type        = map(list(string))
  default     = {}
  nullable    = false
}
```

To something like this, which would force specifiyng an extra `{roles = []}` every time:

```hcl
variable "iam" {
  type        = map(object({
    roles     = list(string)
    condition = optional(object({
      expression = string
      title      = string
    }))
  }))
  default     = {}
  nullable    = false
}
```

The proposal is to support conditions in authoritative IAM via the new `iam_members` variable, by adding an extra optional `authoritative` attribute to its type:

```hcl
variable "iam_members" {
  type = map(object({
    member        = string
    role          = string
    authoritative = optional(bool, false)
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}
```

This would

- leave the current authoritative interface in place as it works well and covers the vast majority of use cases
- allow new functionality which was not available previously, with no impact on existing code
- extend the usage of the new `iam_members` variable to cover both authoritative and additive roles

The only drawback of this approach is potential conflict if the same role is used in both `iam`/`group_iam` and `iam_members`, but this seems acceptable and even desirable, as it would highlight a design issue via a permadiff.

## Decision

No decision yet, this will need to be discussed.

## Consequences

TBD
