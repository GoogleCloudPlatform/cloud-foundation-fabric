# Service Account External IAM Bindings with Condition Support

**authors:** [ludomagno](https://github.com/ludomagno), Antigravity (AI Assistant)
**date:** Jul 27, 2026

## Status

Approved

## Context

The `iam-service-account` module provides convenience variables (`iam_billing_roles`, `iam_folder_roles`, `iam_organization_roles`, `iam_project_roles`, `iam_sa_roles`, and `iam_storage_roles`) to grant IAM roles to the service account on external GCP resources. Currently, these variables are typed as `map(list(string))` (`{ entity_id => [roles] }`).

To support IAM conditions on these external role grants, modifying the existing variables to use `any` or complex union types is problematic:
1. The use of `any` disables HCL type validation at plan time and causes type evaluation side effects.
2. An `any` type cannot be reliably translated into JSON schemas required for factory validation in `project-factory` and FAST stages.
3. Changing the existing variable structure from lists of strings to lists of objects would introduce breaking changes for all existing consumers.

## Decision

We adopt the standard Cloud Foundation Fabric dual-variable pattern (Option B):

1. **Preserve Existing Variables:** Retain `iam_billing_roles`, `iam_folder_roles`, `iam_organization_roles`, `iam_project_roles`, `iam_sa_roles`, and `iam_storage_roles` as `map(list(string))` without changes for backward compatibility and simple unconditional role grants.
2. **Introduce Parallel Bindings Variables:** Add 6 new parallel variables:
   - `iam_billing_bindings`
   - `iam_folder_bindings`
   - `iam_organization_bindings`
   - `iam_project_bindings`
   - `iam_sa_bindings`
   - `iam_storage_bindings`
3. **Strict Type Definition:** Define each new binding variable with explicit object typing and arbitrary map keys:
   ```hcl
   type = map(object({
     entity    = string # 'project', 'bucket', 'folder', etc., depending on resource type
     role      = string
     condition = optional(object({
       expression  = string
       title       = string
       description = optional(string)
     }))
   }))
   ```
4. **Unified Resource Processing:** In `iam.tf`, merge the flattened items from `iam_*_roles` (defaulting `condition = null`) with the items from `iam_*_bindings`. Update the 6 `google_*_iam_member` resources to iterate over the merged map and implement `dynamic "condition"` blocks supporting `templatestring()` interpolation via `var.context.condition_vars`.

## Consequences

* **Type Safety & Factory Parity:** Preserves strict HCL type checking and allows deterministic translation to JSON schemas for module and stage factories.
* **Backward Compatibility:** Zero breaking changes for existing module consumers.
* **State Stability:** Callers provide arbitrary map keys for conditional bindings, guaranteeing stable and unique Terraform state keys even when granting the same role to the same entity multiple times under different conditions.
* **Interface Surface:** Adds 6 new variables to the public interface of the `iam-service-account` module.

## Implementation Plan

1. **`modules/iam-service-account`:**
   - Add the 6 new binding variables in `variables-iam.tf`.
   - Update local merge logic and add `dynamic "condition"` blocks to external IAM member resources in `iam.tf`.
   - Regenerate documentation using `python3 tools/tfdoc.py --replace modules/iam-service-account`.
   - Add test suites in `tests/modules/iam_service_account/` verifying conditional evaluation and state key stability.
2. **`modules/project-factory`:**
   - Plumb the new variables through `opts` in `projects-service-accounts.tf`.
   - Update `schemas/project.schema.json` and `schemas/folder.schema.json` to include condition properties on service account role definitions, and regenerate documentation via `python3 tools/schema_docs.py`.
3. **`fast/stages`:**
   - Propagate schema updates to downstream copies of `project.schema.json` and `folder.schema.json` across FAST stages, verifying parity with `python3 tools/duplicate-diff.py`.
