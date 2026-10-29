# Binding Policies and Tags to Resource Manager Objects

**authors:** [Ludo](https://github.com/ludoo) \
**date:** Oct 29, 2026

## Status

Proposed. Triggered by [#4286](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/4286), which adds hierarchical Cloud Armor policies to `modules/net-cloud-armor` and whose review removed the attachment interface from the policy module pending this decision.

## Context

Several GCP features are expressed as a separate binding object that references two resources: a thing (a tag value, a firewall policy, a Cloud Armor security policy) and a target (organization, folder, project, or VPC). Terraform can manage that binding from the module of either end, and Fabric currently does so in different ways depending on the feature:

| Feature | Binding resource | Target-side interface | Policy-side interface |
|---|---|---|---|
| Tags on resource manager objects | `google_tags_tag_binding` | `tag_bindings` in `organization`, `folder`, `project` | none |
| Tags on other resources | `google_tags_tag_binding` | `tag_bindings` in `gcs`, `kms`, `compute-vm`, etc. | none |
| Hierarchical firewall policy | `google_compute_firewall_policy_association` | `firewall_policy` (single) in `organization`, `folder` | `attachments` (map) in `net-firewall-policy` |
| Network firewall policy | `google_compute_(region_)network_firewall_policy_association` | none in `net-vpc` | `attachments` (map) in `net-firewall-policy` |
| Hierarchical Cloud Armor policy | `google_compute_organization_security_policy_association` | none | removed from #4286 during review |

The module design principle that all aspects of a core resource live in its module points at the target side: the folder module owns what applies to the folder. That reading holds well for tags, where the value is defined centrally but whether a given folder wears it is a decision of whoever owns that folder, because everything that hangs off the binding (IAM conditions, organization policy conditions) is about the folder.

It does not describe how hierarchical policies are actually used. There the decision to attach is taken by the team that owns the policies, not by the owners of the targets, and that team typically manages a set of policies and their attachments across a slice of the hierarchy from a different place than the one where the hierarchy is defined, which is itself often spread across multiple stages. In FAST, networking and security stages own the policies while resman, the project factory, and team stages own the folders and projects. Forcing the attachment through the target modules means composing `folder` or `project` modules with creation disabled next to every policy, which works but makes the policy code harder to read and spreads one decision over two interfaces.

Two properties make the policy side the natural home for these cases. The first is centralization: the policy owner is the one party who knows the complete attachment set, and that set is the thing being reviewed. The second is exclusions: the Cloud Armor association carries exclusion lists for folders and projects underneath the attached target, which only make sense from the policy's point of view and cannot be expressed by a target module without turning it into a policy module. Hierarchical Cloud Armor also enrols every covered project in Cloud Armor Enterprise billing, so attachment and exclusions are one decision that should be readable in one place.

## Decision

The binding lives with the party that decides it, which gives two interfaces with different standing:

- The target-side interface is canonical and mandatory. Every module whose resource can be a binding target exposes it (`tag_bindings` for tags, an association variable for firewall and Cloud Armor policies), regardless of whether a policy-side interface also exists. It exists only where the API allows the target, so `project` carries `cloud_armor_policy` and not `firewall_policy`; the asymmetry follows the API.
- A policy-side interface is accepted as a second interface in the specific cases where centralized management is a definite usage pattern, signalled by the policy owner managing attachments across a hierarchy they do not own and/or by binding flags such as exclusions that are only meaningful from the policy's point of view. Hierarchical firewall policies and hierarchical Cloud Armor policies meet this test; tags do not.
- A given binding is managed from one side only. Both interfaces being available does not mean both are used for the same association.

Policy-side interfaces use a map keyed by a descriptive name, consistent with `net-firewall-policy`'s `attachments`, with values carrying the target and any binding-level flags. Target-side interfaces follow the cardinality the API allows for the target: a map where a target can carry several bindings (tags), a single object where it can carry one (hierarchical policies, which allow one direct association per node).

A PR that introduces a bindable feature implements the target-side interface in the same PR. The policy-side interface, where it applies, is added at the same time so that the feature ships with the usage pattern it is meant for.

### Hierarchical Cloud Armor policies

The Cloud Armor association API accepts organizations, folders and projects as targets, allows one direct association per node, and carries exclusion lists: `excluded_folders` only on organization-level associations, `excluded_projects` on organization- and folder-level ones, neither on project-level ones.

Policy side, in `net-cloud-armor`, keyed by association name suffix, with targets resolved through `context.folder_ids` and exclusions through `context.project_numbers`:

```hcl
variable "attachments" {
  type = map(object({
    id                = string
    excluded_folders  = optional(list(string), [])
    excluded_projects = optional(list(string), [])
  }))
  default  = {}
  nullable = false
}
```

Target side, in `organization`, `folder` and `project`, as a singleton mirroring the existing `firewall_policy`, carrying the exclusions since they are attributes of the association and a target owner carving out its own children is a legitimate use. The name is `cloud_armor_policy` rather than the API's `security_policy`, which next to `firewall_policy` would read as a sibling of the wrong thing. The module validates the exclusions against its own level, and `project` passes its project number as the target.

```hcl
variable "cloud_armor_policy" {
  type = object({
    name              = optional(string)
    policy            = string
    excluded_folders  = optional(list(string), [])
    excluded_projects = optional(list(string), [])
  })
  default = null
}
```

Both are requested on #4286.

### Network firewall policies

A VPC carries one global network firewall policy and one regional policy per region, through two different provider resources. The target-side interface in `net-vpc` is a single map keyed by region, with `global` accepted as a special key and routed internally to the global association resource. The association name is exposed since the API requires it and it has to be unique per network; when omitted it is derived from the key.

```hcl
variable "firewall_policy_associations" {
  type = map(object({
    name   = optional(string)
    policy = string
  }))
  default  = {}
  nullable = false
}
```

This is implemented in the same PR as this document.

## Consequences

- `modules/net-vpc` gains `firewall_policy_associations`, so the target side is complete for firewall policies.
- `modules/net-cloud-armor` gets its attachment interface back in #4286 with a validation on exclusions by target level, and `organization`, `folder`, and `project` gain `cloud_armor_policy` in the same PR.
- The single-valued `firewall_policy` in `organization` and `folder` stays as is, since it encodes the one-association-per-node constraint of the API.
- FAST stages keep attaching hierarchical policies from the networking and security stages through the policy-side interface.

