# Factories Architecture

This guide covers designing and maintaining YAML-driven factories in Fabric modules: in-module vs pure factories, `factories_config` and filesystem conventions, two-tier DAG invariants, data precedence, and JSON schema synchronization. See [FACTORIES.md](../../../../FACTORIES.md) for the live index of all 21 factory-enabled modules and their schemas.

## In-Module Factories vs Pure Factories

Follow the boundary established in [factories ADR](../../../../adrs/modules/20231106-factories.md):

- **In-module factories** manage multiple repeated child resources that depend on one primary resource owned by the module — for example, `net-vpc` (`subnets_folder`, `internal_ranges_folder`), `net-firewall-policy` (rules), `organization`/`folder`/`project` (org policies, PAM entitlements, custom roles, tags), and `vpc-sc` (access levels, ingress/egress policies, perimeters). Do not add a factory for the primary resource itself inside a single-entity module (for example, `modules/project` does not implement a projects factory).
- **Pure factories** manage collections of top-level entities from YAML datasets by composing underlying modules (`project-factory`, `net-vpc-factory`) or standalone resource sets (`net-vpc-firewall`, `dataplex-aspect-types`, `data-catalog-tag-template`, `secops-rules`).

## `factories_config` Interface and Filesystem Conventions

- **Single `factories_config` object:** Group all factory paths under one `variable "factories_config"` (`nullable = false`, `default = {}` unless required) so FAST stages can compose multiple factories without key collisions.
- **`basepath` + `paths` pattern:** Multi-factory modules use a `basepath` paired with relative sub-paths under `paths` (see [dataset-base-path ADR](../../../../adrs/20260210-dataset-base-path.md)). When resolving paths, skip prepending `basepath` if the sub-path starts with `/` or `.` so absolute paths and test fixtures keep working.
- **Directory-first YAML loading:** Prefer directories (`fileset(..., "*.yaml")` or `"**/*.yaml"`) over single files. Files can define one resource per file (using the filename stem as the default key with an optional `name:` override) or a dictionary of resources flattened into a single map.

```hcl
# From modules/project-factory/variables.tf
variable "factories_config" {
  description = "Path to folder with YAML resource description data files."
  type = object({
    basepath = string
    budgets = optional(object({
      billing_account = optional(string)
    }), {})
    exclusions = optional(object({
      projects = optional(list(string), [])
    }), {})
    paths = optional(object({
      budgets           = optional(string, "budgets")
      folders           = optional(string, "folders")
      project_templates = optional(string, "project-templates")
      projects          = optional(string, "projects")
    }), {})
  })
  nullable = false
}
```

## Context as the Glue of Factory Design

Symbolic `$context:` interpolation (`var.context` resolved through `local.ctx` and `_vars` keys for `templatestring()`) is a core pillar of Fabric's factory design, serving two primary roles:

- **Portable YAML datasets across installations:** YAML files reference mnemonic keys (`$folder_ids:teams/team-a`, `$iam_principals:service_accounts/my-project/rw`, `$kms_keys:ew1/compute`) instead of hardcoded GCP IDs, so the same dataset deploys cleanly across dev, staging, prod, or completely separate customer organizations by swapping only the `context` map.
- **Decoupling stages and root modules:** Factories consume external resource IDs (folders, VPCs, subnets, KMS keys, custom roles, principals) via `context` injection rather than remote state lookups or hard-wired module paths, while also enabling internal cross-referencing of apply-time values (such as newly created service accounts or project numbers) within the same factory run.

See [context-locals ADR](../../../../adrs/20251013-context-locals.md) and [templatestring-vars-convention ADR](../../../../adrs/20260424-templatestring-vars-convention.md) for the architecture, and [conventions/hcl.md](../conventions/hcl.md#context-interpolation-implementation) for the exact `local.ctx` and lookup implementation patterns.

## Two-Tier Module Split and DAG Invariants

Terraform treats a variable or local (including `local.ctx`) as a single node in its dependency graph ([context-locals ADR](../../../../adrs/20251013-context-locals.md), [CURSED_KNOWLEDGE.md](../../../../CURSED_KNOWLEDGE.md)). A single module invocation cannot both create resources (such as projects, custom roles, tags, and service agents) and consume those sibling outputs through `context` in the same call without creating a cycle.

`modules/project-factory` solves this with a strict **multi-stage split** for folders (`folder-1..4` -> `folder-1..4-iam`) and projects (`projects` -> KMS/SAs/WIF -> `projects-iam` -> encrypted sub-resources):

- **Pass 1 (`module.projects`, `module.folder-1..4`):** Creates the core entity, enables services, creates custom roles, tag keys/values (`tags_config = { ignore_iam = true }`), primary service agents (`grant_service_agent_editor = false`), logging sinks/metrics, quotas, and non-IAM factories. Exposes `project_ids`, `project_numbers`, `service_agents`, `custom_role_id`, `tag_keys`, and `tag_values`.
- **Intermediate Pass-1 consumers (`projects-kms.tf`, `projects-service-accounts.tf`, `projects-wif.tf`):** Consume `module.projects[...].project_id` so their outputs (`kms_keys`, `service_accounts` IAM emails) can be injected into Pass 2 `context`.
- **Pass 2 (`module.projects-iam`, `module.folder-1..4-iam`):** Reuses the Pass 1 entity (`project_reuse = { use_data_source = false, attributes = { ... } }` or `folder_create = false`) with an expanded `context` carrying all Pass 1 and intermediate outputs (`iam_principals`, `custom_roles`, `project_ids`, `kms_keys`, `tag_keys`, `tag_values`, `condition_vars`, `tag_vars`). Settles IAM bindings, org policies, PAM entitlements, tag bindings, Shared VPC, CMEK service-agent bindings (`service_encryption_key_ids`), Cloud Armor policy attachment, Model Armor, and external service-agent bindings.
- **Post-Pass 2 encrypted sub-resources (`module.buckets`, `module.log-buckets`, `module.pubsub`):** Hang deliberately off `module.projects-iam[...].project_id` so `module.kms` keys, CMEK service-agent bindings, and project-level org policies are already applied before GCS buckets, logging buckets, or Pub/Sub topics are created. Moving them back onto `module.projects` breaks CMEK/org-policy ordering, and feeding their outputs back into `module.projects-iam` creates a cycle.

```hcl
# From modules/project-factory/projects.tf (Pass 2 reusing Pass 1)
module "projects-iam" {
  source   = "../project"
  for_each = local.projects_input
  name     = each.value.name
  prefix   = each.value.prefix
  project_reuse = {
    use_data_source = false
    attributes = {
      name             = module.projects[each.key].name
      number           = module.projects[each.key].number
      services_enabled = module.projects[each.key].services
    }
  }
  context = merge(local.ctx, {
    iam_principals = merge(local.ctx_iam_principals, local.projects_service_agents)
    custom_roles   = merge(try(local.ctx.custom_roles, {}), module.projects[each.key].custom_role_id)
    project_ids    = merge(local.ctx.project_ids, { for k, v in module.projects : k => v.project_id })
  })
  depends_on = [module.projects]
}
```

**Placement rule when modifying `project-factory`:**

- Place a new attribute or sub-factory in **Pass 1** only if it is required to create the entity or produces outputs that Pass 2 or Pass-1 consumers (`projects-kms.tf`, `projects-service-accounts.tf`, `projects-wif.tf`) need.
- Place anything that consumes IAM principals, custom roles, tags, KMS keys, sibling projects, or expanded `context` in **Pass 2** (note `org_policies` and `pam_entitlements` are deliberately filtered out of Pass 1 `factories_config` and run in Pass 2).
- Place sub-resource modules that rely on settled CMEK bindings or project-level org policies (such as `buckets`, `log-buckets`, `pubsub`) **downstream of Pass 2** (`module.projects-iam`).
- Keep Pass 1 free of dependencies back onto Pass 2 outputs, and enable each resource (such as `grant_service_agent_editor` or `create_primary_agents`) in only one pass so Terraform does not try to manage the same resource twice.
- Keep `project-factory` at its two-pass ceiling: do not add a third `../project` pass to work around a DAG cycle. When a feature cannot sit cleanly in Pass 1 or Pass 2 without a cycle, direct callers to higher-level hierarchy resources (org or folder level) or a downstream `modules/project` call with `project_reuse = true`.

## `data_defaults`, `data_overrides`, and `data_merges`

Pure factories separate shared policy from per-file data via three variables:

1. **`data_defaults`** — fallback values used only when omitted in the YAML file (and template).
2. **Project template** (in `project-factory`) — merged under the project YAML file.
3. **YAML file data** — per-entity intent.
4. **`data_overrides`** — non-null fields override file data and defaults (leave unset fields as `null` so they do not override).
5. **`data_merges`** — combined additively with the resulting value for collections such as `labels`, `services`, `contacts`, `metric_scopes`, `tag_bindings`, `service_encryption_key_ids`, and `service_accounts`.

Do not blindly plumb every new field into `data_defaults`, `data_overrides`, and `data_merges`. Omit them when blanket propagation makes no sense or risks unintended grants (for example, `service_agents_project_bindings` and `service_agents_folder_bindings` are intentionally excluded from all three).

## JSON Schemas, Docs, and Synchronization

Every YAML factory surface must stay strictly synchronized with its JSON schema and documentation:

- **Mirror the HCL surface in `schemas/*.schema.json`:** Match property names, strict types (no untyped blobs), and `additionalProperties: false` where appropriate. If a schema carries a secret, use the canonical `{ value, path, wo_version }` object from [write-only-secrets ADR](../../../../adrs/modules/20261029-write-only-secrets.md).
- **Modelines in YAML data files:** Include a modeline at the top of factory YAML files so editors and `tools/check_yaml_schema.py` validate them automatically:

```yaml
# yaml-language-server: $schema=../schemas/project.schema.json
billing_account: 012345-67890A-BCDEF0
parent: $folder_ids:teams/team-a
```

- **Regenerate `.schema.md`:** Run `uv run tools/schema_docs.py` after any `.schema.json` edit. CI enforces parity via `tools/check_schema_docs.py`.
- **Sync duplicated schemas:** Many schemas are intentionally duplicated across modules and FAST stages and verified by `tools/duplicate-diff.py`. Check `tools/duplicate-diff.py`, update every copy in the group in the same PR, and register new shared schemas there.
- **Update `FACTORIES.md`:** Whenever you add, rename, or remove a `factories_config` key or schema, update the tables in [FACTORIES.md](../../../../FACTORIES.md) in alphabetical order.
