# Support for domain-less organizations

**authors:** [Ludo](https://github.com/ludoo) \
**reviewed by:** [Julio](https://github.com/juliocc) \
**date:** Feb 12, 2024

## Status

Implemented in [#2064](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/2064).

## Context

The current FAST design assumes that operational groups come from the same Cloud Identity instance connected to the GCP organization.

While this approach has worked well in the past, there are already designs that cannot be easily mapped (for example groups coming from a separate CI), and the situation will only get worse once domain-less organizations start to be in wider use.

Removing the assumption that FAST logical principals (e.g. `gcp-organization-admins`) always map directly to groups is not entirely trivial, since FAST uses data from the `groups` variable in different places:

- to define authoritative IAM bindings via the module-level `group_iam` interface
- to define additive IAM bindings via the module-level `iam_bindings_additive` interface
- to set essential contacts at the folder and project level

This proposal removes the dependency from groups by allowing to pass in to FAST any principal type, while still trying to preserve the current default behaviour and code readability in IAM bindings.

## Proposal

### FAST variable type change and optional interpolation

The current `groups` variable was meant as a simple mapping between logical profile names used internally by FAST, and actual group names. The default case was furthermore made easier by interpolating the organization domain when no domain was specified, and adding the `group:` principal prefix for IAM bindings.

The new proposed variable maintains the legacy behaviour, but slightly changes it so that no interpolation happens if the variable attributes have a principal prefix. The variable type is also updated to use `optional`, so that individual logical profile / principal mappings can be specified without having to override the whole block.

```hcl
variable "groups" {
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
groups = {
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

FAST leverages the `group_iam` module-level interface to improve code readability for authoritative bindings, which is a primary goal of the framework. Introducing support for any principal type prevents us from using this interface, with a non-trivial impact on the overall readability of IAM roles in FAST.

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

This proposal addresses the issue by changing the module-level interface to support different principal types. The original goal for `group_iam` -- to allow for better readability -- is preserved at the cost of the slight increase in verbosity due to having to specify the principal type.

The trade-off in verbosity seems acceptable as it makes the new interface more flexible, and allows using the interface for `principal:` and `principalSet:` types, which are becoming more and more important to support.

FAST code remains unchanged, as the `groups` local already contains a prefix for each principal, either interpolated or passed in by the user.

The module-level variable definition changes only its name and description:

```hcl
variable "iam_by_principals" {
  description = "Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}
```

Actual use is basically unchanged from the current `group_iam` interface:

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
  iam_by_principals = {
    "group:app1-admins@example.org" = [
      "roles/owner",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.projectCreator"
    ]
    "principalSet://iam.googleapis.com/locations/global/workforcePools/mypool/group/abc123": = [
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

Rolled out.
