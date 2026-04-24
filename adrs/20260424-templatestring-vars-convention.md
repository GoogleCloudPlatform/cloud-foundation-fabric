# Convention for context variables passed to templatestring

**authors:** [Julio Castillo](https://github.com/juliocc), Antigravity (AI Assistant)
**date:** Apr 24, 2026

## Status

Approved

## Context

In Cloud Foundation Fabric, we use a single `context` variable to pass shared state between modules (as documented in `20251013-context-locals.md`). Most of these context variables are flat maps of strings used for simple lookups and full replacements (e.g., `project_ids`, `networks`).

However, some use cases require partial interpolation within strings using Terraform's `templatestring()` function (for example, resolving dynamic tags in bindings, or conditions in IAM bindings). The `templatestring()` function requires its second argument (the variables map) to be a direct reference to a data structure.

When we attempt to flatten the entire `context` variable into a single map for lookups (like `local.ctx`), complex objects like those needed for `templatestring` cause type mismatch errors because they are not flat maps of strings.

## Decision

1.  Context variables intended to be passed as the variables map (second argument) to `templatestring()` MUST be named with a `_vars` suffix (e.g., `tag_vars`, `condition_vars`).
2.  These variables MUST be excluded from the `local.ctx` flattening loop in modules to avoid type mismatch errors.
3.  Other keys in `context` not with `_vars` suffix continue to be flat maps used for full replacement/lookup.

Example of exclusion in `locals`:

```hcl
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars" && k != "tag_vars"
  }
```

Example of usage:

```hcl
  tag_value = templatestring(local._tag_bindings[each.key], var.context.tag_vars)
```

## Consequences

*   Maintains the single `context` variable pattern while supporting complex template interpolations.
*   Ensures type safety during context flattening.
*   Requires explicit exclusion of any new `_vars` variable in the module's local context construction.

## Reasoning

This convention provides a clear visual and structural distinction between simple lookup maps and complex variable structures used for templating, preventing runtime errors in Terraform.

## Implementation

This pattern has been implemented for `tag_vars` and `condition_vars` in the `project`, `folder`, `gcs`, `bigquery-dataset`, and `kms` modules, as well as in the Project Factory and relevant FAST stages.
