# HCL Craft and Runtime Traps

This guide covers internal `.tf` implementation conventions, canonical `context` lookup mechanics, and Terraform/OpenTofu runtime hazards distilled from [CURSED_KNOWLEDGE.md](../../../../CURSED_KNOWLEDGE.md) and maintainer reviews.

## File Organization, Ordering, and Formatting

- **Group files by logical entity:** Prefer descriptive filenames (`iam.tf`, `subnets.tf`, `shared-vpc.tf`, `logging.tf`) over dumping everything into `main.tf`. Reserve `main.tf` for top-level locals and the primary resource. Large modules can split variables and outputs into logical files (`variables-iam.tf`, `variables-tags.tf`), each internally sorted.
- **File descriptions for `tfdoc`:** Add `# tfdoc:file:description <short summary>.` at the top of `.tf` files when the module README uses `<!-- TFDOC OPTS files:1 -->`.
- **Strict alphabetical ordering:** Keep every `variables*.tf` and `outputs*.tf` file strictly sorted alphabetically. `tools/check_documentation.py` rejects unsorted variables with `[SV]`.
- **79-character line length:** Enforce 79 characters for legibility (relaxed for long resource attribute names and descriptions). Break after `{` / `(` and before `}` / `)`, break after `:` in `for` loops, wrap complex ternaries in `(...)` with `?` and `:` aligned on new lines, and split multi-argument function calls across lines.

## Locals Hygiene

- **Separate private and module-level locals:** Prefix intermediate, block-local helpers with `_` (for example, `_iam_principal_roles`); reserve unprefixed names for module-level values referenced by resources or outputs.
- **Lift complex transformations out of resource blocks:** Compute conditional maps, flattenings, and string manipulations in `locals` so resource blocks stay clean (`local.my_map[each.key]`).

```hcl
locals {
  # private intermediate transformations
  _iam_principal_roles = distinct(flatten(values(var.iam_by_principals)))
  _iam_principals = {
    for r in local._iam_principal_roles : r => [
      for k, v in var.iam_by_principals :
      k if try(index(v, r), null) != null
    ]
  }
  # module-level local consumed by resources
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local._iam_principals))) :
    role => concat(
      try(var.iam[role], []),
      try(local._iam_principals[role], [])
    )
  }
}
```

## Context Interpolation Implementation

Build `local.ctx` once in `main.tf`, excluding `_vars` keys meant for `templatestring()` ([templatestring-vars-convention ADR](../../../../adrs/20260424-templatestring-vars-convention.md)):

```hcl
locals {
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if !endswith(k, "_vars")
  }
  ctx_p      = "$"
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  region     = lookup(local.ctx.locations, var.region, var.region)
}
```

Apply lookups according to nullability so `null` stays `null` instead of crashing `lookup()`:

```hcl
# Nullable scalar
encryption_key_name = (
  var.encryption_key_name == null
  ? null
  : lookup(local.ctx.kms_keys, var.encryption_key_name, var.encryption_key_name)
)

# Deeply optional nested field
private_network = (
  try(var.network_config.psa_config.private_network, null) == null
  ? null
  : lookup(
    local.ctx.networks,
    var.network_config.psa_config.private_network,
    var.network_config.psa_config.private_network
  )
)

# Per-element list
nat_subnets = [for s in var.nat_subnets : lookup(local.ctx.subnets, s, s)]

# Partial interpolation via _vars key
tag_value = templatestring(local._tag_bindings[each.key], var.context.tag_vars)
```

## Terraform and OpenTofu Runtime Traps

CI runs both Terraform and OpenTofu (see `versions.tofu`). Watch for these recurring bugs:

- **`try()` destroys partial knownness in `for_each`:** `try(local.partially_known, [])` turns the entire result into `known after apply`, crashing resource `for_each` because keys must be known at plan time. Guard with an explicit null check instead:

```hcl
# BAD: collapses a partially-known map into fully unknown after apply
for_each = try(local.partially_known_map, {})

# GOOD: preserves known keys while values remain computed
for_each = local.partially_known_map == null ? {} : local.partially_known_map
```

- **Dynamic block permadiffs (`!= null` vs `== true`):** Never gate a `dynamic` block on `== true` when `false` is a meaningful API/state value — on every plan Terraform will drift between `false` and `null` (for example, `immutable_tags` in `modules/artifact-registry`). Check `!= null`, and always verify an empty `terraform plan` after `terraform apply`:

```hcl
dynamic "docker_config" {
  for_each = var.format_config.docker.immutable_tags != null ? [""] : []
  content {
    immutable_tags = var.format_config.docker.immutable_tags
  }
}
```

- **OpenTofu compatibility:**
  - Do not use provider-defined functions (`provider::google::...`), which break OpenTofu compatibility (see commit `8080192c3`).
  - Keep both branches of every ternary expression to identical object/primitive types — `null` and typed `null` (such as `tonumber(null)`) can fail to converge cleanly, and objects must declare identical attribute keys on both branches.
  - Ensure `nullable = false` on collection/map variables iterated directly in `for`/`for_each`, and guard optional nested objects before indexing or passing to `lookup()`/`coalesce()`.
- **Prefer `.id` over `.name` for cross-resource references:** `.id` is computed and forces downstream updates when the referenced resource is replaced. Where a child resource (such as Cloud Run IAM) does not automatically recreate when its parent is replaced, add explicit `depends_on`.
- **`create_before_destroy` contagion:** `create_before_destroy` propagates to every upstream dependency node — and because a variable, output, or local map is a single node, referencing one key from a map marks the entire map as `+/-` (create then destroy), which fails on uniquely named resources like subnetworks or storage objects. Inspect `+/-` vs `-/+` carefully in plans ([CURSED_KNOWLEDGE.md](../../../../CURSED_KNOWLEDGE.md#dealing-with-create-before-destroy)).
- **`ignore_changes` hazard:** Terraform reads ignored values at plan time and replays them during apply. Never mix a parent resource using `ignore_changes` on a field with separate additive child resources managing the same field in the same state (for example, `google_access_context_manager_service_perimeter` with `ignore_changes` alongside `google_access_context_manager_service_perimeter_resource`).
- **State-safe refactors:** Whenever renaming a resource address in an existing module, add a `moved {}` block so existing callers upgrade without destroy/recreate.
