# Support IAM Role Sets in Context

**authors:** Simon Roberts (@lyricnz), Ludovico Magnocavallo (@ludoo)\
**date:** May 21, 2026

## Status

Draft

## Context

In complex GCP environments managed by Cloud Foundation Fabric (CFF), IAM configuration can become verbose and repetitive. Often, a logical group of roles (e.g., "Engineer", "Viewer", "Security Admin") needs to be applied to different principals across multiple projects and folders.

Currently, every IAM binding must explicitly list all individual roles. This lacks DRY principles and makes maintenance difficult when a standard role set changes.

This issue was raised in [Issue #3976](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/issues/3976).

## Design Philosophy & Trade-offs

During the discussion, we identified key trade-offs regarding this feature:

1.  **Meta-layer vs. GCP Primitives**: This feature introduces a meta-layer on top of GCP primitives. This is generally **not the approach we design CFF for**. CFF prefers explicit, flat IAM bindings that map directly to GCP primitives to ensure clarity, ease of auditing, and troubleshooting by both humans and automated tools.
2.  **Opacity**: Hiding roles behind a symbolic name (role set) introduces opacity. Auditing requires traversing an additional layer to resolve the actual roles in effect.
3.  **Resource Hierarchy vs. Repetition**: CFF typically designs the upper part of the resource hierarchy to leverage inheritance and avoid repeating roles. However, we must also support different use cases and design approaches where hierarchical grouping is not feasible.
4.  **Application-Level Validity**: Despite the above concerns, this approach is recognized as valid for application-level projects (and folders managing them). For example, when multiple distinct resources (e.g., folders) are owned by different teams who all require the same logical access profile, bindings must be applied to each separate resource. Because they cannot be consolidated via the hierarchy (as access must be scoped per team/folder), this leads to repeating the same lists of roles across many resource configurations.

## Decision

We decide to support IAM Role Sets via the `context` variable, with the following constraints to limit opacity and maintain alignment with CFF principles:

1.  **Scoped to Project and Folder Modules**: We will support role sets in the `project` and `folder` modules where application-level role reuse is common. We will **not** support them in the `organization` module, as org-level IAM should be carefully curated and domain-specific, and the minor savings do not justify the added indirection.
2.  **Scoped IAM Surface**: We will only support role sets in IAM variables that take a list of roles and are not keyed by role:
    *   `iam_by_principals`
    *   `iam_by_principals_additive`
    *   `iam_by_principals_conditional`
    Variables like `iam` (keyed by role) and `iam_bindings` / `iam_bindings_additive` (single role) will **not** support role sets. This keeps the HCL implementation simple.
3.  **Project Factory Integration**: Update the `project-factory` module to support loading role sets from a directory of YAML files (defined via `factories_config.paths.iam_role_sets`) and inject them into the context.
4.  **FAST Integration**: Support `iam_role_sets` in FAST stages using `project-factory` (e.g. stage 0, stage 2 project factory) by updating `defaults.yaml` schema and stage variables.

## Reasoning

*   **DRY (Don't Repeat Yourself)**: Address duplication in application-level IAM configurations where resource hierarchy cannot solve it.
*   **Pragmatism**: Support the pattern where it is practically needed (application projects), while discouraging it where explicit control is preferred (organization level).
*   **Implementation Simplicity**: Scoping expansion to `iam_by_principals*` variables avoids complex HCL code.

## Consequences

*   Users cannot use role sets in `iam`, `iam_bindings`, or `iam_bindings_additive` variables.
*   A new schema `iam-role-set.schema.json` is introduced to validate role set YAML files.

## Alternatives Considered

*   **Expanding all IAM variables**: Rejected due to HCL complexity.
*   **Preprocessing in FAST stages**: Rejected because it leaves modules unable to use the feature independently of FAST.

## Implementation Details

### 1. Schema for Role Sets

We will create a new schema to validate role set YAML files loaded by the factories.

#### [NEW] modules/project-factory/schemas/iam-role-set.schema.json
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "IAM Role Set",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "name": {
      "type": "string",
      "description": "Optional name. Defaults to filename if not set."
    },
    "roles": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "List of roles in this set."
    }
  },
  "required": ["roles"]
}
```

### 2. Core Modules Support

We will update `project` and `folder` modules to support the new context and implement the expansion logic.

#### [MODIFY] modules/project/variables.tf
Add `iam_role_sets` to the `context` variable definition.
```hcl
variable "context" {
  # ...
  type = object({
    # ... existing fields ...
    iam_role_sets = optional(map(list(string)), {})
  })
}
```

#### [MODIFY] modules/project/iam.tf
Implement expansion logic in `locals` and use the expanded versions in resources.
```hcl
locals {
  # Expanded iam_by_principals
  _iam_by_principals_expanded = {
    for principal, roles in var.iam_by_principals : principal => distinct(flatten([
      for r in roles : lookup(local.ctx.iam_role_sets, r, [r])
    ]))
  }

  # Expanded iam_by_principals_additive
  _iam_by_principals_additive_expanded = {
    for principal, roles in var.iam_by_principals_additive : principal => distinct(flatten([
      for r in roles : lookup(local.ctx.iam_role_sets, r, [r])
    ]))
  }

  # Expanded iam_by_principals_conditional
  _iam_by_principals_conditional_expanded = {
    for principal, v in var.iam_by_principals_conditional : principal => {
      roles = distinct(flatten([
        for r in v.roles : lookup(local.ctx.iam_role_sets, r, [r])
      ]))
      condition = v.condition
    }
  }
}
```
Update the following locals in `modules/project/iam.tf` to use the expanded variables:
- `_iam_principal_roles` -> use `local._iam_by_principals_expanded`
- `_iam_principals` -> use `local._iam_by_principals_expanded`
- `iam_bindings_additive` -> use `local._iam_by_principals_additive_expanded`
- `_iam_bindings_conditional` -> use `local._iam_by_principals_conditional_expanded`

#### [MODIFY] modules/folder/variables.tf
Add `iam_role_sets` to `context` variable (same as project).

#### [MODIFY] modules/folder/iam.tf
Implement the same expansion logic as in `project/iam.tf` and update the corresponding locals (`_iam_principal_roles`, `_iam_principals`, `iam_bindings_additive`, `_iam_bindings_conditional`) to use the expanded versions.

---

### 3. Project Factory Support

We will update the `project-factory` module to load role sets from files and propagate them.

#### [MODIFY] modules/project-factory/variables.tf
1.  Add `iam_role_sets` to `context` variable type.
2.  Add `iam_role_sets` to `factories_config.paths` type.
```hcl
variable "factories_config" {
  # ...
  type = object({
    basepath = string
    # ...
    paths = optional(object({
      # ... existing ...
      iam_role_sets     = optional(string)
    }), {})
  })
}
```

#### [MODIFY] modules/project-factory/main.tf
Load role sets from the configured path and merge them into `local.ctx`.
```hcl
locals {
  # ...
  _iam_role_sets_path = local.paths.iam_role_sets
  _iam_role_sets_raw = (
    local._iam_role_sets_path == null
    ? {}
    : {
      for f in try(fileset(local._iam_role_sets_path, "*.yaml"), []) :
      replace(f, ".yaml", "") => yamldecode(
        file("${local._iam_role_sets_path}/${f}")
      )
    }
  )
  _iam_role_sets = {
    for k, v in local._iam_role_sets_raw :
    coalesce(try(v.name, null), k) => lookup(v, "roles", [])
  }
  ctx = merge(var.context, {
    iam_role_sets = merge(try(var.context.iam_role_sets, {}), local._iam_role_sets)
  })
}
```
Ensure `local.paths` logic handles `iam_role_sets` being null.

---

### 4. FAST Integration

We will update all FAST stages that use `project-factory` to support and propagate role sets.

#### [MODIFY] fast/stages/0-org-setup/variables.tf
#### [MODIFY] fast/stages/2-networking/variables.tf
#### [MODIFY] fast/stages/2-project-factory/variables.tf
#### [MODIFY] fast/stages/2-security/variables.tf
1.  Add `iam_role_sets` to `context` variable type.
2.  Add `iam_role_sets` to `factories_config.paths` type.

#### [MODIFY] fast/stages/2-project-factory/main.tf
Explicitly pass `iam_role_sets` in the `module "factory"` call.
```hcl
  context = {
    # ...
    iam_role_sets = local.context.iam_role_sets
    # ...
  }
```

#### [MODIFY] fast/stages/0-org-setup/schemas/defaults.schema.json
Add `iam_role_sets` to `context` properties to support defining them in `defaults.yaml`.
```json
        "iam_role_sets": {
          "type": "object",
          "additionalProperties": {
            "type": "array",
            "items": {
              "type": "string"
            }
          }
        },
```

## Verification Plan

### Automated Tests
We will verify the expansion logic by augmenting existing context tests rather than creating separate test files. This keeps tests compact and exercises the feature in realistic scenarios that combine role sets with other context features like `$iam_principals` and `$custom_roles`.

1.  **Project Module Context Test**:
    *   Modify `tests/modules/project/context.tfvars` to add a `context.iam_role_sets` block and use role set references (`$iam_role_sets:...`) in `iam_by_principals`, `iam_by_principals_additive`, and `iam_by_principals_conditional` — ideally reusing existing `$iam_principals` entries.
    *   Update `tests/modules/project/context.yaml` to assert that the plan contains the fully expanded roles for the principals.
2.  **Folder Module Context Test**:
    *   Same approach as project: modify `tests/modules/folder/context.tfvars` and `tests/modules/folder/context.yaml`.
3.  **Project Factory README Test**:
    *   Modify one existing README example in `modules/project-factory/README.md` to configure `factories_config.paths.iam_role_sets` and add an external test file (e.g., `iam-role-sets/engineer.yaml` with `# tftest-file`) containing a role set.
    *   Update the corresponding project data YAML (e.g., `data/projects/test-1.yaml`) to use `$iam_role_sets:engineer` in an `iam_by_principals` entry.
    *   Update the inventory YAML and resource counts in the `# tftest` directive.

### README Examples
In addition to tests, we will modify one existing README example in each of the `project`, `folder`, and `project-factory` modules to demonstrate the feature. The resolved values should match the existing inventory YAML so no inventory changes are needed for module-level READMEs (the factory README requires inventory updates due to the additional test file and bindings).

Run tests:
```bash
pytest 'tests/modules/project/tftest.yaml::context' --tb=short -s
pytest 'tests/modules/folder/tftest.yaml::context' --tb=short -s
pytest -k 'modules and project-factory:' tests/examples
```
