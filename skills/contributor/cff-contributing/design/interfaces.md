# Interface Design

This guide defines how Fabric designs caller-facing module interfaces: prototyping-to-production ergonomics, compact variable spaces, provider-surface curation, and canonical cross-module interfaces that must be reused verbatim.

## Prototyping vs Production and Usage-Driven Design

Follow John Ousterhout's principle: absorb complexity inside the module so caller configurations stay concise, legible, and self-documenting.

- **Make prototyping trivial and production complete:** A minimal call with a few required inputs should produce a sensible, working resource for rapid prototyping (for example, `modules/compute-vm` spins up a 10 GB `pd-balanced` Debian VM in four lines), while expanding the same optional objects progressively unlocks every production override. Never lock callers into opinionated defaults they cannot override.
- **Do not mirror raw provider schemas 1:1:** Design around actual usage. Combine multiple ergonomic input shapes into the same internal resource when warranted (such as `iam` and `iam_by_principals`), or group large attribute sets into logical sub-objects (`initialize_params`, `source`, `hyperdisk`).
- **Align terminology within a module family:** Prefer the provider's canonical term when sibling modules model the same concept (for example, `group` rather than generic `backend`, and `vpc_config` across the `net-lb` family — see [net-lb standardization ADR](../../../../adrs/20260615-net-lb-interface-standardization.md)).
- **Never expose invalid attributes for a GCP product subtype:** Even if a shared Terraform resource (such as `google_compute_backend_service`) accepts an argument, omit it from modules whose GCP product type rejects it (for example, failover and connection tracking on proxy/application load balancers).
- **Curate the provider surface deliberately:** Read the full **released** provider documentation before designing. At Design Sign-off, list which provider arguments you include and exclude and why — cover useful, composable arguments intentionally rather than omitting them by accident or exposing everything blindly.

```hcl
# From modules/compute-vm/variables.tf — prototyping default with full production override
variable "boot_disk" {
  description = "Boot disk properties."
  type = object({
    architecture      = optional(string)
    auto_delete       = optional(bool, true)
    force_attach      = optional(bool)
    snapshot_schedule = optional(list(string))
    initialize_params = optional(object({
      size = optional(number, 10)
      type = optional(string, "pd-balanced")
    }), {})
    source = optional(object({
      attach   = optional(string)
      disk     = optional(string)
      image    = optional(string)
      snapshot = optional(string)
    }), { image = "debian-cloud/debian-13" })
  })
  default  = {}
  nullable = false
}
```

## Compact Variable Spaces and Type Safety

- **Use `object(...)` with `optional(...)`:** Group related settings into one compact object variable instead of scattering flat scalar variables.
- **Omit explicit `optional()` defaults by default:** Prefer `optional(string)` / `optional(bool)` with no default so the provider applies its own default and modules do not drift against provider updates. Supply an explicit default only when (a) internal module logic requires a non-null value, or (b) Fabric intentionally provides an ergonomic prototyping default (such as `boot_disk` above).
- **Attributes accepting one or two values become booleans:** When a provider argument only carries a binary choice (enable/disable or two mutually exclusive modes), model it as a `bool` rather than a string enum unless GCP is actively adding more modes.
- **Use maps instead of lists for multiple items:** `map(object(...))` gives stable Terraform state keys (preventing index-shift replacements), avoids dynamic-value `for_each` errors, and lets callers specify only the attributes they want to override per key.
- **Set `nullable = false` on collection/config objects with `{}` or `[]` defaults** so internal `for` expressions never have to guard against `null`.
- **Never use `any` in variable types:** Using `any` disables plan-time type validation and breaks deterministic JSON schema generation for factories (see [sa-iam-conditions ADR](../../../../adrs/modules/20260727-sa-iam-conditions.md)). The sole established exception is `context.condition_vars` when callers pass nested template data.
- **Validate provider ENUMs at plan time:** Any variable or object field exposing a fixed provider ENUM should carry a `validation` block.

```hcl
# From modules/gcs/variables.tf
variable "storage_class" {
  description = "Bucket storage class."
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "MULTI_REGIONAL", "REGIONAL", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class must be one of STANDARD, MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE."
  }
}
```

## Canonical Cross-Module Interfaces

Whenever a module implements one of the capabilities below, reuse the exact Fabric interface verbatim — never invent a variant.

### IAM

Defined in [iam-refactor ADR](../../../../adrs/modules/20230816-iam-refactor.md). Do not implement `iam_policy`.

- **Top-level resource IAM (up to 6 standard variables):**
  - `iam`: `map(list(string))` — authoritative `{ ROLE => [MEMBERS] }`.
  - `iam_by_principals`: `map(list(string))` — authoritative `{ PRINCIPAL => [ROLES] }`, merged into `iam`.
  - `iam_by_principals_conditional`: `map(object({ roles = list(string), condition = object({ expression = string, title = string, description = optional(string) }) }))` — authoritative conditional bindings grouped by role + condition title, merged into `iam_bindings`.
  - `iam_by_principals_additive`: `map(list(string))` — additive `{ PRINCIPAL => [ROLES] }`, merged into `iam_bindings_additive`.
  - `iam_bindings`: `map(object({ members = list(string), role = string, condition = optional(object({ expression = string, title = string, description = optional(string) })) }))` — authoritative conditional bindings with arbitrary keys.
  - `iam_bindings_additive`: `map(object({ member = string, role = string, condition = optional(object({ expression = string, title = string, description = optional(string) })) }))` — additive bindings with arbitrary keys.
- **Sub-resource IAM (inside a `map(object(...))`):** Embed `iam`, `iam_bindings`, and `iam_bindings_additive` directly on the item object (see `managed_folders` in `modules/gcs/variables.tf` and the full `iam.tf` implementation templates in [iam-refactor ADR](../../../../adrs/modules/20230816-iam-refactor.md)).
- **External IAM bindings (granting a module's identity roles on external resources):**
  - Use **per-target variables** rather than a polymorphic `target_type` field.
  - Use the **dual-variable pattern** (`iam_<target>_roles` as `map(list(string))` + `iam_<target>_bindings` with arbitrary keys and optional `condition`) when the subject is implicit and terse unconditional grants are common (as in `modules/iam-service-account` — [sa-iam-conditions ADR](../../../../adrs/modules/20260727-sa-iam-conditions.md)).
  - Use a **single `_bindings` variable** when the subject is explicit per entry and grants are rare (as in `service_agents_project_bindings` / `service_agents_folder_bindings` in `modules/project` — [service-agent-external-iam ADR](../../../../adrs/modules/20260909-service-agent-external-iam.md)).

### Context Interpolation

Defined in [context-locals ADR](../../../../adrs/20251013-context-locals.md) and [templatestring-vars-convention ADR](../../../../adrs/20260424-templatestring-vars-convention.md).

- Expose a single `variable "context"` (`default = {}`, `nullable = false`) containing only the lookup maps relevant to the module (`project_ids`, `locations`, `networks`, `subnets`, `kms_keys`, `iam_principals`, `custom_roles`, `addresses`, etc.). Do not add `context` blindly when symbolic interpolation brings no value.
- Any key intended as the variables map passed to `templatestring()` MUST end with `_vars` (for example, `condition_vars`, `tag_vars`) so `local.ctx` excludes it automatically via `if !endswith(k, "_vars")`. See [conventions/hcl.md](../conventions/hcl.md#context-interpolation-implementation) for the exact `local.ctx` and lookup patterns.

```hcl
variable "context" {
  description = "Context-specific interpolations."
  type = object({
    condition_vars = optional(map(map(string)), {})
    custom_roles   = optional(map(string), {})
    iam_principals = optional(map(string), {})
    kms_keys       = optional(map(string), {})
    locations      = optional(map(string), {})
    project_ids    = optional(map(string), {})
  })
  default  = {}
  nullable = false
}
```

### Secret Values

Defined in [write-only-secrets ADR](../../../../adrs/modules/20261029-write-only-secrets.md). Applies to every new interface carrying a secret (`data`, `password`, `client_secret`, etc.).

- Never overload a string with a boolean (`is_file`) and never mirror raw provider triples (`x` / `x_wo` / `x_wo_version`).
- Keep module-specific flags (such as `is_base64`) as sibling attributes outside the secret object so the object shape stays identical everywhere.
- Validate that at most one of `value` and `path` is set; allow both `null` so write-only callers can keep `wo_version` after removing a local secret file.
- Include the standard `## Secret values` section from the ADR in the module's `README.md`.

```hcl
# From modules/secret-manager/variables.tf
data = object({
  value      = optional(string)
  path       = optional(string)
  wo_version = optional(number)
})
is_base64 = optional(bool, false)

# Validation: allow at most one of value and path
validation {
  condition = alltrue(flatten([
    for k, v in var.secrets : [
      for sk, sv in v.versions :
      sv.data.value == null || sv.data.path == null
    ]
  ]))
  error_message = "Only one of data.value and data.path can be set in versions."
}
```

### Tag Bindings

Defined in [tag-bindings ADR](../../../../adrs/20241219-tag-bindings.md).

- Always type `tag_bindings` as `map(string)` (`default = {}`, `nullable = false`). Keys are arbitrary static identifiers (ignored by the provider) that allow dynamic tag values in `for_each`.

### Naming and `prefix`

Never generate random suffixes in resource names. Expose an optional `prefix` variable with deterministic token concatenation (`local.prefix = var.prefix == null ? "" : "${var.prefix}-"`):

```hcl
variable "prefix" {
  description = "Optional prefix used for resource names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}
```
