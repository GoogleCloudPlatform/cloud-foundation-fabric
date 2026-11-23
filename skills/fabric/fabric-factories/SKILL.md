---
name: fabric-factories
description: Authors, structures, and validates Cloud Foundation Fabric (CFF) YAML factory datasets across module factories (project-factory, net-vpc-factory, vpc-sc, and in-module factories_config keys) and FAST stages. Use when creating or editing Fabric YAML data files, configuring factories_config, writing $context interpolation or data_defaults/data_overrides/data_merges, or validating YAML datasets against Fabric JSON schemas. For general HCL module composition without YAML factories, use fabric-builder; for full FAST 2-networking topology design, use fast-networking.
---

# Fabric Factories

Author, organize, and validate YAML datasets for Cloud Foundation Fabric (CFF) module factories and FAST stages. This skill covers the YAML data layer; for composing Terraform root modules in HCL, use `fabric-builder`, and for end-to-end FAST `2-networking` topology design, use `fast-networking`.

## Mental Model: In-Module vs Pure Factories vs FAST Datasets

Fabric uses YAML factories at three progressively broader levels:

1. **In-module factories** manage repeated child resources hanging off one primary entity owned by a module (for example, `net-vpc` subnets and internal ranges, `organization`/`folder`/`project` org policies, custom roles, PAM entitlements, SCC configs, and tags, `net-firewall-policy` rules, `net-cloud-armor` rules, `billing-account` budgets, and `vpc-sc` access levels, ingress/egress policies, and perimeters). You pass file or folder paths in `factories_config`.
2. **Pure factories** manage collections of top-level entities from a dataset directory (`project-factory` for folders, projects, budgets, and per-project resources; `net-vpc-factory` for VPCs, subnets, and VPC firewall rules; `net-vpc-firewall`, `dataplex-aspect-types`, `data-catalog-tag-template`, `secops-rules`). Pure factories like `project-factory` and `net-vpc-factory` take `factories_config = { basepath = "...", paths = { ... } }` plus `data_defaults`, `data_overrides`, and (in `project-factory`) `data_merges`.
3. **FAST stage datasets** (`0-org-setup`, `1-vpcsc`, `2-networking`, `2-project-factory`, `2-security`, `3-secops-dev`) compose module-backed factories alongside stage-level YAML factories and a `defaults.yaml` file under one directory configured via `factories_config = { dataset = "...", paths = { ... } }`.

Consult [references/catalog.md](references/catalog.md) for the complete index of all 21 factory-enabled modules, their exact `factories_config` keys, folder-vs-file expectations, and schema filenames, plus the 6 FAST stages.

## Schema-First Authoring Workflow

Never invent YAML keys, enum values, or nested object shapes from memory. Follow this loop for every factory dataset:

1. **Identify the target factory and version:** Match the exact Fabric release tag (or local checkout) used by the Terraform root module. Look up the module or FAST stage and its schema filename(s) in [references/catalog.md](references/catalog.md).
2. **Obtain the JSON schema before writing YAML:**
   - If working alongside a local Fabric checkout or FAST stage, read `<module_or_stage>/schemas/<name>.schema.json` directly.
   - Otherwise, fetch the matching schema from GitHub (pin `--ref` to the consumer's Fabric release tag when known):
     ```bash
     python3 scripts/factory_tools.py fetch project-factory --ref v53.0.0 --out schemas/
     python3 scripts/factory_tools.py fetch 2-project-factory --stage --ref v53.0.0 --out schemas/
     ```
     Use `--no-ssl-verify` only if the host environment has custom TLS interception issues.
3. **Add a `# yaml-language-server` modeline at line 1 of every YAML file:**
   - Point to the local relative schema path when schemas are checked in or vendored alongside the dataset:
     ```yaml
     # yaml-language-server: $schema=../../schemas/project.schema.json
     ```
   - Or point to the pinned GitHub raw URL matching the module `?ref=` tag when schemas are not local:
     ```yaml
     # yaml-language-server: $schema=https://raw.githubusercontent.com/GoogleCloudPlatform/cloud-foundation-fabric/v53.0.0/modules/project-factory/schemas/project.schema.json
     ```
4. **Author portable YAML using `$context:` tokens and layered defaults:** Follow the filesystem, key-derivation, `$context:`, precedence, and two-tier rules summarized below and detailed in [references/patterns.md](references/patterns.md).
5. **Run the mandatory validation gate before finishing** (schema validation, YAML linting, and `terraform validate`/`plan` when HCL is present).

## Core Authoring Rules

- **`basepath` / `dataset` + `paths` resolution:** Pure factories (`project-factory`, `net-vpc-factory`) prepend `factories_config.basepath` to relative entries in `paths`; FAST stages prepend `factories_config.dataset`. Any path starting with `/` or `.` bypasses the base path. Pointing a `paths` key to a non-existent path disables that factory cleanly.
- **Directory-first vs single-file keys:** Respect whether the factory key expects a directory (`*.yaml` or `**/*.yaml`) or a single file (check [references/catalog.md](references/catalog.md)). Hierarchy folders in `project-factory` and VPC folders in `net-vpc-factory` use `.config.yaml` inside each entity's directory.
- **Key derivation matters:** Pay attention to whether a resource key comes from the filename stem, directory path, or an explicit `name:` field inside YAML. Notably, `modules/net-vpc` keys subnet files by `basename()` (so two files with the same name in different regional subfolders collide), and `modules/project-factory` keys all projects by `basename()` even across `projects/` and `folders/` subtrees. See [references/patterns.md](references/patterns.md#key-derivation-and-filesystem-gotchas).
- **Prefer `$context:` over hardcoded IDs:** Use `$namespace:key` references (e.g., `$folder_ids:teams/team-a`, `$project_ids:host-net-0`, `$iam_principals:service_accounts/app-0/rw`, `$locations:ew1`, `$kms_keys:ew1/compute`) for external and factory-created resources, and `${...}` `templatestring()` syntax with `condition_vars` / `tag_vars` for partial interpolation inside IAM conditions, org policies, and tags. See [references/patterns.md](references/patterns.md#symbolic-context-interpolation).
- **Respect precedence and shallow template merges:** In `project-factory`, effective precedence is `data_overrides` (non-null fields) > project YAML > `project_template` (shallow merge — redefining a top-level map like `iam` or `org_policies` in a project file replaces the entire template map) > `data_defaults`, with `data_merges` combined additively on collection fields. Set `prefix: null` in YAML to clear a default prefix. Always set `locations.storage` in `data_defaults` or `data_overrides` (required by `project-factory` precondition).
- **Account for the two-tier module split (DAG acyclicity):** `project-factory` splits both folders and projects into **Pass 1** (core entity, services, custom roles, tag keys/values, service accounts, buckets, WIF) and **Pass 2** (`*-iam`: IAM bindings, org policies, PAM entitlements, tag bindings, Shared VPC, CMEK, VPC-SC). This lets Pass 2 reference Pass 1 outputs via `$context:` without Terraform dependency cycles, **but** an org-policy exception or tag binding required to create a Pass 1 resource (such as an allowed WIF issuer) cannot be added in the same apply — apply the exception first, then add the dependent Pass 1 resource. See [references/patterns.md](references/patterns.md#two-tier-module-split-and-apply-order).

## Validation Gate (Run Before Finishing)

Always validate authored or modified YAML files before handing back work:

1. **JSON Schema validation against modelines:**
   ```bash
   uv run --with pyyaml --with jsonschema python3 scripts/factory_tools.py validate <data_dir_or_file> --require-modeline
   ```
   (Or `python3 scripts/factory_tools.py validate ...` when `pyyaml` and `jsonschema` are already installed; pass `--schema <path_or_url>` if validating a file without a modeline.)
2. **YAML syntax and formatting lint:** Run `yamllint` if installed (`yamllint <data_dir>`), checking indentation, duplicate keys, and valid YAML types (avoid unquoted `yes`/`no`/`on`/`off` where strings or booleans are ambiguous).
3. **Context and reference audit:** Verify every `$namespace:key` token has a matching external `context` entry, `defaults.yaml` key, or factory-created resource key with the right derivation rule.
4. **Terraform verification (when a root module is present):** Run `terraform fmt -check`, `terraform validate`, and `terraform plan` (or `-refresh=false` offline) to verify the factory decodes and plans cleanly.

## References

- [references/catalog.md](references/catalog.md) — Self-contained index of all 21 factory-enabled Fabric modules, their `factories_config` keys, schemas, and the 6 FAST stages plus addons/templates.
- [references/patterns.md](references/patterns.md) — Deep guide to `$context:` namespaces, `_self_` and `*_vars` templating, `data_defaults`/`data_overrides`/`data_merges` precedence, two-tier DAG consequences, and common schema gotchas.
- [scripts/factory_tools.py](scripts/factory_tools.py) — Self-contained helper to validate YAML files against `# yaml-language-server: $schema=...` modelines and fetch Fabric module/stage schemas or latest release tags from GitHub.
