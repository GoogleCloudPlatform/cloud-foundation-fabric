# Mapping cookbook — live GCP to Cloud Foundation Fabric

Review-hardened knowledge from the live verification rounds summarised in
[COVERAGE.md](../COVERAGE.md). Every rule here encodes a bug that was
actually made and caught; provenance markers like "(verified r9)" point
at the round that proved the rule. Read the section for a resource type
BEFORE mapping it. When in doubt, read the Fabric module source in this
repository — never trust memory for module internals.

**This document is deliberately incomplete, and always will be.** It is
not a specification of what the skill supports; it is the precipitate of
a method — the accumulated residue of mapping real resources against a
live organization and keeping what survived the gates. A type with no
section here is not unsupported. It means nobody has run the method on it
yet.

So entries are born the same way every time, and that is the only way
they should be born: someone maps a live resource by reading the module
source, converges both gates, and writes down what cost them a cycle. See
"Step 3b — when the cookbook has never seen this type" in
[SKILL.md](../SKILL.md) for the loop. **If you map a type that has no
section here, adding one is part of your run report** — that is what
keeps this file growing rather than the same traps being paid for on
every engagement.

What belongs in an entry: the CAI asset-type string as live output
returns it, the module addresses and `for_each` key formats, the import
ID format, the ForceNew inputs that must mirror live values, and every
trap that cost a cycle. Mark surfaces you did not exercise as unverified
— an honest gap is worth more than an implied guarantee.

Contents: canonical module map · factory emission (opt-in) · universal
rules · workspace layout · scaffolding scripts · import-ID table ·
per-type rules (organization, folders, projects, service accounts, log
sinks, logging buckets, VPC networks, root module) · fallback and
accelerator.

**Where the fielded data lives.** Address patterns, import IDs, CAI
asset types and verification rounds are held in
[`address-map.yaml`](./address-map.yaml) and rendered into the
import-ID table below; the prose here owns everything else — the traps,
the causal reasoning and the capability gaps. Add a new address to the
YAML, not to the table, and run
`uv run scripts/address_map.py` to check both.

## Canonical module map (normative)

Fabric modules are the product — this table is the default mapping, not
a suggestion. Raw resources require a documented module capability gap
(see "Fallback" at the end).

Emission has two modes — `per-instance` (the default: one module
instance per container, inputs as HCL) and `factory` (data-driven YAML
consumed by a Fabric factory carrier). The mode is chosen per resource
family in the manifest's `emission:` block (see "Factory emission
(opt-in)" below); families with `—` in the factory column have exactly
one mode and ignore the knob. Some sub-resources are factory-only by
Fabric convention regardless of the knob: org policies, custom roles
and custom constraints are carried as `data/` YAML inside their owning
`organization` / `folder` / `project` instance.

| Scope / resource family | Default (`per-instance`) | `factory` emission — carrier | Carries |
|---|---|---|---|
| Organization | `modules/organization` (single instance) | — | org IAM + audit configs, org policies (factory), custom roles (factory), org sinks |
| Folder | `modules/folder` — one instance per folder | `project-factory` — hierarchy `data/`, one YAML dir per folder, path = key | the folder itself, folder IAM, folder org policies (factory), folder sinks |
| Project | `modules/project` — one instance per project | `project-factory` — one project YAML per project | the project, services, project IAM, project org policies, metadata |
| Service accounts | `modules/iam-service-account` | `project-factory` — `service_accounts:` block in the owning project's YAML (only when that project is factory-emitted) | SA + its IAM |
| Log buckets | `modules/logging-bucket` | — | bucket config (sink destinations) |
| VPC networks | `modules/net-vpc` | subnets only: `net-vpc` `factories_config.subnets_folder` | network, subnets (incl. proxy-only), routes |
| VPC firewall rules (legacy) | `modules/net-vpc-firewall` | `net-vpc-firewall` `factories_config.rules_folder` | custom rules + the four `default_rules_config` rules |
| Cloud NAT & Routers | `modules/net-cloudnat` | — | Cloud NAT + its Cloud Router (NAT-only routers) |
| HA VPN | `modules/net-vpn-ha` | — | HA VPN gateway, external gateway, tunnels, its own Cloud Router, interfaces, BGP peers |
| Cloud DNS | `modules/dns` | — (no factory: recordsets are the `recordsets` input, keyed `"<type> <name>"`) | managed zones, recordsets |
| DNS Response Policy | `modules/dns-response-policy` | `dns-response-policy` `factories_config.rules` | response policies & rules |
| NCC | `modules/ncc-spoke-ra` (hub + router-appliance spokes only) | — | hub; linked-VPC/VPN spokes are a capability gap |
| Firewall policy rules | `modules/net-firewall-policy` inputs | `net-firewall-policy` `factories_config` rule files | ingress/egress rules |
| Other | nearest Fabric module for the family; check `modules/` in-repo | see `FACTORIES.md` at the repo root — the authoritative factory catalog (every module factory flows through `factories_config`) | — |

Instance keys: pick short stable slugs at first import (record them in
`coverage-map.yaml`); keys are immutable afterwards. Because the key —
not the display name — defines the address, a console rename plans as
an in-place `name` update, not destroy/create (verified r6).

## Factory emission (opt-in)

**Status: cookbook-level (C) — rules below are derived from module
source in this repository, not yet exercised against live imports.**
Everything in this section meets that standard and no higher; treat
unmarked claims as unverified.

The manifest owns the choice, per resource family. `emission` is a
map of family → style, where family names are the canonical-map rows
and styles are family-specific: `per-instance` (default) or `factory`
for module-instance families (those without a factory carrier reject
`factory`), and `additive` (default) or `authoritative` for the `iam`
pseudo-family (see "Organization and containers: IAM"). It lives on
the scope entry, like everything else in the manifest: the grammar is
scopes-only, and there is no top-level position.

Resolution, per family:

```text
scopes[].emission.<family>  →  built-in default (per-instance / additive)
```

Omission means the built-in default — for `emission` only. **Do not
generalise this to `types:`.** Both keys sit on a scope entry, and
there the resemblance stops: `emission` is denominator-neutral (it
decides how collected assets are written, and a missing family key
falls back safely), while `types:` decides what is collected at all —
every scope must declare its full list, and an omission is a refused
manifest, not a default. A wrong emission choice still faces both
gates; a wrong type list shrinks the denominator the gates are
measured against.

```yaml
scopes:
  - name: org-foundation
    levels: [organization, folder]
    # types: … (each scope carries its own list — elided here)
    emission:
      folder: factory        # -> project-factory hierarchy data/

  - name: sandbox
    levels: [folder, project]
    include: [folders/333333333333]
    # types: …
    # no emission: -> built-in defaults (per-instance; iam additive)
```

### Subtree-granular emission (scope splitting)

Emission granularity follows scope granularity: to manage *some*
folders via factory and others per-instance, split the tree into
scopes along subtree boundaries and give each its own `emission:` —
scope `include`/`exclude` already speak subtrees (CAI `ancestors`
matching), so no new selector machinery is needed. Remember the
coupling: every scope carries its own `types:` list, so a scope added
for emission reasons declares its list like any other (usually a copy
of the list it split from):

```yaml
scopes:
  - name: teams               # this subtree is factory-managed
    root: organizations/000000000000
    include: [folders/111111111111]
    levels: [folder]
    types: &folder-types
      - type: cloudresourcemanager.googleapis.com/Folder
        levels: [organization, folder]
    emission:
      folder: factory

  - name: rest                # everything else stays per-instance
    root: organizations/000000000000
    exclude: [folders/111111111111]
    levels: [folder]
    types: *folder-types      # same list; YAML anchors avoid drift
```

Rules that make the split sound (from `project-factory` source,
`folders.tf`):

- **Factory subtrees can be rooted mid-tree.** A level-1 factory
  folder takes an explicit `parent` in its `.config.yaml`
  (`parent = coalesce(<config parent>, "$folder_ids:default")`),
  resolvable through `context.folder_ids` — so a factory-managed
  subtree may sit under a per-instance-managed or unmanaged folder.
- **One factory instance for the whole workspace.** All
  factory-emitted folders share a single `project-factory` instance
  and one `data/` hierarchy, regardless of how many scopes opted in:
  disjoint subtrees become multiple top-level `data/` directories,
  each with an explicit `parent`. The factory is workspace-shaped,
  not scope-shaped — scopes decide what is collected, emission how it
  is written.
- **Boundary crossings never use literals.** Downward
  (per-instance child under a factory folder):
  `parent = module.<pf>.folder_ids["<path>"]`. Upward (factory
  subtree under a per-instance folder): `parent:` in the subtree
  root's `.config.yaml`, fed via the factory's `context.folder_ids`
  input. Every style boundary is a seam: name it in the run report.
- **The 4-level cap applies per factory subtree**, since each subtree
  root is level 1 — splitting deep hierarchies along scope boundaries
  also relieves the nesting-depth tradeoff.

When to opt in: the imported workspace is the intended day-2 operating
model and the family's ongoing management is data-shaped — the
canonical case is foundational infrastructure, with the folder tree,
folder IAM and org policies maintained as hierarchical YAML. When in
doubt, stay per-instance; graduating a family to factory emission later
is a `moved {}` exercise, per instance, at a time of your choosing.

### Tradeoffs (why per-instance stays the default)

- **Key = data path, blast radius = subtree.** In `project-factory` the
  hierarchy directory path IS the instance key: renaming or moving a
  directory re-keys every folder and project below it — a
  destroy/create plan across the subtree. The same immutability rule as
  instance keys applies (choose the `data/` layout once, record it in
  `coverage-map.yaml`), but the coupling is structural, not per-key.
  D-04 recovery applies unchanged if it ever happens.
- **Deeper, internal addresses.** Import blocks target factory
  internals — these are not a stable interface across Fabric refs, so
  "read the module source in this repository, do not trust memory" does
  double duty here. Re-verify address shapes on every Fabric ref bump.
- **Nesting depth.** `project-factory` supports at most 4 folder
  levels (hardcoded `module.folder-1` … `module.folder-4`); the
  per-instance `modules/folder` chain has no limit. A hierarchy deeper
  than 4 cannot be factory-emitted.
- **The reference rule changes carrier.** Inside factory YAML,
  references are context interpolations (`$folder_ids:<path>`,
  `$iam_principals:…`), not module outputs. The rule itself is
  unchanged — no literals for managed resources — only its spelling:
  - **Level-1 folders** (under the organization or a boundary parent):
    `parent: "organizations/<org_id>"` or `parent: "$folder_ids:default"`.
  - **Nested folders (Level 2+)**: `parent: "$folder_ids:<parent_path>"`
    (e.g. `parent: "$folder_ids:networking"` in `networking/production/.config.yaml`).
    While `project-factory` defaults omitted `parent` on child folders to
    `"$folder_ids:${parent_key}"`, emitting it explicitly makes hierarchy
    dependencies clear and self-documenting in the YAML data.

### project-factory: addresses and layout (from module source)

- Folders: `module.<pf>.module.folder-<level>["<path>"]` where
  `<level>` is 1-based directory depth and `<path>` the `data/`-relative
  directory path. Folder IAM lives on a **separate** paired instance,
  `module.<pf>.module.folder-<level>-iam["<path>"]` — both must appear
  in `coverage-map.yaml` for a folder with IAM.
- Projects: `module.<pf>.module.projects["<key>"]`; service accounts:
  see `projects-service-accounts.tf` for the key format.
- Cross-emission references: the factory outputs `folder_ids` /
  `project_ids` / `iam_principals` keyed by hierarchy path, so mixed
  mode composes without literals — a per-instance project under a
  factory folder takes `parent = module.<pf>.folder_ids["<path>"]`.
  The inverse (factory projects under per-instance folders) goes
  through the factory's `context.folder_ids` input.
- Escaping: the factory-YAML rows of the escaping table below apply
  wholesale; check `templatestring` usage per field with the same
  `grep -rn templatestring modules/project-factory/` discipline.

Other carriers (`net-vpc` subnet factory, `net-firewall-policy` rule
files, …): same method — read the carrier's `factories_config` source,
derive address + key formats, and add a subsection here as part of the
run report, marking what was exercised. `FACTORIES.md` at the repo root
is the authoritative catalog of factory carriers.

## Universal rules

### Imports and coverage

- Every emitted resource gets a paired `import` block in the owning
  instance's `*-import.tf`, and an entry in `tf/coverage-map.yaml`.
- Deterministic keys: map keys become Terraform addresses; derive them
  from content, never from list position. For additive IAM use
  `slug(role)_slug(member)`, with
  `_sha256(role\0member\0title\0expression)[:8]` appended when
  conditional; for authoritative conditional bindings use
  `slug(role)_slug(title)_sha256(role\0title\0expression)[:8]`.
- Run `terraform fmt -recursive` as the last emission step;
  `terraform fmt -check -recursive` must pass before the gates. Fmt-ed
  output is the canonical form the determinism and checksum assertions
  compare (verified plan-invariant, r11).

### Escaping

What to escape depends on two things: the carrier (HCL input or factory
YAML) and whether the module passes the field through
`templatestring()`. Check with
`grep -rn templatestring modules/<module>/` — do not guess.

| Field | Carrier | Templated? | Escape `${` as |
|---|---|---|---|
| IAM condition expressions (org, folder, project modules) | HCL input | yes | `$$${` |
| Org-policy values / condition fields / parameters (all levels) | factory YAML | yes | `$${` |
| Members, titles, filters, descriptions (non-templated inputs) | HCL input | no | `$${` |

`%{` follows the same pattern with `%`. Escape the `${` and `%{`
sequences only — never blanket-replace `$`: in HCL, `$$` not followed
by `{` is two literal dollars, so broad replacement corrupts values
(caught in r7 scaffolding review). Literal `${` round-trip is verified
end to end (r3, seeded condition title).

### The reference rule

If a referenced resource is managed in the workspace, refer to it
through its module output — never by literal string:
`project_id = module.project-<key>.project_id`,
`parent = module.folder-<key>.id`, `module.sa-<key>.iam_email` for
members where the SA is managed. Literals are only for references that
leave the managed graph (a billing account, an unimported destination),
and every such literal is an "unmanaged reference" line in the run
report. When a referenced resource later graduates into management,
upgrading the literal to a module output is part of that import's
commit (verified r10: sink destinations). Two deliberate exceptions
stay literal: import block `id`s and `coverage-map.yaml` — they are
join artifacts, and determinism and auditability win.

### Scope semantics

- References never widen scope. Managing config that references an
  unmanaged resource is fine — org sinks converge without their
  destinations, IAM bindings without their SA principals — as long as
  convergence does not depend on the referenced side and the report
  names it. The manifest decides scope.
- Scopes narrow on two axes: subtrees (`include`/`exclude`) and what
  is collected inside them (`levels`, and each scope's own `types:`
  list). Both are Scope-Approval-gate surface: they move the
  denominator.
- Manifest `include` / `exclude` match the CAI `ancestors` array,
  which stores numeric ids. Both spellings work: `projects/123456789`
  (the project NUMBER) matches directly, and a project ID is resolved
  to its number by `inventory.py` via `gcloud projects describe` —
  prefer the number where known, since resolution needs the describe
  permission. See `examples/import-manifest.org-foundation.yaml` for
  the include-vs-exclude trap and
  `examples/import-manifest.multi-domain.yaml` for selecting specific
  projects per scope.

#### Per-scope type declaration (`scopes[].types`)

Every scope carries its own `types:` list — there is no other place
to declare types, so what a scope collects is exactly what is written
on it. The same type may appear in several scopes with different
`levels`, `iam` or `enumerate`; an `enumerate:` block is swept only
in the scopes whose list names it.

Fail-closed rules (all refuse the manifest before any API call):

- a scope without a `types:` list, or with `types: []`, is refused —
  an empty list is a scope that collects nothing, and that is the one
  thing no scope may say quietly;
- a type whose `levels` cannot intersect its scope's `levels` is
  refused as a dead declaration (an entry listing `unknown` is
  exempt): it reads as coverage and produces none;
- a duplicate `type:` inside one scope's list is refused.

Provenance in `inventory.json`: each `_meta.scopes[]` entry records
its own `declared_types` yield counts and `zero_yield_types`;
`_meta.declared_types` is the aggregate; every inventory entry names
the scope(s) that collected it (`scopes: [...]`, merged and sorted
when scopes overlap). **Read the per-scope counts, not only the
aggregate** — a type that yields zero in one scope and non-zero in
another never appears in the aggregate zero-yield warning. Same
discipline as `_meta.split_parity`: read the record, not the key.

### Serialization traps

- YAML emission: quote YAML 1.1 booleans (`yes/no/on/off`), preserve
  multi-line strings verbatim (block style, no rstrip), never sort
  ordered lists.
- The API omits false booleans in JSON output (`includeChildren` absent
  means `false`, not `true`).
- Empty string vs null — **check which of the two shapes you are facing
  before reaching for a benign rule** (r17):

  1. **Module passes the variable through directly**
     (`description = var.description`, with a non-empty variable
     `default`). Setting the input explicitly to `null` round-trips a
     live empty or unset value cleanly, because Terraform treats an
     explicit null as "attribute not present" and plans no diff.
     Verified on `modules/bigquery-dataset` (r17): a live dataset with
     `description = ""` planned `"" -> "Terraform managed."` until
     `description = null` was set, after which it imported clean. **This
     is the preferred fix — a config change, not a rule.**
  2. **Module wraps the field in `coalesce(var.x, default)`.** Terraform's
     `coalesce` skips null AND empty strings, so the default always
     wins and no config value can express "empty". `null` does nothing
     here. This is the only shape where a `when_before`-guarded benign
     rule is warranted — D-03, verified on org log sinks
     (`modules/organization/logging.tf` uses
     `coalesce(each.value.description, "...")`).

  Tell them apart with
  `grep -n '<field>' modules/<module>/*.tf`. Reaching for a rule when
  shape 1 applies means shipping a benign entry that a one-line config
  change would have removed. Never an unguarded attribute rule in
  either case.
- ForceNew inputs: for every module, check which inputs are ForceNew on
  the underlying resource and mirror live values exactly BEFORE the
  first plan. A destroy/create pair on an imported resource is always a
  mapping error. Known cases: network/subnet `description` (r9), log
  bucket `parent` format (r10).
- **Silently dropped module inputs.** Terraform's object type conversion
  DISCARDS attributes a module's variable type does not declare — with
  no error and no warning. `terraform validate` returns Success. So a
  field you believe you have set may never reach the resource, and from
  the plan alone that looks identical to a provider artifact. Verified
  against `modules/certificate-authority-service` before #4106: passing
  `publishing_options` produced a clean validate and the destructive
  removal diff regardless.

  Diagnosis rule: when a diff persists on an attribute you are certain
  you have set, read the module's variable TYPE before concluding
  anything (`grep -A20 'variable "<name>"' modules/<module>/variables.tf`).
  A silently-dropped input is the mechanical tell for a module
  capability gap, and it is the single easiest way to mistake a gap for
  benign drift.

## Workspace layout (normative)

One file per container instance (organization, folder, project) and a
data tree that mirrors the hierarchy using instance keys as path
segments — never display names, so renames touch nothing and
reparenting is a cosmetic `git mv`:

```
tf/
├── versions.tf  organization.tf  organization-import.tf
├── folder-<key>.tf / project-<key>.tf     # one per CONTAINER, + -import.tf
├── coverage-map.yaml
└── data/
    ├── organization/{org-policies,custom-roles}/*.yaml
    └── folders/<key-a>/org-policies/…            # top-level folder
        └── <key-b>/org-policies/…                # child nested under parent
            └── projects/<proj-key>/org-policies/…
```

Project-contained resources live in their project's file. Every module
instance whose resource lives inside a project — service accounts,
buckets, VPCs, datasets — goes in that project's `project-<key>.tf`
(import blocks in `project-<key>-import.tf`), not in a file of its own.
A project file is the complete, reviewable inventory of that project.
Only containers get their own files (owner decision after r8).

File placement is address-neutral (verified r11: plan-invariant).
Re-homing a module block between files changes no address, no state, no
coverage-map entry — so re-layouts are always safe and do not violate
incremental immutability, which governs addresses and instance keys,
never file placement. Do re-layouts as dedicated, mapping-free commits.

Each instance's `factories_config` points at exactly its own subtree.
Module-input config (IAM, sinks) lives in the instance's `.tf` file;
only factory-driven YAML lives under `data/`. The same constraint at
different levels lands on different paths — no collisions.

## Scaffolding scripts (run-local generators)

Writing a helper script to emit the workspace is legitimate — with
governance:

1. Workspace-confined and org-confidential: scripts embed org data;
   they live in the workspace (or its private repo), never in the
   skill. Parameterize by construction — org id and container ids come
   from the manifest, `inventory.json` or argv, never hardcoded.
2. The cookbook is the spec; the script is an implementation. A
   divergence is a defect even while gates are green, because gates
   only verify paths the live org exercises today (r7 review found four
   such latent divergences).
3. Scope comes from the frozen denominator: the set of emitted things
   joins against `inventory.py` keys. Detail fetches (`describe`,
   `get-iam-policy`) are fine.
4. Deterministic: sorted iteration, stable keys, double-run
   byte-identical, `terraform fmt` as the last step.
5. No silent promotion: durable knowledge becomes cookbook prose;
   durable mechanism goes through human review into a tested frozen
   tool. Never "the script works, keep it".
6. Reported: the run report lists scaffolding used and gate verdicts;
   commit the script as round evidence (sanitized and parameterized).
7. Strict address matching: When filtering or mutating import blocks
   across incremental runs, match full resource type strings (e.g.
   `google_organization_iam_custom_role`) rather than loose substrings
   (like `"custom_role"`), which collide with role IDs such as
   `roles/latchkey_custom_role_automation`.

## Import-ID quick table

**Generated — do not edit by hand.** The rows below are rendered from
[`address-map.yaml`](./address-map.yaml), which owns the fielded subset
of this cookbook: asset type, module, address pattern, import ID and the
round that verified it. Edit the YAML and re-render:

```bash
uv run scripts/address_map.py --render-cookbook
```

Two invariants are machine-enforced there and cannot be restated here by
accident: an address pattern is claimed by exactly one entry, and a CAI
asset type serviced by more than one module must say how to tell the
carriers apart. `<placeholder>` segments are chosen per engagement.
A blank `Verified` cell means the surface was never exercised live —
an honest gap, not an implied guarantee.

<!-- BEGIN ADDRESS-MAP (generated) -->

| Resource | Module | Address pattern | Import ID | Verified |
|---|---|---|---|---|
| BigQuery Dataset | `modules/bigquery-dataset` | `module.<instance>.google_bigquery_dataset.default` | `projects/<project_id>/datasets/<dataset_id>` | r17 |
| CAS CA Pool | `modules/certificate-authority-service` | `module.<instance>.google_privateca_ca_pool.default[0]` | `projects/<project_id>/locations/<location>/caPools/<name>` | r14 |
| CAS CA Pool IAM | `modules/certificate-authority-service` | `module.<instance>.google_privateca_ca_pool_iam_binding.authoritative["<role>"]` | `projects/<project_id>/locations/<location>/caPools/<name> <role>` | — |
| CAS CA Pool IAM (cond.) | `modules/certificate-authority-service` | `module.<instance>.google_privateca_ca_pool_iam_binding.bindings["<key>"]` | `projects/<project_id>/locations/<location>/caPools/<name> <role> <condition_title>` | — |
| Certificate Authority | `modules/certificate-authority-service` | `module.<instance>.google_privateca_certificate_authority.default["<id>"]` | `projects/<project_id>/locations/<location>/caPools/<pool>/certificateAuthorities/<id>` | — |
| DNS zone | `modules/dns` | `module.<instance>.google_dns_managed_zone.dns_managed_zone[0]` | `projects/<project_id>/managedZones/<zone>` | r12 |
| DNS recordset | `modules/dns` | `module.<instance>.google_dns_record_set.dns_record_set["<type> <name>"]` | `projects/<project_id>/managedZones/<zone>/rrsets/<record_name>/<type>` | — |
| DNS Response Policy | `modules/dns-response-policy` | `module.<instance>.google_dns_response_policy.default[0]` | `projects/<project_id>/responsePolicies/<response_policy_name>` | — |
| DNS Response Policy rule | `modules/dns-response-policy` | `module.<instance>.google_dns_response_policy_rule.default["<rule_name>"]` | `projects/<project_id>/responsePolicies/<response_policy_name>/rules/<rule_name>` | — |
| Folder | `modules/folder` | `module.folder-<key>.google_folder.folder[0]` | `folders/<id>` | r6 |
| Folder IAM | `modules/folder` | `module.folder-<key>.google_folder_iam_binding.authoritative["<role>"]` | `folders/<id> <role>` | r6 |
| Folder IAM (cond.) | `modules/folder` | `module.folder-<key>.google_folder_iam_binding.bindings["<key>"]` | `folders/<id> <role> <condition_title>` | r6 |
| Folder IAM member (additive, default) | `modules/folder` | `module.folder-<key>.google_folder_iam_member.bindings["<key>"]` | `folders/<id> <role> <member>` | — |
| Folder sink | `modules/folder` | `module.folder-<key>.google_logging_folder_sink.sink["<name>"]` | `folders/<id>/sinks/<name>` | r6 |
| Folder org policy | `modules/folder` | `module.folder-<key>.google_org_policy_policy.default["<constraint>"]` | `folders/<id>/policies/<constraint>` | r6 |
| GCS bucket | `modules/gcs` | `module.<instance>.google_storage_bucket.bucket[0]` | `<project_id>/<bucket_name>` | r12 |
| Service account | `modules/iam-service-account` | `module.sa-<key>.google_service_account.service_account[0]` | `projects/<project_id>/serviceAccounts/<email>` | r8 |
| SA IAM binding | `modules/iam-service-account` | `module.sa-<key>.google_service_account_iam_binding.authoritative["<role>"]` | `projects/<project_id>/serviceAccounts/<email> <role>` | r8 |
| SA IAM binding (cond.) | `modules/iam-service-account` | `module.sa-<key>.google_service_account_iam_binding.bindings["<key>"]` | `projects/<project_id>/serviceAccounts/<email> <role> <condition_title>` | r8 |
| SA IAM member (additive, default) | `modules/iam-service-account` | `module.sa-<key>.google_service_account_iam_member.bindings["<key>"]` | `projects/<project_id>/serviceAccounts/<email> <role> <member>` | — |
| KMS CryptoKey | `modules/kms` | `module.<instance>.google_kms_crypto_key.default["<key>"]` | `projects/<project_id>/locations/<location>/keyRings/<name>/cryptoKeys/<key>` | r13 |
| KMS CryptoKey IAM | `modules/kms` | `module.<instance>.google_kms_crypto_key_iam_binding.authoritative["<key>.<role>"]` | `projects/<project_id>/locations/<location>/keyRings/<name>/cryptoKeys/<key> <role>` | r13 |
| KMS KeyRing | `modules/kms` | `module.<instance>.google_kms_key_ring.default[0]` | `projects/<project_id>/locations/<location>/keyRings/<name>` | r13 |
| Log bucket | `modules/logging-bucket` | `module.logging_bucket_<key>.google_logging_project_bucket_config.bucket[0]` | `projects/<project_id>/locations/<location>/buckets/<name>` | r10 |
| NCC Hub | `modules/ncc-spoke-ra` | `module.<instance>.google_network_connectivity_hub.hub[0]` | `projects/<project_id>/locations/global/hubs/<hub_name>` | — |
| NCC spoke (router appliance) | `modules/ncc-spoke-ra` | `module.<instance>.google_network_connectivity_spoke.spoke_ra` | `projects/<project_id>/locations/<location>/spokes/<spoke_name>` | — |
| Compute address (global PSA) | `modules/net-address` | `module.<instance>.google_compute_global_address.psa["<key>"]` | `projects/<project_id>/global/addresses/<name>` | r19 |
| Compute address (global PSC) | `modules/net-address` | `module.<instance>.google_compute_global_address.psc["<key>"]` | `projects/<project_id>/global/addresses/<name>` | r19 |
| Compute address (regional internal) | `modules/net-address` | `module.<instance>.google_compute_address.internal["<key>"]` | `projects/<project_id>/regions/<region>/addresses/<name>` | r19 |
| Cloud NAT | `modules/net-cloudnat` | `module.<nat_instance>.google_compute_router_nat.nat` | `projects/<project_id>/regions/<region>/routers/<router>/<nat>` | r12 |
| Cloud Router | `modules/net-cloudnat` | `module.<nat_instance>.google_compute_router.router[0]` | `projects/<project_id>/regions/<region>/routers/<name>` | r12 |
| Hierarchical Firewall Policy | `modules/net-firewall-policy` | `module.<instance>.google_compute_firewall_policy.hierarchical[0]` | `locations/global/firewallPolicies/<id>` | r7 |
| Global Network Firewall Policy | `modules/net-firewall-policy` | `module.<instance>.google_compute_network_firewall_policy.net_global[0]` | `projects/<project_id>/global/firewallPolicies/<name>` | r7 |
| Regional Network Firewall Policy | `modules/net-firewall-policy` | `module.<instance>.google_compute_region_network_firewall_policy.net_regional[0]` | `projects/<project_id>/regions/<region>/firewallPolicies/<name>` | r7 |
| Interconnect Attachment | `modules/net-vlan-attachment` | `module.<instance>.google_compute_interconnect_attachment.default["<key>"]` | `projects/<project_id>/regions/<region>/interconnectAttachments/<name>` | — |
| VPC network | `modules/net-vpc` | `module.net_vpc_<key>.google_compute_network.network[0]` | `projects/<project_id>/global/networks/<name>` | r3 |
| VPC route (gateway) | `modules/net-vpc` | `module.net_vpc_<key>.google_compute_route.gateway["<key>"]` | `projects/<project_id>/global/routes/<net>-<key>` | r9 |
| VPC route (ilb) | `modules/net-vpc` | `module.net_vpc_<key>.google_compute_route.ilb["<key>"]` | `projects/<project_id>/global/routes/<net>-<key>` | r9 |
| VPC route (instance) | `modules/net-vpc` | `module.net_vpc_<key>.google_compute_route.instance["<key>"]` | `projects/<project_id>/global/routes/<net>-<key>` | r9 |
| VPC route (ip) | `modules/net-vpc` | `module.net_vpc_<key>.google_compute_route.ip["<key>"]` | `projects/<project_id>/global/routes/<net>-<key>` | r9 |
| VPC route (vpn tunnel) | `modules/net-vpc` | `module.net_vpc_<key>.google_compute_route.vpn_tunnel["<key>"]` | `projects/<project_id>/global/routes/<net>-<key>` | r9 |
| VPC subnet | `modules/net-vpc` | `module.net_vpc_<key>.google_compute_subnetwork.subnetwork["<region>/<name>"]` | `projects/<project_id>/regions/<region>/subnetworks/<name>` | r3 |
| VPC subnet (private NAT) | `modules/net-vpc` | `module.net_vpc_<key>.google_compute_subnetwork.private_nat["<region>/<name>"]` | `projects/<project_id>/regions/<region>/subnetworks/<name>` | — |
| VPC subnet (proxy-only) | `modules/net-vpc` | `module.net_vpc_<key>.google_compute_subnetwork.proxy_only["<region>/<name>"]` | `projects/<project_id>/regions/<region>/subnetworks/<name>` | r9 |
| VPC firewall rule (custom) | `modules/net-vpc-firewall` | `module.<instance>.google_compute_firewall.custom_rules["<rule_name>"]` | `projects/<project_id>/global/firewalls/<rule_name>` | — |
| VPC firewall rule (default, admins) | `modules/net-vpc-firewall` | `module.<instance>.google_compute_firewall.allow_admins[0]` | `projects/<project_id>/global/firewalls/<network_name>-ingress-admins` | — |
| VPC firewall rule (default, http) | `modules/net-vpc-firewall` | `module.<instance>.google_compute_firewall.allow_tag_http[0]` | `projects/<project_id>/global/firewalls/<network_name>-ingress-tag-http` | — |
| VPC firewall rule (default, https) | `modules/net-vpc-firewall` | `module.<instance>.google_compute_firewall.allow_tag_https[0]` | `projects/<project_id>/global/firewalls/<network_name>-ingress-tag-https` | — |
| VPC firewall rule (default, ssh) | `modules/net-vpc-firewall` | `module.<instance>.google_compute_firewall.allow_tag_ssh[0]` | `projects/<project_id>/global/firewalls/<network_name>-ingress-tag-ssh` | — |
| External VPN Gateway | `modules/net-vpn-ha` | `module.<vpn_instance>.google_compute_external_vpn_gateway.external_gateway["<peer_key>"]` | `projects/<project_id>/global/externalVpnGateways/<name>` | — |
| HA VPN Gateway | `modules/net-vpn-ha` | `module.<vpn_instance>.google_compute_ha_vpn_gateway.ha_gateway[0]` | `projects/<project_id>/regions/<region>/vpnGateways/<name>` | — |
| Cloud Router (VPN) | `modules/net-vpn-ha` | `module.<vpn_instance>.google_compute_router.router[0]` | `projects/<project_id>/regions/<region>/routers/<name>` | — |
| Cloud Router interface (VPN) | `modules/net-vpn-ha` | `module.<vpn_instance>.google_compute_router_interface.router_interface["<tunnel_key>"]` | `<project_id>/<region>/<router_name>/<interface_name>` | — |
| Cloud Router BGP peer (VPN) | `modules/net-vpn-ha` | `module.<vpn_instance>.google_compute_router_peer.bgp_peer["<tunnel_key>"]` | `projects/<project_id>/regions/<region>/routers/<router_name>/<peer_name>` | — |
| VPN Tunnel | `modules/net-vpn-ha` | `module.<vpn_instance>.google_compute_vpn_tunnel.tunnels["<tunnel_key>"]` | `projects/<project_id>/regions/<region>/vpnTunnels/<name>` | — |
| Org audit config | `modules/organization` | `module.organization.google_organization_iam_audit_config.default["<service>"]` | `<org> <service>` | r3 |
| Custom role | `modules/organization` | `module.organization.google_organization_iam_custom_role.roles["<id>"]` | `organizations/<org>/roles/<id>` | r3 |
| Org IAM binding (authoritative opt-in) | `modules/organization` | `module.organization.google_organization_iam_binding.authoritative["<role>"]` | `<org> <role>` | r3 |
| Org IAM binding (cond.) | `modules/organization` | `module.organization.google_organization_iam_binding.bindings["<key>"]` | `<org> <role> <condition_title>` | r3 |
| Org IAM member (additive, default) | `modules/organization` | `module.organization.google_organization_iam_member.bindings["<key>"]` | `<org> <role> <member>` | — |
| Org log sink | `modules/organization` | `module.organization.google_logging_organization_sink.sink["<name>"]` | `organizations/<org>/sinks/<name>` | r3 |
| Org policy | `modules/organization` | `module.organization.google_org_policy_policy.default["<constraint>"]` | `organizations/<org>/policies/<constraint>` | r5 |
| Tag Key | `modules/organization` | `module.organization.google_tags_tag_key.default["<short_name>"]` | `tagKeys/<id>` | r18 |
| Tag Value | `modules/organization` | `module.organization.google_tags_tag_value.default["<key_short_name>/<value_short_name>"]` | `tagValues/<id>` | r18 |
| Tag Binding | `modules/organization` | `module.<instance>.google_tags_tag_binding.binding["<key>"]` | `tagBindings/<url-encoded-parent-and-value>` | r18 |
| PAM entitlement | `modules/project` | `module.<container>.google_privileged_access_manager_entitlement.default["<entitlement_id>"]` | `<parent>/locations/<location>/entitlements/<entitlement_id>` | — |
| Project | `modules/project` | `module.project-<key>.google_project.project[0]` | `projects/<project_id>` | r4 |
| Project IAM | `modules/project` | `module.project-<key>.google_project_iam_binding.authoritative["<role>"]` | `<project_id> <role>` | r4 |
| Project IAM (cond.) | `modules/project` | `module.project-<key>.google_project_iam_binding.bindings["<key>"]` | `<project_id> <role> <condition_title>` | r4 |
| Project IAM member (additive, default) | `modules/project` | `module.project-<key>.google_project_iam_member.bindings["<key>"]` | `<project_id> <role> <member>` | — |
| Project org policy | `modules/project` | `module.project-<key>.google_org_policy_policy.default["<constraint>"]` | `projects/<project_id>/policies/<constraint>` | — |
| Project service | `modules/project` | `module.project-<key>.google_project_service.project_services["<api>"]` | `<project_id>/<api>` | r4 |
| Project service (orgpolicy) | `modules/project` | `module.project-<key>.google_project_service.org_policy_service[0]` | `<project_id>/orgpolicy.googleapis.com` | r4 |
| Workload Identity Pool | `modules/project` | `module.project-<key>.google_iam_workload_identity_pool.default["<pool_id>"]` | `projects/<project_id>/locations/global/workloadIdentityPools/<pool_id>` | r18 |
| Workload Identity Pool Provider | `modules/project` | `module.project-<key>.google_iam_workload_identity_pool_provider.default["<pool_id>/<provider_id>"]` | `projects/<project_id>/locations/global/workloadIdentityPools/<pool_id>/providers/<provider_id>` | r18 |
| Pub/Sub Topic | `modules/pubsub` | `module.<instance>.google_pubsub_topic.default` | `projects/<project_id>/topics/<topic_name>` | r17 |
| VPC-SC Access Level | `modules/vpc-sc` | `module.<instance>.google_access_context_manager_access_level.basic["<key>"]` | `accessPolicies/<policy_id>/accessLevels/<level_name>` | r15 |
| VPC-SC Access Policy | `modules/vpc-sc` | `module.<instance>.google_access_context_manager_access_policy.default[0]` | `<policy_id>` | r15 |
| VPC-SC Service Perimeter | `modules/vpc-sc` | `module.<instance>.google_access_context_manager_service_perimeter.regular["<key>"]` | `accessPolicies/<policy_id>/servicePerimeters/<perimeter_name>` | r15 |
| NCC spoke (raw — capability gap) | raw | `google_network_connectivity_spoke.<instance>` | `projects/<project_id>/locations/<location>/spokes/<spoke_name>` | r12 |

<!-- END ADDRESS-MAP -->

Verified across r2–r19 (see COVERAGE.md for the per-family evidence).
For anything else: check the provider documentation's import section, or
emit the import block with the CAI asset name minus the
`//<service>.googleapis.com/` prefix — verified to match the provider
import ID byte-for-byte on every family tested (r5 oracle, 100%) — and
let plan tell you: it errors loudly and safely on a wrong ID.

## Per-type rules

### Organization: org policies

- Factory files in `data/.../org-policies/` wrap each policy in a map
  keyed by the constraint name (`<constraint>: {rules: [...]}`) — the
  module merges raw YAML via `yamldecode()` (verified r5).
- `dryRunSpec` is real config: emit it under a `dry_run:` block in the
  same constraint definition. A dry-run-only policy must never become
  `rules: []` (verified r4; CAI omits dry-run-only policies — the
  inventory service-API sweep exists for exactly this).
- `parameters` must be a JSON string (the module feeds it to
  `templatestring()`), serialized deterministically
  (`json.dumps(..., sort_keys=True)`) (verified r3).
- Factory `fileset()` is non-recursive: filenames are
  `<constraint>.yaml`, never subdirectories.
- Value lists are ordered attributes: preserve live order (verified r3).
- **Verbatim condition expressions**: Condition expressions in org policy
  rules returned by the API can carry a trailing newline (`\n`). In factory
  YAML, use block scalar style (`|`) rather than quoted/stripped strings so
  the trailing newline is preserved and does not plan as an in-place update.

### Organization: custom roles

- Factory configuration:
  `factories_config = { custom_roles = "<path>" }`.
- Factory YAML schema: `includedPermissions: [...]` (matching the IAM
  API attribute), `title`, `description`, `stage` (verified r5).
- Title/description/stage need a Fabric ref containing PR #4102; on
  v57.0.0 they plan as in-place updates (D-01).

### Organization and containers: IAM

- **Additive is the default emission for IAM** (manifest
  `emission.iam`, styles `additive` | `authoritative`, same two
  positions and resolution as every other emission family). Each live
  (role, member, condition) tuple maps to one `iam_bindings_additive`
  entry → one `google_*_iam_member.bindings["<key>"]`. Why default:
  an apply can only create or destroy the exact tuples emitted — it
  can never remove members it does not manage — and it is the
  non-authoritative posture Google's PAM documentation recommends.
  The honest tradeoff: additive emission cannot converge out-of-band
  *additions* away — unmanaged members accumulate invisibly to the
  plan, while coverage still counts the container policy as mapped.
  Estates that want IAM fully declarative as the day-2 model opt into
  `emission.iam: authoritative` (`iam` / `iam_bindings` maps — the
  emission every existing verified round exercised); the choice is
  the human's, recorded in the manifest.
- Assert IAM policy `version: 3` when conditions exist — v1/v2
  responses flatten conditions, which is silent privilege escalation.
- `deleted:` principals cannot be imported; exclude them from bindings
  but always surface them in the report (under additive emission the
  tombstones simply stay unmanaged; under authoritative emission an
  apply would remove them).
- **PAM grant bindings are runtime state, never configuration —
  excluded from the denominator by `inventory.py`, not by you.** On
  grant activation, Privileged Access Manager injects a temporary
  time-bound conditional binding into the container's allow policy and
  revokes it itself when the grant ends; Google's PAM documentation
  explicitly warns against managing these bindings in Terraform.
  Whenever IAM is collected, `inventory.py` also sweeps active grants
  through CAI (`privilegedaccessmanager.googleapis.com/Grant` — CAI
  models the Grant, not the Entitlement; one extra call per scope,
  covered by the same `cloudasset.viewer` grant) and strips matching
  bindings before normalization. Matching is deterministic — (target,
  role, requester) come from the grant resource itself, never from
  string-matching the binding's condition, whose format Google does
  not publish — and deliberately narrow: conditional bindings only, so
  a permanent binding coinciding with a grant is kept. A container
  whose policy holds only grant bindings mints no `#iam` entry:
  structural exemption, not a waiver. Stripped bindings are stamped in
  `_meta.pam_grant_exclusions`; quote them in the run report's
  machine-managed exclusions. At emission time, work from the stamped
  list — if a live policy shows a conditional binding that looks
  PAM-shaped but is not in the stamp, the inventory is stale:
  re-collect, do not classify by hand. Exclusion is also
  collision-safe: under the additive default nothing unmanaged can be
  removed by construction, and even under authoritative opt-in Fabric
  `iam` maps produce bindings authoritative for the (role,
  no-condition) tuple while PAM bindings always carry a condition, so
  an apply of the emitted config cannot revoke an active grant. Declaring the Grant type in a manifest is refused. Do not
  confuse grants with PAM *entitlements*, which are ordinary importable
  configuration mapping to the `pam_entitlements` factory on
  `organization` / `folder` / `project`.
- Audit configs map to `logging_data_access` on `modules/organization`
  (verified r3).
- Conditional binding import IDs need a non-empty condition title;
  format is space-separated:
  `<org_or_folder_or_project_id> <role> <condition_title>`.
- **Multi-module state consolidation**: When inferring from Terraform
  state where IAM for the same scope/role is split across multiple module
  instances (e.g. `module.organization`, `module.organization-iam`, or
  dynamic factory loops): under authoritative emission, member lists
  must be union-merged across all matching state bindings before
  mapping into canonical module `iam` maps; under additive emission,
  deduplicate (role, member, condition) tuples across instances
  instead — each tuple is emitted exactly once.
- **Verbatim condition expressions & ForceNew**: IAM condition expressions
  from live API policies frequently contain a trailing newline (`\n`).
  Because `condition.expression` on `google_*_iam_binding` is `ForceNew`,
  stripping whitespace or omitting the newline triggers a spurious
  destroy/create (replacement) plan. Preserve the exact string from the live
  API (e.g. via HCL heredoc `<<-EOT` or explicit `\n`).

### Folders (`modules/folder`, one instance per folder)

- Chain parents by module reference
  (`parent = module.folder-<parent-key>.id`; top-level folders point at
  the org). No nesting-depth limit — unlike factory emission, which
  caps at 4 levels (see "Factory emission (opt-in)").
- Set `deletion_protection = true` (imported provider default; avoids a
  spurious in-place change — verified r2).
- Folder-level org policies, sinks and IAM live on the same instance as
  the folder — never a separate wrapper.
- Display-name renames are plain `name` updates (verified r6).
- Re-keying recovery (D-04) — only if instance keys themselves must
  change, which should be never. If a plan ever shows a destroy/create
  pair on the same folder id:
  1. Stop — never let that plan stand, even unapplied.
  2. Rename the factory path/key to the new slug (content unchanged).
  3. Add `moved { from = <old address> to = <new address> }` at the
     workspace root and keep the block permanently.
  4. Update the `coverage-map.yaml` entry's address in the same commit
     (the one sanctioned exception to address immutability — the key
     stays, the address moves with the `moved` block as evidence).
  5. Re-plan: the pair must collapse to no-op or update before anything
     else proceeds. Automatic `moved {}` generation is deliberately
     deferred until a real engagement needs it at scale.

### Projects (`modules/project`, one instance per project)

- Chain parent by module reference or the org id for top-level
  projects.
- Set `deletion_policy = "PREVENT"`. `auto_create_network = true`
  matched live state with zero diff on the pilot projects — confirm per
  project via plan rather than assuming (r7).
- `services`: the enabled-service list from the live ServiceUsage API.
  `orgpolicy.googleapis.com` maps internally to
  `google_project_service.org_policy_service[0]`; every other service
  maps to `google_project_service.project_services["<api>"]` (r7).
- CAI can report ghost services (disabled in ServiceUsage but present
  in CAI): cross-check `gcloud services list` and waive with evidence
  (r7).
- `service_agents_config`: set `{ create_primary_agents = false,
  grant_default_roles = false, grant_service_agent_editor = false }` on
  imported projects to avoid unwanted resource creation or default role
  injection (r7).
- `labels`: pass `{}` or live labels. Provider-computed
  `terraform_labels` diffs are covered by a `when_before`-guarded
  benign rule (r7).

### Service accounts (`modules/iam-service-account`) — verified r8

- Manifest: `iam.googleapis.com/ServiceAccount` with `iam: true` —
  without the opt-in, impersonation grants (IAM on the SA) are
  invisible to the denominator.
- Google-managed and service-agent SAs (`*-compute@developer.`,
  `*@cloudservices.`, `service-*@gcp-sa-*`) must be waived, never
  imported — they are lifecycle-bound to services, not user config.
- SA keys: do not import or enumerate user-managed keys (secrets);
  waive and note in the report.
- Reference rule: `project_id = module.project-<key>.project_id`;
  impersonation members that are themselves managed SAs use
  `module.sa-<key>.iam_email`; unmanaged principals stay literal and
  are listed in the report.

### Log sinks (org/folder level)

- Never import `_Default` / `_Required` (Google-managed; automatically excluded from the denominator by `inventory.py`).
- The module `type` enum is `gcs` (not `storage`), `bigquery`,
  `logging`, `pubsub`, `project` — map the destination API prefix
  accordingly; fail on an unknown prefix, never rewrite (r7).
- `destination` expects the path without the API prefix — the module
  prefixes `<api>.googleapis.com/` itself (r5).
- Emit `exclusions`, `bq_partitioned_table` (bigquery only),
  `intercept_children`; set `iam = false` and report the writer-identity
  grant if the destination is unmanaged.
- When the destination graduates into management, upgrade the literal
  destination to the destination module's output in the same commit
  (verified r10; the sink then plans as a clean no-op).

### Logging buckets (`modules/logging-bucket`) — verified r10

- Manifest: `logging.googleapis.com/LogBucket`, `levels: [project]`.
- `_Default` and `_Required` buckets are Google-managed and automatically excluded from the denominator by `inventory.py`.
- ForceNew parent trap: the provider stores
  `project = "projects/<id>"` on import; a bare project id in `parent`
  plans a ForceNew recreation. Always pass
  `parent = "projects/${module.project-<key>.project_id}"`.

### Storage buckets (`modules/gcs`) — verified r12

- Manifest: `storage.googleapis.com/Bucket`, `levels: [project]`.
- Address: `module.<instance>.google_storage_bucket.bucket[0]`.
- Import-ID trap (ForceNew): a bare `<bucket_name>` id leaves
  `project = ""` in state, and the module's `project_id` then plans a
  ForceNew recreation. Always use `<project_id>/<bucket_name>`.
- Lives in `project-<key>.tf`;
  `project_id = module.project-<key>.project_id`.

### BigQuery datasets (`modules/bigquery-dataset`) — verified r17 (datasets)

- Manifest: `bigquery.googleapis.com/Dataset`, `levels: [project]`.
- Address: `module.<instance>.google_bigquery_dataset.default` (singleton, NO `[0]`).
- Import ID: `projects/<project_id>/datasets/<dataset_id>`.
- Output reference: `module.<instance>.id` (returns `projects/<project_id>/datasets/<dataset_id>`).
- **Default description trap**: `modules/bigquery-dataset` defaults `description = "Terraform managed."`. When adopting a live dataset with an empty description, explicitly set `description = null` in module inputs to achieve clean 0-diff import convergence.
- **Reference rule**: `project_id = module.project_<key>.project_id`.
- Tables, views, materialized views, routines, and dataset IAM: unverified (dataset-only path).
- Lives in `project-<key>.tf`.

### Pub/Sub topics (`modules/pubsub`) — verified r17 (topics)

- Manifest: `pubsub.googleapis.com/Topic`, `levels: [project]`.
- Address: `module.<instance>.google_pubsub_topic.default` (singleton, NO `[0]`).
- Import ID: `projects/<project_id>/topics/<topic_name>`.
- Output reference: `module.<instance>.id` (returns `projects/<project_id>/topics/<topic_name>`).
- **Reference rule**: `project_id = module.project_<key>.project_id`.
- Subscriptions, schemas, and topic IAM: unverified (topic-only path).
- Lives in `project-<key>.tf`.


### DNS zones and recordsets (`modules/dns`) — verified r12 (zones)

- Manifest: `dns.googleapis.com/ManagedZone` and, for recordsets,
  `dns.googleapis.com/ResourceRecordSet`; `levels: [project]`.
- Addresses and import IDs: see the generated table.
- Private-zone client networks reference
  `module.net_vpc_<key>.self_link`.
- **Recordset `for_each` key**: `"<type> <name>"` — type first, one
  space, and `<name>` carries the trailing dot exactly as the API
  returns it (`"A www.example.com."`). Getting the order or the dot
  wrong produces a create/destroy pair rather than an import.
- **Coverage map**: the `ManagedZone` key claims the zone address; each
  recordset is its own CAI asset and claims its own address. Do not
  fold recordsets under the zone key — that hides a per-record gap
  behind a covered parent.
- **CAI surface trap**: `ResourceRecordSet` is a supported asset type
  for `gcloud asset list`, but it is "not available in the analysis
  APIs". `--verify-search-parity` compares against
  `search-all-resources`, so recordsets can be reported as
  `only_in_list`. That is the documented API taxonomy, not a collection
  bug — do not "fix" it by dropping the type.
- **Description default trap**: `modules/dns` defaults `description` to
  `"Terraform managed."` (with a space). FAST stages write
  `"Terraform-managed."` (with a hyphen), and live zones created by
  other tooling may carry anything at all. Mirror the live value
  explicitly; an unset `description` silently plans the module default
  over whatever is there.
- Lives in `project-<key>.tf`.

### Cloud Routers and NAT (`modules/net-cloudnat`) — verified r12

- Manifest: `compute.googleapis.com/Router`, `levels: [project]`.
- Addresses and import IDs: see the generated table.
- Inputs: `router_create = true`,
  `router_network = module.net_vpc_<key>.name`.
- **Carrier disambiguation — read before mapping any Router.**
  `compute.googleapis.com/Router` is the one CAI type in this cookbook
  that two modules legitimately create. A router whose only attached
  function is NAT belongs here. A router that terminates VPN tunnels is
  created by `modules/net-vpn-ha` and belongs in that section; mapping
  it here strands the tunnels, interfaces and BGP peers with no
  carrier. Decide from the live router's attachments, not its name.
- Coverage map: CAI models only `compute.googleapis.com/Router` (the NAT is a sub-resource with no independent CAI asset type). In `coverage-map.yaml`, the single router key claims both addresses: `[module.<nat_instance>.google_compute_router.router[0], module.<nat_instance>.google_compute_router_nat.nat]`.
- Lives in `project-<key>.tf`.

### Compute addresses (`modules/net-address`) — verified r19 (global PSC, global PSA, regional internal)

- Manifest: `compute.googleapis.com/Address`, `levels: [project]`.
- **CAI split-type note**: CAI's list surface types GLOBAL addresses as
  `compute.googleapis.com/GlobalAddress`; only the search surface
  unifies them under `.../Address`. `inventory.py` sweeps the sibling
  automatically and accounts it under the declared type — such entries
  carry `cai_list_type` in the inventory and worklist, and
  `_meta.split_type_sweeps` records the raw swept count. Do NOT declare
  `GlobalAddress` yourself unless you deliberately want it accounted as
  its own type. Run `--verify-search-parity` at least once per
  engagement (see `cai-blind-spots.md`).
- **Global PSC addresses** (`addressType: INTERNAL`,
  `purpose: PRIVATE_SERVICE_CONNECT`, `global/` in the self link):
  - Variable: `psc_addresses` with `region = null` (routes the entry
    through `local.global_psc`). The paired consumer forwarding rule is
    created only when `service_attachment != null`; an address-only
    entry is legitimate.
  - **Trap**: do NOT use `global_addresses` — it sets only
    name/description/ip_version and cannot express `address_type`,
    `purpose`, `network` or `address`, all ForceNew: the plan shows a
    destroy/create, which on an import is always a mapping error.
  - Address: `module.<instance>.google_compute_global_address.psc["<key>"]`;
    import ID `projects/<project_id>/global/addresses/<name>`.
  - **ForceNew trap — empty live description**: `psc_addresses.*.
    description` defaults to `"Terraform managed."`, and `description`
    is ForceNew on `google_compute_global_address`. A live address with
    an empty description must set `description = ""` explicitly or the
    plan shows a replacement.
- **Global PSA addresses** (`purpose: VPC_PEERING`):
  - Variable: `psa_addresses` with `address`, `network` and
    `prefix_length` mirrored to live values.
  - Address: `module.<instance>.google_compute_global_address.psa["<key>"]`;
    import ID `projects/<project_id>/global/addresses/<name>`.
- **Regional internal addresses** (`purpose: GCE_ENDPOINT` or
  `SHARED_LOADBALANCER_VIP`):
  - Variable: `internal_addresses` with `region`, `subnetwork` and
    `purpose` mirrored to live values.
  - Address: `module.<instance>.google_compute_address.internal["<key>"]`;
    import ID `projects/<project_id>/regions/<region>/addresses/<name>`.
- External, IPsec-interconnect and network-attachment variants:
  unverified (not exercised by the validation runs).
- **Reference rule**: `project_id = module.project_<key>.project_id`;
  networks via `module.net_vpc_<key>.self_link`.
- Lives in `project-<key>.tf`.

### Network Connectivity Center — hub, and spokes as a capability gap (r12)

- Manifest: `networkconnectivity.googleapis.com/Hub` and
  `networkconnectivity.googleapis.com/Spoke`, `levels: [project]`.
- **Hub**: `modules/ncc-spoke-ra` does carry the hub
  (`google_network_connectivity_hub.hub[0]`, created when
  `hub.create` is true), so a hub is NOT a capability gap. Import it
  into that module rather than raw.
- **Spoke capability gap**: `modules/ncc-spoke-ra` covers
  router-appliance spokes only
  (`google_network_connectivity_spoke.spoke_ra`, keyed on
  `linked_router_appliance_instances`). Linked-VPC and linked-VPN
  spokes have no Fabric carrier. Per the fallback doctrine these import
  as a raw `google_network_connectivity_spoke.<instance>` and MUST
  appear in the run report's capability-gaps section
  (upstream-Fabric-issue material). Revisit and lift with `moved {}`
  blocks if a module appears.
- Import IDs: see the generated table.
- `linked_vpc_network.uri = module.net_vpc_<key>.self_link`.
- Lives in `project-<key>.tf`.

### KMS keyrings, keys, and key IAM (`modules/kms`) — verified r13

- Manifest: `cloudkms.googleapis.com/KeyRing` and `cloudkms.googleapis.com/CryptoKey` (with `iam: true` for leaf-IAM opt-in).
- Module addresses:
  * KeyRing: `module.<instance>.google_kms_key_ring.default[0]`
  * CryptoKey: `module.<instance>.google_kms_crypto_key.default["<key_name>"]`
  * CryptoKey IAM: `module.<instance>.google_kms_crypto_key_iam_binding.authoritative["<key_name>.<role>"]`
- **Permanent residue caveat**: Keyrings and CryptoKeys cannot be destroyed in GCP once created (only CryptoKeyVersions can be destroyed). Seeded test keyrings remain permanently as disabled/empty shells in the project.
- **Reference rule**: `project_id = module.project_<key>.project_id`; IAM member emails reference managed SAs (e.g. `module.sa_<key>.iam_email`).
- Lives in `project-<key>.tf`.

### Certificate Authority Service (`modules/certificate-authority-service`) — verified r16 (CA pools)

- Manifest: `privateca.googleapis.com/CaPool` (validated CAI type string), `levels: [project]`.
- Module addresses:
  * CA Pool: `module.<instance>.google_privateca_ca_pool.default[0]` (verified r14, plan-converged r16)
  * CA Pool IAM: `module.<instance>.google_privateca_ca_pool_iam_binding.authoritative["<role>"]` (unverified)
  * Certificate Authority: `module.<instance>.google_privateca_certificate_authority.default["<ca_id>"]` (unverified)
- **Pool-only mapping trap**: The module `ca_configs` variable defaults to `{ test-ca = {} }`. When importing a pool without CAs, pass `ca_configs = {}` to avoid unwanted default CA creation.
- **ForceNew alignment**: `name`, `project_id`, `location`, `tier` (`enterprise_tier = false` for DevOps tier, `true` for Enterprise) must mirror live values.
- **Publishing options — verified r16 with Fabric ref ≥ `a153861aae` (upstream PR #4106 / issue #4106)**:
  GCP populates `publishing_options` on every pool (DevOps tier
  defaults: `encoding_format = "PEM"`, `publish_ca_cert = true`,
  `publish_crl = false`). **Minimum ref required**: support for
  `publishing_options` landed in #4106 and is NOT in any released tag as
  of r16 — verified against `a153861aae` (see D-07). On any earlier ref,
  including `v57.0.0`, adopting a live pool plans a **destructive
  removal** of the block: a capability gap, never benign drift, since an
  apply would reset live CA-certificate/CRL publication (D-07, D-08).
  There the only sanctioned options are the raw-resource fallback or
  leaving pools unmanaged. On a ref carrying the fix,
  `modules/certificate-authority-service` accepts an optional
  `publishing_options` object in `ca_pool_config.create_pool`. Mirror
  the live values explicitly:
  `publishing_options = { encoding_format = "PEM", publish_ca_cert = true, publish_crl = false }`.
  `publish_ca_cert` and `publish_crl` are REQUIRED when the block is present; `encoding_format` is optional and
  validated to `PEM|DER`. Adopting a live pool with explicit `publishing_options` converges cleanly with 0 residuals and 0 drift (verified r16).
- **Deletability**: Unlike KMS keyrings, CA pools are fully deletable when empty in GCP.
- **Reference rule**: `project_id = module.project_<key>.project_id`.
- Lives in `project-<key>.tf`.

### VPC Service Controls (`modules/vpc-sc`) — verified r15

- **Org-level singleton placement**: `AccessPolicy` is org-scoped (`parent = "organizations/<org_id>"`). In a single-root workspace layout, place `module "vpc_sc"` in `organization.tf` and import blocks in `organization-import.tf`.
- **Existing policy management vs create**: If adopting an existing live AccessPolicy, set `access_policy = null` and configure `access_policy_create = { parent = "organizations/<org_id>", title = "<live_title>" }` so the policy itself is imported at `module.<instance>.google_access_context_manager_access_policy.default[0]`.
- **Import ID formats**:
  - `google_access_context_manager_access_policy`: Requires bare numeric ID string `<policy_id>` (regex `^(?P<name>[^/]+)$`). Do NOT include `accessPolicies/` prefix (verified r15).
  - `google_access_context_manager_access_level`: `accessPolicies/<policy_id>/accessLevels/<name>` (or `<policy_id>/<name>`).
  - `google_access_context_manager_service_perimeter`: `accessPolicies/<policy_id>/servicePerimeters/<name>` (or `<policy_id>/<name>`).
- **Enforced vs Dry-Run (`status` vs `spec`)**:
  - Dry-run perimeters require `use_explicit_dry_run_spec = true` and the `spec = { ... }` block (verified r15).
  - Enforced perimeters use `status = { ... }` (with `use_explicit_dry_run_spec = false` or omitted). **Unverified** — r15 seeded a dry-run perimeter only, so the `status` surface has never been plan-tested. Treat it as C until a round exercises an enforced perimeter.
  - ForceNew / plan diff trap: Aligning `use_explicit_dry_run_spec` and `spec` vs `status` to match live state is required to prevent accidental enforcement or diffs. Getting this wrong on a live enforced perimeter would plan it into dry-run, silently disabling enforcement — check it before the first plan, not after.
- **Context cross-references**:
  - In `perimeters`, access level references can use `$access_levels:<key>` syntax (e.g. `$access_levels:my_level`), which the module expands to the full resource name `accessPolicies/<policy_id>/accessLevels/<key>`.
- **CAI Enumeration & Level Detection**:
  - CAI `gcloud asset list --content-type=resource` rejects ACM asset types (`identity.accesscontextmanager.googleapis.com/*`), requiring fallback to `gcloud asset search-all-resources`.
  - `asset_level()` in `inventory.py`: For `AccessLevel` and `ServicePerimeter`, `parentFullResourceName` is `//accesscontextmanager.googleapis.com/accessPolicies/<policy_id>`, which does not contain `/organizations/` or `/projects/`, classifying them as `unknown` level. `unknown` entries are ALWAYS retained in the denominator — `apply_level_filter()` never drops an entry classified `unknown`, whatever `levels` says. Listing `unknown` does change one thing: a type whose declared levels are otherwise disjoint from the scope's `levels` stays ACTIVE and is swept at all, so a type declared only at `unknown` needs `unknown` in the scope too or it is swept and then discarded (verified r15).

### VPC networks (`modules/net-vpc`) — verified r3/r9

- Module inputs to addresses: `subnets` →
  `subnetwork["<region>/<name>"]`; `subnets_proxy_only` →
  `proxy_only[...]`; `subnets_private_nat` → `private_nat[...]`;
  `routes = {<key> = {...}}` → `gateway["<key>"]` with route name
  `<net>-<key>`; `create_googleapis_routes` →
  `gateway["<name>-googleapis"]`.
- ForceNew description alignment: `description` is ForceNew on network
  and subnet resources, and the module supplies defaults that override
  live strings, planning delete/create. Set descriptions to the exact
  live values before the first plan (r9).
- `send_secondary_ip_range_if_empty`: the module hardcodes `true`; on
  imported subnets without secondary ranges the provider plans
  `null -> true`. Covered by a guarded benign rule (r9).
- **Routes — not importable, auto-excluded:** Subnet-local routes (`nextHopNetwork`)
  and NCC / peering routes (`nextHopHub`, `nextHopPeering`) are auto-generated
  by GCP and cannot be created via the Compute API (`routes.insert` rejects
  these next hops). `inventory.py` automatically filters them from the
  denominator; if present in an existing denominator, they must be waived.
  Confirmed present in live CAI `resource.data` payloads (`nextHopNetwork` for
  subnet-local routes, `nextHopHub` for NCC routes, `nextHopPeering` for VPC peering)
  so filtering is structural without requiring gcloud hydration fallbacks (verified r20).
- **Routes — importable, do import:** Default internet gateway routes
  (`0.0.0.0/0` -> `default-internet-gateway`, named `default-route-<hash>`)
  are legal `routes.insert` resources and must be imported via `net-vpc`'s
  `routes` map using an explicit `name`:
  ```hcl
  module "net_vpc_hub" {
    source     = "./modules/net-vpc"
    project_id = module.project_hub.project_id
    name       = "hub-0"
    delete_default_routes_on_create = false
    routes = {
      default = {
        name          = "default-route-<hash>"
        description   = "Default route to the Internet."
        dest_range    = "0.0.0.0/0"
        next_hop_type = "gateway"
        next_hop      = "default-internet-gateway"
        priority      = 1000
      }
    }
  }

  import {
    id = "projects/<project-id>/global/routes/default-route-<hash>"
    to = module.net_vpc_hub.google_compute_route.gateway["default"]
  }
  ```
  **Three traps to observe:**
  1. `description` must be the live string verbatim (`"Default route to the Internet."`). The module default is `"Terraform-managed."` and route attributes are ForceNew, so a mismatch plans a destroy/create of the default route.
  2. `delete_default_routes_on_create` must be `false` (the module default) in an imported workspace. It is create-only and never returned in state by the API; carrying `true` over from a FAST stage config plans a **VPC replacement**.
  3. The GCP-generated hash is frozen into config. If the VPC is ever recreated, GCP mints a new `default-route-<hash>` and the stale name is then *created* alongside it.
  *(Import mapping derived from module source and live route attributes; mark any unexercised live variations as unverified).*
- Reading `modules/net-vpc/{main,subnets,routes}.tf` gives exact
  `for_each` key formats; zero trial-and-error cycles were needed with
  the source open (r3).

### Tags (Resource Manager) — verified r18

- **Carrier Container Architecture**: Tags are not a standalone module in Fabric. They are carried inside container modules:
  - `modules/organization`: Org-level tag keys, tag values, tag IAM, and tag bindings attaching tags to the organization.
  - `modules/folder`: Folder tag bindings (`tag_bindings`).
  - `modules/project`: Project-level tag keys, tag values, tag IAM, and project tag bindings (`tag_bindings`).
- **`for_each` Key Shapes & Addresses**:
  - `google_tags_tag_key.default["<short_name>"]` (keyed by short name)
  - `google_tags_tag_value.default["<key_short_name>/<value_short_name>"]` (keyed by composite short names)
  - `google_tags_tag_binding.binding["<binding_key>"]` (keyed by user-specified map key in `tag_bindings`)
- **Import IDs**:
  - Tag Key: `tagKeys/<id>` (e.g. `tagKeys/123456789012`)
  - Tag Value: `tagValues/<id>` (e.g. `tagValues/567890123456`)
  - Tag Binding: `tagBindings/%2F%2Fcloudresourcemanager.googleapis.com%2F<parent_type>%2F<parent_id>/tagValues/<val_id>` (e.g. `tagBindings/%2F%2Fcloudresourcemanager.googleapis.com%2Ffolders%2F123456789012/tagValues/901234567890`)
- **Escaping Matrix Trap**:
  - In `modules/{organization,folder,project}/tags.tf`, `tag_bindings` passes `tag_value` through `templatestring(local._tag_bindings[each.key], var.context.tag_vars)`.
  - Per the escaping matrix, a literal `${` in that carrier must be written `$$${`. **Derived from module source, not exercised (r18)** — no value containing `${` was seeded, so treat the rule as reasoned rather than observed until a round proves it.
  - Scope of the trap: GCP restricts tag key and value short names to alphanumerics, hyphens, underscores and periods, so a literal `${` cannot appear in the `tagValues/<id>` reference itself. The risk lives in free-text fields and in `tag_vars` context values, not in the binding reference.
- **CAI Enumeration & Level Detection**:
  - CAI types: `cloudresourcemanager.googleapis.com/TagKey`, `cloudresourcemanager.googleapis.com/TagValue`, and `cloudresourcemanager.googleapis.com/TagBinding`.
  - `inventory.py`: `asset_level()` classifies `TagKey` and `TagValue` at `organization` level (via parent/ancestor markers). `TagBinding` is classified by its target attachment (`folder`, `project`, or `organization`).

### Workload Identity Federation (IAM) — verified r18

- **Carrier Architecture**: Managed inside `modules/project/identity-providers.tf` via `var.workload_identity_pools`.
- **`for_each` Key Shapes & Addresses**:
  - `google_iam_workload_identity_pool.default["<pool_id>"]`
  - `google_iam_workload_identity_pool_provider.default["<pool_id>/<provider_id>"]` (composite key `${pool_id}/${provider_id}`)
- **Import IDs**:
  - Pool: `projects/<project_id>/locations/global/workloadIdentityPools/<pool_id>`
  - Provider: `projects/<project_id>/locations/global/workloadIdentityPools/<pool_id>/providers/<provider_id>`
- **CAI Types**:
  - `iam.googleapis.com/WorkloadIdentityPool` (level: `project`)
  - `iam.googleapis.com/WorkloadIdentityPoolProvider` (level: `project`)
- **Org Policy Constraints & Traps**:
  - `constraints/iam.workloadIdentityPoolProviders`: Restricts allowed external identity provider issuer URLs.
  - Providers (such as GitHub Actions OIDC) require CEL `attribute_condition` referencing provider claims (e.g. `assertion.repository == '...'`).

### Privileged Access Manager (PAM)

- **Canonical Module**: `modules/organization`, `modules/folder`, `modules/project` via `pam_entitlements` map or `factories_config.pam_entitlements` factory path.
- **Resource Address**:
  - `module.<container>.google_privileged_access_manager_entitlement.default["<entitlement_id>"]`
- **Import ID Formats**:
  - Entitlement: `{{parent}}/locations/{{location}}/entitlements/{{entitlement_id}}` (e.g., `organizations/123/locations/global/entitlements/my-entitlement` or `projects/my-project/locations/global/entitlements/my-entitlement`)
- **CAI Types**:
  - `privilegedaccessmanager.googleapis.com/Entitlement` (levels: `organization`, `folder`, `project`)
  - `privilegedaccessmanager.googleapis.com/Grant`: Ephemeral runtime access requests generated upon JIT access activation. Excluded from survey and collection by default; retained only with `--include-pam-grants`.
- **Traps**:
  - Grants represent transient workflow state with short TTLs and should **not** be managed in Terraform baseline IaC.

### VPC firewall rules (`modules/net-vpc-firewall`)

- Manifest: `compute.googleapis.com/Firewall`, `levels: [project]`.
- **Carrier boundary**: `modules/net-vpc` deliberately does not manage
  firewall rules — that is a module-boundary decision, not an omission.
  `modules/net-vpc-firewall` is the carrier for legacy VPC firewall
  rules; `modules/net-firewall-policy` carries hierarchical and network
  firewall policies. They are different CAI types
  (`.../Firewall` vs `.../FirewallPolicy`) and never substitute for
  each other.
- Addresses and import IDs: see the generated table.
- **Five distinct addresses, not one.** The module emits custom rules
  under `google_compute_firewall.custom_rules["<rule_name>"]`
  (`for_each`, keyed on the rule name), *and* up to four `count`-based
  default rules from `default_rules_config`:
  `allow_admins[0]`, `allow_tag_http[0]`, `allow_tag_https[0]`,
  `allow_tag_ssh[0]`, named `<network_name>-ingress-admins`,
  `-ingress-tag-http`, `-ingress-tag-https` and `-ingress-tag-ssh`.
  A live estate that was built with FAST already has these. Match a
  live rule to the default-rule address when its name matches that
  pattern, and to `custom_rules` otherwise — routing a default rule
  through `custom_rules` plans a create/destroy pair against the same
  live name.
- **There is no `google_compute_firewall.rules` resource.** Verify the
  resource label against `modules/net-vpc-firewall/main.tf` and
  `default-rules.tf` before writing an import block.
- Inputs: `project_id`, `network`, and `custom_rules` (or
  `factories_config.rules_folder`).
- Lives in `project-<key>.tf`.

### DNS response policies (`modules/dns-response-policy`)

- Manifest: `dns.googleapis.com/ResponsePolicy` and, for rules,
  `dns.googleapis.com/ResponsePolicyRule`; `levels: [project]`.
  Rules are a separate CAI asset type, not a sub-resource — declare
  both or the rules never enter the denominator.
- Addresses and import IDs: see the generated table.
- **Input schema trap**: `networks` is `map(string)`
  (`name => self_link`), not a list of strings
  (`modules/dns-response-policy/variables.tf`).
- **CAI surface trap**: both types are "not available in the analysis
  APIs", so `--verify-search-parity` may report them as `only_in_list`.
  Expected; see the DNS zones section.
- Lives in `project-<key>.tf`.

### HA VPN and VPN tunnels (`modules/net-vpn-ha`)

- Manifest: `compute.googleapis.com/VpnGateway`,
  `compute.googleapis.com/ExternalVpnGateway`,
  `compute.googleapis.com/VpnTunnel` and
  `compute.googleapis.com/Router`; `levels: [project]`.
- Addresses and import IDs: see the generated table. Note the router
  interface import ID has **no** `projects/` prefix
  (`<project_id>/<region>/<router_name>/<interface_name>`) — it is the
  one irregular form in this family.
- **Carrier disambiguation**: this module creates its own
  `google_compute_router.router[0]`, so a VPN-terminating router is
  mapped here and NOT through `modules/net-cloudnat`. See the Cloud
  Routers and NAT section for the rule.
- **`shared_secret` cannot be imported, and cannot be waived.**
  - Provider constraint: `google_compute_vpn_tunnel.shared_secret` is
    `ForceNew`, and the Compute API returns only `shared_secret_hash`
    on read. An imported tunnel therefore holds no plaintext secret.
  - Fabric constraint: `modules/net-vpn-ha` sets
    `shared_secret = coalesce(each.value.shared_secret, local.secret)`
    where `local.secret` is `random_id.secret.b64_url`
    (`modules/net-vpn-ha/main.tf`). **You cannot leave it unset.**
    Omitting it does not produce a no-op — it produces an
    unknown-at-plan-time value on a ForceNew attribute, which plans a
    tunnel *replacement*, non-deterministically.
  - **A waiver does not help.** `verify_plan.py` classifies anything
    other than a clean import or a no-op — including `replace` — as
    RESIDUAL and fails. `benign-drift.yaml` covers cosmetic attribute
    diffs, not replacements. A run that "waives" a tunnel replacement
    is a run that would destroy a live tunnel on apply. Do not do this.
  - **Correct posture**: obtain the plaintext secret from the operator
    out of band and set it explicitly. It is the only way the module
    converges.
  - **When the secret is genuinely unavailable**, this is a module
    capability gap, and it is handled the way every other gap is: emit
    a raw `google_compute_vpn_tunnel` with
    `lifecycle { ignore_changes = [shared_secret] }`, and record it in
    the run report's capability-gaps section with that reason. This is
    a documented fallback, not a shortcut — and not the default.
- Lives in `project-<key>.tf`.

### Root module

- Emit `versions.tf` (terraform >= 1.5, google + google-beta
  `>= 7.40, < 8`, `backend "local"`) and the module wiring yourself;
  the gates cannot pass without them.
- Pin the Fabric ref to a released tag. If a needed feature is
  unreleased (custom-role metadata, D-01), surface the trade-off to the
  user instead of silently pinning a SHA.

## Fallback: module capability gaps (raw resources — the exception)

Raw `google_*` resources are permitted only when the canonical module
cannot express a required attribute of the live resource, or no module
covers the type. Check the module source first; "faster" is not a
reason. Procedure:

1. Emit only the import block (address in root module namespace,
   deterministic name), with the id from the CAI-name heuristic above.
2. `terraform plan -generate-config-out=generated-<type>.tf` — the
   generated HCL is provider-faithful by construction.
3. Review, move into the owning project's file, re-plan to a clean
   import.
4. Record the mapping in `coverage-map.yaml`; list the resource in the
   report's module capability gaps section: which module was evaluated,
   which attribute (or whole type) it cannot express, and whether that
   is upstream-Fabric-issue material.

Fabricization is the default, not polish. Raw clusters accepted under a
capability gap are debt: when the gap closes upstream, lift them into
their canonical module — verifying the module's address surface against
the in-repo source, and with `moved {}` blocks if state already exists.

### Optional accelerator: `gcloud beta resource-config bulk-export`

For large fallback scopes, Google's Config-Connector-based exporter can
draft HCL and import IDs in bulk (evaluated live, r5):

```bash
gcloud beta resource-config bulk-export --project=P \
  --resource-types=ComputeFirewall,ComputeInstance \
  --resource-format=terraform --path=draft/ --on-error=halt
gcloud beta resource-config terraform generate-import draft/
```

- Always `--on-error=halt`: the default `ignore` silently skips
  unexportable resources — the exact silent-gap failure this skill
  exists to prevent. Never let its output define scope.
- Coverage is Config-Connector-bounded: 81 of 264 types (30.7%).
  Org-level governance (org policies v2, custom constraints, org IAM)
  is unsupported and org-level sinks crash the converter. The
  denominator must remain `inventory.py`.
- Where it works (project infrastructure), the HCL is clean and the
  `generate-import` IDs matched the CAI-name heuristic 100%
  byte-for-byte — useful as an independent import-ID oracle.
- Draft only, gates unchanged: treat its HCL like
  `-generate-config-out` output; the KRM round-trip is not the pinned
  provider schema and the plan gate is the truth.
- Prerequisites are heavy: `config-connector` component, Cloud Asset
  API enabled, service-agent roles.
- Verdict: not a foundation on-ramp; optional accelerator and oracle
  for project infrastructure.
