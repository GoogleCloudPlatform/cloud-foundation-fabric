# Fabric Factory Authoring Patterns & Gotchas

Deep mechanics for authoring portable, valid YAML datasets in Cloud Foundation Fabric module factories and FAST stages.

## Filesystem Layout and `basepath` / `dataset` Resolution

Multi-factory modules (`project-factory`, `net-vpc-factory`) use `factories_config.basepath` + `factories_config.paths`; FAST stages use `factories_config.dataset` + `factories_config.paths`:

```hcl
module "project-factory" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project-factory?ref=v53.0.0&depth=1"
  data_defaults = {
    billing_account = "012345-67890A-BCDEF0"
    locations       = { storage = "eu" }
    prefix          = "myorg"
  }
  factories_config = {
    basepath = "data"
  }
}
```

Path resolution rules:
- Relative entries in `paths` are prefixed with `basepath` (or `dataset` in FAST).
- Paths starting with `/` or `.` bypass `basepath` / `dataset` (useful for absolute paths or sharing directories across datasets).
- Omitting a directory or pointing a `paths` entry at a non-existent folder disables that factory without errors.
- Per-project `factories_config` paths inside a project YAML file (such as `observability: observability/iac-0` or `org_policies: org-policies/restricted`) are also prefixed with `basepath` unless they start with `/` or `.`.

### Canonical Directory Layouts

**`project-factory`** (supports up to 4 nested folder levels):

```text
data/
├── budgets/
│   └── prod-100.yaml
├── folders/
│   └── teams/
│       ├── .config.yaml              # folder key: teams ($folder_ids:teams)
│       └── team-a/
│           ├── .config.yaml          # folder key: teams/team-a ($folder_ids:teams/team-a)
│           └── app-inline-0.yaml     # optional project: auto-inherits parent: $folder_ids:teams/team-a
├── project-templates/
│   └── gke-standard.yaml             # template key: gke-standard (no project created directly)
└── projects/
    └── team-a/
        └── prod-app-0.yaml           # project key: prod-app-0 ($project_ids:prod-app-0)
```

Prefer placing projects under `projects/` with explicit `parent: $folder_ids:...` rather than inside `folders/`; placing projects inside the folder hierarchy tree couples project lifecycle to folder path changes.

**`net-vpc-factory`**:

```text
data/
└── vpcs/
    └── prod-spoke-0/                 # VPC key: prod-spoke-0
        ├── .config.yaml              # vpc-factory.schema.json (or vpc.schema.json in FAST 2-networking)
        ├── subnets/
        │   ├── prod-app-ew1.yaml     # subnet.schema.json
        │   └── prod-app-ew8.yaml
        └── firewall-rules/
            └── allow-internal.yaml   # firewall-rules.schema.json
```

**`vpc-sc`** (in-module factories, no `basepath`):

```hcl
module "vpc-sc" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/vpc-sc?ref=v53.0.0&depth=1"
  access_policy = "1234567890"
  factories_config = {
    access_levels    = "data/access-levels"
    egress_policies  = "data/egress-policies"
    ingress_policies = "data/ingress-policies"
    perimeters       = "data/perimeters"
  }
}
```

## Symbolic `$context:` Interpolation

Context tokens decouple YAML datasets from environment-specific GCP IDs and allow cross-referencing apply-time resources created within the same factory run.

### Standard Syntax

- **Full-value lookups:** `$namespace:key` (for example `$folder_ids:teams/team-a`, `$locations:ew1`, `$kms_keys:ew1/compute`). If a value is not found in `context.<namespace>`, Fabric leaves the string literal unchanged — so a typo in a `$namespace:key` token passes `yaml` decoding and leaks a literal `$...` string into the Terraform plan.
- **Partial string templates (`*_vars`):** Context keys ending in `_vars` (such as `condition_vars` and `tag_vars`) are passed to Terraform's `templatestring()` rather than `$namespace:key` lookup maps. Use `${...}` interpolation inside IAM condition expressions, PAM entitlements, org-policy conditions/values, and tag bindings:
  ```yaml
  iam_bindings:
    dev-only:
      role: roles/viewer
      members:
        - $iam_principals:devs
      condition:
        title: dev-only
        expression: resource.matchTag('${tag_values["app-0/environment/dev"]}', 'true')
  ```

### `project-factory` Built-in Context Namespaces

In addition to user-supplied maps in `var.context`, `project-factory` automatically populates these namespaces for resources created in the same run:

| Namespace & Pattern | Key Derivation | Example / Notes |
| :--- | :--- | :--- |
| `$folder_ids:<path>` | Relative directory path under `paths.folders` | `folders/teams/team-a/.config.yaml` -> `$folder_ids:teams/team-a` |
| `$project_ids:<stem>` | Filename stem (`basename`) without `.yaml` | `projects/team-a/app-0.yaml` -> `$project_ids:app-0` |
| `$project_numbers:<stem>` | Filename stem (`basename`) without `.yaml` | Used in VPC-SC or IAM conditions |
| `$iam_principals:service_accounts/<proj>/<sa>` | Project stem + `service_accounts` map key | Regular project service account IAM email (`serviceAccount:...`) |
| `$iam_principals:service_accounts/_self_/<sa>` | Current project only (for `project_template` reuse) | Resolves only inside the same project; also works for `$service_account_ids:_self_/<sa>` |
| `$iam_principals:service_accounts/<proj>/automation/<sa>` | Project stem + `automation.service_accounts` key | Automation SA created in `automation.project` |
| `$iam_principals:service_agents/<proj>/<api>` (or `_self_`) | Project stem + service agent short key | Resolves only when that API is enabled on the target project |
| `$service_account_ids:<proj>/<sa>` (or `<proj>/automation/<sa>`) | Project stem + SA key | Required for `iam_sa_roles` (SA-on-SA bindings), not `$iam_principals:` |
| `$log_buckets:<proj>/<bucket>` | Project stem + `logging_buckets` key | Used as `logging_sinks.*.destination` |
| `$storage_buckets:<proj>/<bucket>` | Project stem + `buckets` key | Bucket name/reference |
| `$tag_keys:<proj>/<key>` & `$tag_values:<proj>/<key>/<val>` | Project stem + project-level tag key/value | Static org tags omit `<proj>/` (`$tag_keys:<key>`, `$tag_values:<key>/<val>`) |
| `$custom_roles:<role_key>` | Custom role key in `var.context` or same project | Project Pass 1 `custom_role_id` is injected into Pass 2 |

### `vpc-sc` and `net-vpc-factory` Context Namespaces

- **`vpc-sc`:** Supports `$access_levels:<key>`, `$egress_policies:<key>`, `$ingress_policies:<key>` (populated from its factories), plus `var.context` maps: `folder_ids`, `iam_principals`, `identity_sets` (list expansion), `organization_ids`, `project_numbers`, `psc_endpoints`, `resource_sets` (list expansion), `service_sets` (list expansion), and `condition_vars`. Note: `perimeters` sets `ignore_resource_changes: true` when project membership is managed externally by `project-factory`.
- **`net-vpc-factory`:** Supports `addresses`, `cidr_ranges`, `cidr_ranges_sets`, `condition_vars`, `custom_roles`, `iam_principals`, `locations`, `networks`, and `project_ids` via `var.context`. Subnets in `service_connection_policies` reference `<resolved-region>/<subnet-name>`.

## Precedence: `data_defaults`, Templates, YAML, `data_overrides`, `data_merges`

In `project-factory` (and similarly in `net-vpc-factory` without templates or `data_merges`), per-entity fields resolve in this strict order:

1. **`data_overrides`** — highest priority; any non-null field overrides both YAML and defaults. Leave fields unset (`null`) unless intentionally enforcing a factory-wide override.
2. **YAML file data** (wins over `var.projects` when both define the same project key).
3. **`project_template`** (`project-factory` only) — shallow-merged beneath the YAML file (`merge(template, project)`).
4. **`data_defaults`** — fallback used only when a field is omitted (`null`) in both the YAML file and its template.
5. **`data_merges`** (`project-factory` only) — combined **additively** on top of the resolved value for supported collections: `contacts`, `labels`, `metric_scopes`, `service_encryption_key_ids`, `services`, `tag_bindings`, and `service_accounts`.

Important edge cases:
- **Shallow template merge:** Declaring `iam`, `org_policies`, `labels`, or `services` in a project YAML file completely replaces the template's entire attribute rather than deep-merging maps or appending lists. Put baseline services/labels that should always append into `data_merges` instead of a template.
- **Clearing a default `prefix`:** Setting `prefix: null` explicitly in a project YAML file (or `prefix = ""` in `var.projects`) suppresses `data_defaults.prefix` for that project.
- **Required storage default in `project-factory`:** `data_defaults.locations.storage` or `data_overrides.locations.storage` must be set to a non-null region/multi-region (checked by a Terraform precondition).
- **FAST `defaults.yaml`:** FAST stages read `defaults.yaml` into locals and pass its sections into `data_defaults`, `data_overrides`, `data_merges`, and `context` of the underlying factories. Always validate `defaults.yaml` against the stage's `defaults.schema.json`.

## Two-Tier Module Split and Apply Order

Terraform treats `local.ctx` as one graph node, so a single module call cannot both create resources and consume sibling outputs through `context` without a dependency cycle. `project-factory` prevents cycles by running two module passes for both folders (`folder-1..4` -> `folder-1..4-iam`) and projects (`projects` -> `projects-iam`):

- **Pass 1 (`module.projects`, `module.folder-1..4`):** Creates the folder/project, enables APIs, creates custom roles, tag keys/values (`ignore_iam = true`), primary service agents, logging sinks/metrics, quotas, Workload Identity pools/providers, and parallel per-project resources (service accounts, buckets, KMS, Pub/Sub, BigQuery).
- **Pass 2 (`module.projects-iam`, `module.folder-1..4-iam`):** Reuses Pass 1 entities with the expanded `context` containing all Pass 1 outputs, and applies IAM bindings, **organization policies**, **PAM entitlements**, **tag bindings**, Shared VPC attachment, CMEK, Cloud Armor, Model Armor, and VPC-SC perimeter membership.

**Consumer consequence (two-step apply rule):** Because organization policies and tag bindings run in Pass 2 — after Pass 1 resources — and org policy propagation itself takes minutes, you cannot introduce an org-policy exception (for example, `iam.workloadIdentityPoolProviders` allowed issuers) or a tag binding required by a conditional policy in the same `terraform apply` as the Pass 1 resource that relies on it. Apply the org-policy exception or tag first, then add the dependent Pass 1 resource in a follow-up change.

Similarly, `net-vpc-factory` and FAST `2-networking` create VPCs and subnets before applying second-pass cross-VPC resources (peerings, NCC spokes, routes/PBRs referencing ILB/NVA addresses) so cross-VPC `$networks:` and `$addresses:` references stay acyclic.

## Key Derivation and Filesystem Gotchas

- **Unique project filenames across `projects/` and `folders/` (`project-factory`):** Both trees key projects by `basename()` (filename stem without `.yaml`). Never create `projects/team-a/app-0.yaml` and `projects/team-b/app-0.yaml` (or a same-named file under `folders/`) in the same factory — keys collide.
- **Unique subnet filenames per VPC (`net-vpc` / `net-vpc-factory`):** `modules/net-vpc` keys raw subnet files by `basename(file)` before building `<region>/<name>`. Never place `subnets/ew1/default.yaml` and `subnets/ew8/default.yaml` in the same VPC; include the region or tier in the filename (e.g., `subnets/ew1/prod-default-ew1.yaml`).
- **Subnet `secondary_ip_ranges` must be objects (`subnet.schema.json`):** Each entry takes `{ ip_cidr_range: "10.x.y.z/prefix" }` (or `{ reserved_internal_range: "..." }`), never a bare CIDR string.
- **VPC firewall rules vs Firewall Policies:**
  - `net-vpc-firewall` / `firewall-rules.schema.json` uses top-level `ingress` / `egress` maps with `rules: [{ protocol, ports }]`, `deny: true|false`, and `enable_logging: { include_metadata: false }` (object, not boolean).
  - `net-firewall-policy` / `firewall-policy-rules.schema.json` uses `match: { source_ranges, destination_ranges, layer4_configs: [{ protocol, ports }] }` and `action: allow|deny|goto_next|apply_security_profile_group`.
- **Automation resource prefixes in `project-factory`:** Under `automation:`, service accounts drop the global prefix and prefix with the local project key (`<project>-<sa>`), while newly created buckets keep both (`<prefix>-<project>-<bucket>`). When reusing a shared bucket with `create: false` and `managed_folders:`, the local project key is NOT appended to the bucket name.
- **Unresolved `$context:` tokens:** Because `lookup(local.ctx.<ns>, val, val)` falls back to the raw string, always inspect `terraform plan` output (or grep planned values for `\$`) to confirm no unresolved `$namespace:key` strings leaked into resource arguments.
