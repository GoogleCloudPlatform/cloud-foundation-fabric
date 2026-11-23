# Fabric YAML Factories Guide

Conventions and non-obvious mechanics for authoring and validating YAML datasets across Fabric module factories and FAST stages. Whenever you also author Terraform root `.tf` files alongside YAML data, apply [conventions.md](conventions.md) for the HCL layer.

## Mental Model and Lookup

Fabric uses YAML factories at three levels:

- **In-module factories** manage repeated child resources under one primary entity (`net-vpc` subnets and internal ranges; `organization`/`folder`/`project` org policies, custom roles, PAM entitlements, SCC configs, and tags; `net-firewall-policy` and `net-cloud-armor` rules; `billing-account` budgets; `vpc-sc` access levels, policies, and perimeters).
- **Pure factories** manage collections of top-level entities from a dataset folder (`project-factory`, `net-vpc-factory`, `net-vpc-firewall`, `dataplex-aspect-types`, `data-catalog-tag-template`, `secops-rules`). Pure factories like `project-factory` and `net-vpc-factory` pair `factories_config = { basepath = "...", paths = { ... } }` with `data_defaults`, `data_overrides`, and (in `project-factory`) `data_merges`.
- **FAST stage datasets** (`0-org-setup`, `1-vpcsc`, `2-networking`, `2-project-factory`, `2-security`, `3-secops-dev`) wrap module factories alongside stage-level loaders and a `defaults.yaml` file under `factories_config = { dataset = "...", paths = { ... } }`.

Query exact `factories_config` keys, folder-vs-file expectations, and schema paths on demand using `<skill-dir>/scripts/fabric.py` (resolved relative to `fabric-builder/SKILL.md`) instead of guessing:

```bash
python3 <skill-dir>/scripts/fabric.py factories                  # list all factory modules and FAST stages
python3 <skill-dir>/scripts/fabric.py factories project-factory  # inspect keys and schemas for one target
python3 <skill-dir>/scripts/fabric.py fetch schemas project-factory --ref v54.0.0 --out schemas/
python3 <skill-dir>/scripts/fabric.py fetch schemas 2-project-factory --stage --ref v54.0.0 --out schemas/
```

## Schema-First Authoring and Modelines

Every YAML file should start with a `# yaml-language-server` modeline pointing either to a local schema copy (when schemas are vendored or in a local checkout) or to the pinned GitHub raw URL matching the module `?ref=` tag:

```yaml
# yaml-language-server: $schema=../../schemas/project.schema.json
```

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/GoogleCloudPlatform/cloud-foundation-fabric/v54.0.0/modules/project-factory/schemas/project.schema.json
```

Validate before handing work back:

```bash
uv run --with pyyaml --with jsonschema python3 scripts/fabric.py validate <data_dir_or_file> --require-modeline
```

Also run `yamllint` when installed to catch duplicate keys or unquoted `yes`/`no`/`on`/`off` ambiguities.

## Filesystem Layout and Path Resolution

- **Relative vs bypassed paths:** Relative entries in `factories_config.paths` (and per-project sub-factory paths in `project-factory`) are prefixed with `basepath` (or `dataset` in FAST). Paths starting with `/` or `.` bypass `basepath` so absolute paths and shared directories keep working. Pointing a path key at a non-existent folder disables that factory cleanly.
- **Canonical directory structures:**
  - `project-factory`: `folders/<path>/.config.yaml` (up to 4 levels; key is `<path>`), `projects/<any-subdir>/<stem>.yaml` (key is `<stem>` via `basename()`), `project-templates/<name>.yaml`, `budgets/<name>.yaml`. Prefer placing projects under `projects/` with explicit `parent: $folder_ids:...` rather than inside `folders/`, because placing projects inside the folder tree couples project lifecycle to folder moves.
  - `net-vpc-factory`: `vpcs/<vpc>/.config.yaml` with sibling `subnets/*.yaml` and `firewall-rules/*.yaml`.

## Symbolic `$context:` Interpolation

Context tokens keep YAML datasets portable across environments and let resources reference apply-time outputs created in the same run:

- **Full-value lookups (`$namespace:key`):** Because `lookup(local.ctx.<ns>, val, val)` falls back to the original string on a miss, a typo passes YAML parsing and leaks a literal `$...` string into the plan. Always check planned values for unresolved `$` tokens.
- **Partial templates (`*_vars`):** Context keys ending in `_vars` (`condition_vars`, `tag_vars`) feed Terraform's `templatestring()` rather than `$namespace:key` lookups — use `${...}` inside IAM condition expressions, PAM entitlements, org policies, and tag bindings.
- **Key `project-factory` built-in namespaces:** `$folder_ids:<path>`, `$project_ids:<stem>`, `$project_numbers:<stem>`, `$iam_principals:service_accounts/<proj>/<sa>` (or `_self_` in templates, or `<proj>/automation/<sa>`), `$iam_principals:service_agents/<proj>/<api>` (or `_self_`), `$service_account_ids:<proj>/<sa>` (for `iam_sa_roles`, not `$iam_principals:`), `$log_buckets:<proj>/<bucket>`, `$storage_buckets:<proj>/<bucket>`, `$tag_keys:<proj>/<key>`, `$tag_values:<proj>/<key>/<val>`, and `$custom_roles:<role_key>`.
- **`vpc-sc` and `net-vpc-factory`:** `vpc-sc` populates `$access_levels:`, `$egress_policies:`, and `$ingress_policies:` from its factories (and sets `ignore_resource_changes: true` on perimeters whose project membership is managed by `project-factory`); `net-vpc-factory` resolves `addresses`, `cidr_ranges`, `cidr_ranges_sets`, `condition_vars`, `custom_roles`, `iam_principals`, `locations`, `networks`, and `project_ids`.

## Precedence and Shallow Template Merges

In `project-factory`, fields resolve in order: `data_overrides` (non-null fields win) > YAML file > `project_template` > `data_defaults`, with `data_merges` combined additively on supported collections (`contacts`, `labels`, `metric_scopes`, `service_encryption_key_ids`, `services`, `tag_bindings`, `service_accounts`).

- **Templates merge shallowly:** Defining `iam`, `org_policies`, `labels`, or `services` in a project YAML file replaces the template's entire attribute rather than deep-merging maps or appending lists. Put baseline collections that must always append into `data_merges`.
- **Clearing a default `prefix`:** Set `prefix: null` in YAML (or `prefix = ""` in `var.projects`) to suppress `data_defaults.prefix`.
- **Required storage default:** `project-factory` checks via precondition that `data_defaults.locations.storage` or `data_overrides.locations.storage` is non-null.

## Multi-Pass DAG and Apply Order

Because Terraform treats `local.ctx` as a single dependency node, `project-factory` runs in stages so internal cross-references stay acyclic:

1. **Pass 1 (`module.projects`, `module.folder-1..4`):** Core folder/project, APIs, custom roles, tag keys/values, primary service agents, logging sinks/metrics, quotas.
2. **Intermediate Pass-1 consumers (`module.kms`, `module.service-accounts`, `module.wif`):** Consume `module.projects` so their KMS keys and SA emails feed Pass 2 `context`.
3. **Pass 2 (`module.projects-iam`, `module.folder-1..4-iam`):** Reuses Pass 1 entities with the expanded `context` and settles IAM bindings, **organization policies**, PAM entitlements, **tag bindings**, Shared VPC, **CMEK service-agent bindings**, Cloud Armor, Model Armor, and VPC-SC membership.
4. **Post-Pass 2 encrypted sub-resources (`module.buckets`, `module.log-buckets`, `module.pubsub`):** Consume `module.projects-iam` so KMS keys, CMEK bindings, and project org policies are already applied before encrypted resources are created.

**Two-step apply consequence:** Because organization policies and tag bindings run in Pass 2 (and propagate asynchronously in GCP), an org-policy exception needed by a Pass 1 resource (such as allowed Workload Identity issuers) cannot be introduced in the same `terraform apply` as that Pass 1 resource — apply the exception first, then add the dependent resource.

## Key Derivation and Schema Gotchas

- **Unique `basename()` filenames:** Both `project-factory` (across `projects/` and `folders/`) and `net-vpc` / `net-vpc-factory` (`subnets/`) key files by `basename()`. Two files sharing the same filename in different subdirectories collide, so include a distinguishing prefix or region in each filename (e.g. `prod-default-ew1.yaml`).
- **Subnet `secondary_ip_ranges` are objects:** Entries take `{ ip_cidr_range: "10.x.y.z/prefix" }` (or `{ reserved_internal_range: "..." }`), never bare CIDR strings.
- **VPC firewall rules vs Firewall Policies:** `firewall-rules.schema.json` uses top-level `ingress`/`egress` maps with `rules: [{ protocol, ports }]`, `deny: true|false`, and `enable_logging: { include_metadata: false }` (an object, not a boolean); `firewall-policy-rules.schema.json` uses `match: { source_ranges, destination_ranges, layer4_configs: [{ protocol, ports }] }` and `action: allow|deny|goto_next|apply_security_profile_group`.
- **Automation resource prefixes (`project-factory`):** Under `automation:`, service accounts drop the global prefix and use `<project>-<sa>`, while new buckets keep `<prefix>-<project>-<bucket>` (reused shared buckets with `create: false` omit `<project>`).
