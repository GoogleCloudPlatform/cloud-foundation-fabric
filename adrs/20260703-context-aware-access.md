# Support for Context-Aware Access (`context_aware_access_bindings`) in `modules/organization`

**authors:** [ludomagno](https://github.com/ludomagno)  
**date:** Jul 3, 2026  

## Status

Proposed

## Context

Google Cloud Context-Aware Access ([securing GCP Console and APIs](https://cloud.google.com/access-context-manager/docs/securing-console-and-apis)) enforces identity- and context-based access controls for Google Cloud Console and CLI/APIs by binding Google Workspace / Cloud Identity user groups to Access Context Manager access levels using `google_access_context_manager_gcp_user_access_binding` resources.

Access levels specify context conditions (e.g., corporate IP subnets, device posture, geographic regions) and can be referenced via symbolic context keys (`$access_levels:<key>`) or literal access level IDs (`accessPolicies/<id>/accessLevels/<name>`).

## Decision

### 1. Module Scope & Ownership Rationale
The `google_access_context_manager_gcp_user_access_binding` resources will be implemented in `modules/organization`.

*Rationale:* This follows the universal Fabric pattern where support for a feature or policy is added to the module that owns the resource to which the policy is applied. Since GCP User Access Bindings apply at the Organization resource boundary, `modules/organization` is the correct module owner.

### 2. Context Resolution Pattern
The standard Fabric context replacement pattern is applied so that `access_levels` attributes in bindings can be specified either:
- As explicit, fully-qualified Access Level IDs (e.g., `accessPolicies/12345/accessLevels/corp_device`), or
- Via `$access_levels:<key>` context replacements.

The `$access_levels:` context namespace in `modules/organization` is populated by merging:
- Static context passed in via `var.context.access_levels`
- Internal context populated via `var.access_levels`
- Internal context populated via an `access_levels` factory (`factories_config.access_levels`)

### 3. Feature and Variable Naming
To strictly align with Fabric naming rules and avoid creating new names for existing components:
- Binding variable: `context_aware_access_bindings`
- Access levels variable: `access_levels` (matching the exact name used in `modules/vpc-sc`)
- Factory configuration key: `factories_config.access_levels` (for access levels only; no factory for bindings)

### 4. Access Level Factory Schema
The `access_levels` factory schema in `modules/organization` will be identical to the one implemented in `modules/vpc-sc` (`modules/vpc-sc/schemas/access-level.schema.json`).

No additional schema fields are required. The JSON schema will be copied to `modules/organization/schemas/access-level.schema.json` and tracked in `tools/duplicate-diff.py`.

## Interface Specifications

### Variable Interface (`variables.tf`)

```hcl
variable "access_levels" {
  description = "Access levels map for internal context resolution (key => access_level_id)."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "context_aware_access_bindings" {
  description = "GCP User Access Bindings for securing Console and APIs."
  type = map(object({
    group_key     = string
    access_levels = list(string)
    scoped_access_settings = optional(list(object({
      active_settings = optional(object({
        access_levels = optional(list(string))
      }))
      dry_run_settings = optional(object({
        access_levels = optional(list(string))
      }))
    })), [])
  }))
  default  = {}
  nullable = false
}
```

## FAST Support (`fast/stages/0-org-setup`)

To support Context-Aware Access in Fabric FAST environments:

1. **Defaults Context Support**: Add support for the new `$access_levels:` context namespace to the `0-org-setup` defaults dataset and variables.
2. **Access Level Factory**: Add support for the `access_levels` factory in `0-org-setup` to enable defining org-level access levels alongside org policy and IAM factories.
3. **Schema Copy & Tracking**: Copy `access-level.schema.json` to `fast/stages/0-org-setup/schemas/access-level.schema.json` and register the triple (`modules/vpc-sc`, `modules/organization`, `fast/stages/0-org-setup`) in `tools/duplicate-diff.py`.

## Consequences

- Enforces Fabric resource ownership principles by placing org-level bindings in `modules/organization`.
- Allows callers to use explicit access level IDs or `$access_levels:` context replacements.
- Integrates cleanly into FAST Stage 0 with full schema validation and duplicate checking via `tools/duplicate-diff.py`.
