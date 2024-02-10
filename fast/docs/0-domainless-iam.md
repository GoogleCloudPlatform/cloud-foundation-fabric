# Support for domain-less organizations

**authors:** [Ludo](https://github.com/ludoo) \
**date:** Feb 11, 2024

## Status

Under review

## Context

The current FAST design assumes that operational groups come from the same Cloud Identity instance connected to the GCP organization.

While this approach has worked well in the past, there are already designs that cannot be easily mapped (for example groups coming from a separate CI), and the situation will only get worse once domain-less organizations start to be in wider use.

Removing the assumption that FAST logical principals (e.g. `gcp-organization-admins`) always map directly to groups is not entirely trivial, since FAST uses data from the `groups` variable in different places:

- to define authoritative IAM bindings via the module-level `group_iam` interface
- to set essential contacts at the folder and project level

This proposal removes the dependency from groups, and tries at the same time to preserve code readability in IAM bindings by changing the `group_iam` module interface so that it can be used for a wider set of principals.

## Proposal

### FAST variable type change and optional interpolation

The current `groups` variable was meant as a simple mapping between logical names for groups used internally by FAST, and actual group names. The organization domain was then interpolated if no domain was specified, and the `group:` prefix added for IAM bindings.

The new proposed variable maintains the legacy behaviour, but slightly changes it so that no interpolation happens if the variable attributes have a principal prefix. The variable type is also updated to use `optional`, so that individual group principals can be specified without having to override the whole block.

Finally, the name changes to `group_principals` to indicate that any type of principal can be used, not only `group:` or `user:` but more importantly `princpal:` and `principalSet:` to support domain-less organizations.

```hcl
variable "group_principals" {
  type = object({
    gcp-billing-admins      = optional(string, "gcp-billing-admins")
    gcp-devops              = optional(string, "gcp-devops")
    gcp-network-admins      = optional(string, "gcp-network-admins")
    gcp-organization-admins = optional(string, "gcp-organization-admins")
    gcp-security-admins     = optional(string, "gcp-security-admins")
    gcp-support             = optional(string, "gcp-support")
  })
  nullable = false
  default = {}
}
```

Passing in different principals is intuitive:

```hcl
group_principals = {
  gcp-devops = "principalSet://iam.googleapis.com/locations/global/workforcePools/mypool/group/abc123"
  gcp-organization-admins = "group:gcp-organization-admins@other.domain"
}
```

Internally, interpolation is fairly straightforward:

```hcl
locals {
  groups = {
    for k, v in var.group_principals : k => (
      can(regex("^[a-zA-Z]+:", v))
      ? v
      : "group:${v}@${var.organization.domain}"
    )
  }
}
```

### FAST IAM additive bindings and module interface change

FAST leverages the `group_iam` module-level interface to improve code readability for authoritative bindings, which is a primary goal of the framework. Introducing support for any principal type would prevent us from using this interface, with a non-trivial impact on the overall readability of IAM roles in FAST.

This is an example use in the IaC project:

```hcl
  # human (groups) IAM bindings
  group_iam = {
    (local.groups.gcp-devops) = [
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountTokenCreator",
    ]
    (local.groups.gcp-organization-admins) = [
      "roles/iam.serviceAccountTokenCreator",
      "roles/iam.workloadIdentityPoolAdmin"
    ]
  }
```

This proposal addresses the issue by changing the module-level interface to support different principal types. The original goal for `group_iam` -- to allow for better readability -- is preserved at the cost of a slight increase in verbosity, from having to specify the principal type for each principal

The trade-off in verbosity is accetable since it makes the new interface a lot more flexible, introducing support for types like `principal:` and `principalSet:` which are becoming more and more common.

FAST code would be unchanged, as the `groups` local already contains the principal prefix for each "group", either interpolated or passed in by the user.

This module-level variable definition would change only its name and description:

```hcl
variable "iam_principals" {
  description = "Authoritative IAM binding keyed by principal, in {PRINCIPAL => [ROLES]} format. Principal need to be statically defined. Internally merged with the `iam` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}
```

Use would also be almost identical to the current `group_iam` interface:

```hcl
# current interface
  group_iam = {
    "app1-admins@example.org" = [
      "roles/owner",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.projectCreator"
    ]
  }
# proposed interface
  iam_principals = {
    "group:app1-admins@example.org" = [
      "roles/owner",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.projectCreator"
    ]
    ""principalSet://iam.googleapis.com/locations/global/workforcePools/mypool/group/abc123": = [
      "roles/owner",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.projectCreator"
    ]
  }
```

### FAST essential contacts

Having `group_principals` support different type of principals will make it impossible to use the same variable to set essential contacts, as the principal might not be a group.

This will require introduction of a new `essential_contacts` top-level variable keyed by folder/project (the individual contexts on which to set contacts), with the added benefit of being able to specify different and potentially multiple contacts compared to now.

## Decision

Pending

## Consequences

Pending
