---
name: fabric-importer
description: Reverse-engineers live GCP resources into Cloud Foundation Fabric Terraform modules with native import blocks, driven by an agreed import manifest and verified by automated completeness and plan-convergence gates. Use when migrating or importing existing GCP infrastructure into Cloud Foundation Fabric or Terraform.
---

# Fabric Importer — agent protocol

You (the agent) reverse-engineer live GCP resources into Cloud Foundation
Fabric Terraform. There is no per-resource pipeline: **you perform the
mapping yourself**, guided by the cookbook, and two frozen gates verify
your output. Trust comes from the gates, not from you.

## Trust boundary (non-negotiable)

- **Frozen scripts** (`scripts/`): `inventory.py`, `coverage.py`,
  `verify_plan.py`, `benign-drift.yaml`, `manifest_init.py`,
  `integrity.py`. You may RUN them; you must NEVER modify them or their
  rulesets. Both gates print runtime provenance and active input hashes;
  a reviewer compares them against a clean checkout. If a gate is
  genuinely broken, report it with evidence — do not patch around it.
- **Human-owned files**: the import manifest and the waiver ledger. You
  may draft or propose changes; a human reviews and commits them.
- **Yours**: everything in the workspace (`tf/`, `coverage-map.yaml`,
  reports). Constraint: once an address exists, it is immutable — extend,
  never rewrite (see "Incremental runs").

## Safety contract

1. **NEVER run `terraform apply`.** Generated authoritative IAM makes an
   apply equivalent to overwriting live IAM with a snapshot. Verification
   is plan-only via `verify_plan.py`. Never synthesize state files.
2. **Read-only against GCP**: `list`/`describe`/`get-iam-policy`/asset
   export only. Prefer a dedicated read-only identity
   (`roles/cloudasset.viewer` + per-service viewers, via impersonation)
   so an accidental apply fails with 403.
3. **All workspace output is org-confidential.** Never commit it; never
   quote principals/IDs in documents that leave the engagement.
4. **Never rationalize a residual diff.** If you believe a plan diff is a
   provider artifact, propose a `benign-drift.yaml` entry with evidence in
   your report and stop. A human accepts it or the run stays red.

## Human-in-the-Loop Gates

Gate on steps that are hard to reverse, costly, or where human judgment is required (e.g. narrowing scope, waiving assets, or accepting provider drift). Keep mechanical, reversible steps (asset collection, scaffolding, linting, plan checks) autonomous. Gates are **blocking**: if running non-interactively and confirmation cannot be obtained, stop — never assume approval.

| Gate | When | What the human decides |
| :--- | :--- | :--- |
| **Scope Approval** | End of Step 0 (Manifest Drafting) | Reviews and commits `import-manifest.yaml`: which resource types, hierarchy levels (org/folder/project), and included/excluded subtrees are in scope. |
| **Waiver Signing** | Step 4 (Completeness Gate) | Reviews deliberate exclusions in `waivers.yaml` and signs them with attribution (`signed_by`) for unmanaged or auto-generated resources (e.g. default log sinks, default compute service accounts). |
| **Benign Drift Review** | Step 5 (Plan Convergence Gate) | Evaluates proposed cosmetic provider quirks (e.g. computed labels, default timeouts) and commits reviewed entries to `scripts/benign-drift.yaml`. |
| **Final Review & Apply** | Step 6 (Handover) | Inspects the final zero-drift plan, run report, and input provenance digests before running `terraform apply` on their own schedule. |

---

## Step-by-Step Workflow

```mermaid
flowchart TD
    subgraph S0["Step 0: Discovery & Scope Declaration"]
        MA["<b>Mode A: State-Driven Inference</b><br/><code>manifest_from_state.py</code><br/><i>(Existing .tfstate files)</i>"]
        MB["<b>Mode B: Live Cloud Survey</b><br/><code>inventory.py survey</code> &amp;<br/><code>manifest_init.py</code><br/><i>(Untracked brownfield)</i>"]
        Draft["Draft <code>import-manifest.yaml</code><br/><i>(Resource types, levels &amp; subtree filters)</i>"]
        G_Scope{"<b>Gate: Scope Approval</b><br/>Human reviews &amp; commits manifest"}
        Stop_Scope["Stop / Re-scope"]
    end

    subgraph S1["Step 1: Inventory Enumeration"]
        Collect["<b>CAI &amp; API Enumeration</b><br/><code>inventory.py collect</code>"]
        InvFile[("<b>Frozen Denominator</b><br/><code>inventory.json</code>")]
    end

    subgraph S2["Step 2: Canonical Scaffolding &amp; Mapping"]
        Worklist["<b>Compute Delta Worklist</b><br/><code>coverage.py --worklist-out</code>"]
        Emit["<b>Agent Emits Terraform &amp; Mappings</b><br/>• Canonical Fabric Module calls<br/>• Native <code>import {}</code> blocks<br/>• <code>tf/coverage-map.yaml</code>"]
    end

    subgraph S3["Step 3: Completeness Gate (Gate 1)"]
        Gate1{"<b>Gate 1: Completeness</b><br/><code>coverage.py --require-signed-waivers</code><br/><i>Every asset mapped or waived?</i>"}
        GWaiver{"<b>Gate: Waiver Signing</b><br/>Human signs deliberate exclusion<br/>in <code>waivers.yaml</code>"}
    end

    subgraph S4["Step 4: Plan Convergence Gate (Gate 2)"]
        PlanExec["<b>Plan &amp; Drift Evaluation</b><br/><code>terraform plan</code> &amp;<br/><code>verify_plan.py</code>"]
        Gate2{"<b>Gate 2: Plan Convergence</b><br/><i>Zero unexpected changes?<br/>(Only clean imports &amp; no-ops)</i>"}
        GDrift{"<b>Gate: Benign Drift Review</b><br/>Human accepts verified provider quirk<br/>in <code>benign-drift.yaml</code>"}
    end

    subgraph S5["Step 5: Output &amp; Handover"]
        Report["<b>Generate Run Report</b><br/>Audit trail, capability gaps &amp;<br/>gate input SHA256 digests"]
        GApply{"<b>Gate: Apply Sign-off</b><br/>Human operator reviews plan"}
        Workspace(["<b>Zero-Drift Production Fabric Workspace</b><br/><code>tf/</code> ready for <code>terraform apply</code>"])
    end

    %% Flow connections
    MA --> Draft
    MB --> Draft
    Draft --> G_Scope
    G_Scope -->|Human Rejects| Stop_Scope
    G_Scope -->|Human Approves &amp; Commits| Collect

    Collect --> InvFile
    InvFile --> Worklist
    Worklist --> Emit
    Emit --> Gate1

    %% Gate 1 loops
    Gate1 -->|Missing / Unmapped Assets| GWaiver
    GWaiver -->|Sign Waiver (signed_by)| Gate1
    GWaiver -->|In-Scope Resource| Emit
    Gate1 -->|100% Covered (Exit 0)| PlanExec

    %% Gate 2 loops
    PlanExec --> Gate2
    Gate2 -->|Residual Diff / Attribute Mismatch| GDrift
    GDrift -->|Fix HCL / Module Inputs / ForceNew| Emit
    GDrift -->|Accept Quirk (Review &amp; Commit)| Gate2
    Gate2 -->|Zero Drift (Exit 0)| Report

    %% Final Step
    Report --> GApply
    GApply -->|Reviewed &amp; Approved| Workspace

    %% Styling & Classes
    classDef gate fill:#fff3e0,stroke:#e65100,stroke-width:2px,color:#e65100;
    classDef step fill:#e8f0fe,stroke:#1a73e8,stroke-width:2px,color:#1a73e8;
    classDef file fill:#f1f8e9,stroke:#33691e,stroke-width:2px,color:#33691e;
    classDef terminal fill:#fce8e6,stroke:#c5221f,stroke-width:2px,color:#c5221f;
    classDef success fill:#e6f4ea,stroke:#137333,stroke-width:3px,color:#137333;

    class G_Scope,GWaiver,Gate1,Gate2,GDrift,GApply gate;
    class MA,MB,Draft,Collect,Worklist,Emit,PlanExec,Report step;
    class InvFile file;
    class Stop_Scope terminal;
    class Workspace success;
```

---

## Operational Workflow

### Step 0 — establish the manifest (with the user)

The manifest is the user's contract: which resource types, at which
levels, under which subtrees. Never invent it silently. If one exists,
confirm it; otherwise run one of the drafting workflows:

**Option A — Inferred from existing Terraform state(s)** (preferred when migrating existing TF):

```bash
python3 scripts/manifest_from_state.py --state <state-files...> --out import-manifest.yaml
```

See [references/inferring-manifests-from-state.md](./references/inferring-manifests-from-state.md).

**Option B — Surveyed from live GCP estate**:

```bash
python3 scripts/inventory.py survey --scope organizations/ORG_ID --out survey.json
python3 scripts/manifest_init.py --survey survey.json \
  --scope organizations/ORG_ID --out import-manifest.yaml
```

Then interview the user over the draft (every discovered type is listed
with per-level counts, commented out; foundation types are pre-enabled):

- What do you want under Terraform management *now*? (Start narrow —
  org foundation first, workloads later. Show them
  `examples/import-manifest.org-foundation.yaml` as the reference.)
- At which levels? (e.g. org IAM yes, project IAM no.)
- Any subtrees to exclude (sandboxes, decommissioning trees)?

When writing `scope.include`/`scope.exclude`, note that CAI `ancestors`
store NUMERIC project numbers; `inventory.py` automatically resolves
alphanumeric project IDs to numbers during enumeration, but project numbers
remain supported and canonical.

The user commits the manifest. Scope changes later = manifest edit +
incremental re-run, never a rewrite.

### Step 1 — enumerate (the denominator)

```bash
python3 scripts/inventory.py collect --manifest import-manifest.yaml --out inventory.json
```

### Step 2 — get your worklist

```bash
python3 scripts/coverage.py --inventory inventory.json --workspace tf \
  --waivers waivers.yaml --worklist-out worklist.yaml
```

First run: everything is missing. Re-runs: only the delta.

### Step 3 — map and emit (your job)

**Fabric modules are the product, not an optimization.** Every resource
maps to its canonical Fabric module (the cookbook's "Canonical module
map" is normative): `modules/organization` for everything org-level,
one `modules/folder` instance per folder, one `modules/project`
instance per project — each carrying its own IAM, org policies, and
sinks. Do NOT use `project-factory` for imports: per-instance modules
give stable, chosen addresses.

For each worklist entry, emit module config (factory YAML or module
inputs, per the cookbook) + a paired import block targeting the
module-internal address, maintaining `tf/coverage-map.yaml`
(inventory key → list of Terraform addresses). Read
`references/mapping-cookbook.md` FIRST: it encodes the hard-won rules
(escaping, import-ID formats, coalesce traps, dry-run keys, hashed
condition keys).

When the cookbook has no section for a type — which is the normal case,
not an error — follow the method below. The cookbook is the precipitate
of that method, not a precondition for it.

**Raw `google_*` resources are the exception, never a shortcut.**
Permitted only when (a) the canonical module cannot express a required
attribute of the live resource (a *module capability gap*), or (b) no
Fabric module covers the type at all. Every raw resource MUST appear in
the step-5 report's "module capability gaps" section with the concrete
reason. For drafting raw config,
`terraform plan -generate-config-out=generated.tf` is provider-faithful
by construction — but it is an inspection technique, not a mapping
tier.

Read the Fabric module source **in this repository** before targeting
module-internal addresses; do not trust memory. Root-module wiring
(`versions.tf`, provider config, module blocks) is part of your output.

Three cookbook sections are normative for HOW you emit: **Workspace
layout** (one file per CONTAINER; project-contained resources live in
their project's file; hierarchical `data/` keyed by instance keys),
**The reference rule** (managed resources are referenced via module
outputs, never literals), and **Scaffolding scripts** (run-local
generators are fine — parameterized, cookbook-conformant, deterministic,
never promoted into the skill).

### Step 3b — when the cookbook has never seen this type

The cookbook will never be comprehensive, and it is not meant to be. It
is the accumulated residue of running this loop against real resources;
every entry in it was produced this way. Meeting an undocumented type is
routine — apply the same method, at the same standard of evidence.

What makes that safe is division of labour. **The gates make the method
safe**: you cannot take a wrong mapping to green, because a bad import
ID errors, a mismatched attribute stays residual, and an unmapped asset
fails coverage. **The cookbook makes it cheap and correctly diagnosed**:
it is the difference between converging on the first attempt and the
third, and — more importantly — between identifying a diff's cause and
confidently misreading it. The gates cannot catch a misdiagnosis, because
classifying a diff as benign is a human judgement they delegate. Do not
treat an absent cookbook section as licence to reason loosely.

The loop:

1. **Census the type.** Confirm the CAI asset-type string against live
   `gcloud asset list` output before trusting it. Type strings taken
   from module knowledge have been wrong before. Record what CAI
   actually returns, including which enumeration path had to be used.
2. **Find the module and read its source.** Canonical module map first,
   then `modules/` in this repository. Read the resource blocks for
   addresses and `for_each` key formats, and the variables file for the
   input shape. Never work from memory about module internals.
3. **Mirror ForceNew inputs to live values BEFORE the first plan.**
   Check which inputs are ForceNew on the underlying resource and set
   them to exactly what is live. A destroy/create pair on an imported
   resource is always a mapping error, never an acceptable outcome.
4. **Emit, plan, and read the result.** The plan is the oracle. A wrong
   import ID fails loudly and safely; a wrong attribute shows up as a
   diff. This step is cheap — use it rather than deliberating.
5. **Diagnose every diff before classifying it**, in this order:
   - Read the module's variable TYPE. Terraform silently discards
     attributes a variable type does not declare — no error, `validate`
     returns Success — so a field you believe you set may never have
     reached the resource.
   - Check whether the field is assigned directly or wrapped in
     `coalesce()`. Directly assigned fields accept `null` and need no
     rule; `coalesce` fields cannot express "empty" at all.
   - Check the escaping matrix if the value passes through
     `templatestring()`.
   Only after those does the question "is this benign?" become
   answerable.
6. **Land on one of three outcomes — all legitimate:**
   - *Clean convergence.* The module expresses the live resource.
   - *Module capability gap.* The module exists but cannot express an
     attribute that changes how the resource behaves. Emit a raw
     resource mirroring the live values, name it in the report's module
     capability gaps section with the module evaluated and the attribute
     missing, and treat it as upstream-Fabric-issue material. This is a
     successful outcome, not a failure.
   - *No module covers the type.* Same as above, plus note whether a
     module is worth proposing upstream.
   A residual you cannot explain is none of these. Report it and stop —
   never rationalise it into green.
7. **Write the cookbook entry as part of your report.** A type you
   mapped and verified is knowledge the next engagement should not have
   to rediscover: the CAI type string, the module addresses and
   `for_each` key formats, the import ID, the ForceNew inputs, and every
   trap that cost you a cycle. Mark surfaces you did not exercise as
   unverified. This step is what makes the tool compound instead of
   resetting to zero on every engagement — without it, the same traps
   are paid for repeatedly.

### Step 4 — run the gates

```bash
terraform -chdir=tf fmt -recursive   # generated code is ALWAYS fmt-ed
python3 scripts/coverage.py --inventory inventory.json --workspace tf \
  --waivers waivers.yaml --require-signed-waivers
terraform -chdir=tf init -input=false
terraform -chdir=tf plan -input=false -detailed-exitcode -out=verify.tfplan
terraform -chdir=tf show -json verify.tfplan | python3 scripts/verify_plan.py
```

`--require-signed-waivers` is the default posture: every waiver must
carry a `signed_by` recording the human who accepted it. Drop the flag
only in a fully unattended run, and say so in the report.

Iterate step 3 until **both** gates are green. Convergence =
coverage reconciled ∧ every plan change is a clean import, no-op, or
reviewed-benign.

### Step 5 — report

Produce a run report for the user: what was imported (counts by type,
with the Fabric module used for each), a **module capability gaps**
section — every raw resource emitted, which module fell short, which
attribute, and whether it is upstream-Fabric-issue material — plus
benign diffs relied on, waivers in effect, proposed waivers/benign rules
awaiting human review, and anything the manifest excludes that you
believe deserves attention. Plain facts; no "100%" claims beyond what the
gates literally verified.

The report MUST include the verbatim stdout of both final gate runs —
including the provenance stamp and every `input … sha256:` line.
Those lines are what lets a reviewer tie the verdict to the exact tool
build and the exact inputs; a report that paraphrases the gates instead
of quoting them is not evidence.

## Incremental runs

- The workspace persists. `coverage.py`'s worklist is the only to-do
  list; touch nothing that is already mapped.
- Commit `.terraform.lock.hcl` in the (user-owned, private) workspace
  repo: convergence verdicts are only reproducible against the exact
  provider build that produced them.
- Existing Terraform addresses and `coverage-map.yaml` entries are
  immutable. If a mapping must genuinely change (e.g. folder renamed),
  emit `moved {}` blocks and flag it prominently in the report.
- Manifest NARROWING fails closed: `coverage.py` flags now-out-of-scope
  mapped keys as `stale?` problems and exits 2. Resolution is a human
  decision: re-widen the manifest, sign waivers, or deliberately retire
  the mappings (remove config + import blocks + coverage-map entries in
  one reviewed commit) — never silently.
- Manifest widening only ever adds worklist entries; it never invalidates
  existing mappings.

## Prerequisites

`terraform` >= 1.5, `gcloud`, `python3` + PyYAML. Discovery IAM — the
read-only grant on the scope root (same table as the README):

- `roles/viewer`
- `roles/resourcemanager.organizationViewer`
- `roles/resourcemanager.folderViewer`
- `roles/iam.securityReviewer`
- `roles/orgpolicy.policyViewer`
- `roles/cloudasset.viewer`
- `roles/accesscontextmanager.policyReader` (when VPC-SC is in scope)

This covers org foundation, folders, projects, networking, and storage;
families verified later (KMS, CAS, VPC-SC, BigQuery, Pub/Sub, Tags, WIF)
may need additional per-service viewer roles — the plan gate names the
missing permission when one is needed.

## References

- [README.md](./README.md) — human user guide and architecture overview
- [COVERAGE.md](./COVERAGE.md) — resource maturity matrix
- [references/mapping-cookbook.md](./references/mapping-cookbook.md) —
  Fabric mapping rules, escaping, import-ID table, known traps
- [references/inferring-manifests-from-state.md](./references/inferring-manifests-from-state.md)
  — inferring import manifests from existing Terraform states
- [references/cai-blind-spots.md](./references/cai-blind-spots.md) —
  where the CAI denominator is incomplete and what to do about it
- [references/operating-contract.md](./references/operating-contract.md)
  — invariants and trust boundaries in full
