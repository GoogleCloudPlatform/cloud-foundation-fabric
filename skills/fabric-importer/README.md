# fabric-importer

`fabric-importer` reverse-engineers an existing Google Cloud organization into Cloud Foundation Fabric Terraform modules with native `import` blocks. An AI agent generates the module mapping; a set of frozen verification scripts proves the result is complete, attribute-accurate, and plan-converged. It never modifies anything in your live cloud environment.

Start with the document for your role:

- **Human Operator / Requesting an Import**: Follow this guide below.
- **AI Agent Performing the Work**: Follow [SKILL.md](./SKILL.md).
- **Supported Resources & Maturity**: See the [Maturity Matrix](./COVERAGE.md).

---

## The Design in One Paragraph

Most infrastructure importers rely on brittle per-resource generator pipelines that quickly grow stale. This skill inverts that model: the AI agent inspects the live inventory and Fabric module sources directly, then emits idiomatic Fabric module calls paired with native Terraform 1.5+ `import {}` blocks. Two frozen verification gates validate the output. This is sound because every mistake is immediately visible: a missing attribute or schema mismatch causes `terraform plan` to propose unexpected changes, and a missed resource is flagged during inventory reconciliation. Verification per run replaces trust in generator code.

---

## Human-in-the-Loop Gates

Gate on steps that are hard to reverse, costly, or where human judgment is required (e.g. narrowing scope, waiving assets, or accepting provider drift). Keep mechanical, reversible steps (asset collection, scaffolding, linting, plan checks) autonomous. Gates are **blocking**: if running non-interactively and confirmation cannot be obtained, stop — never assume approval.

| Gate | When | What the human decides |
| :--- | :--- | :--- |
| **Scope Approval** | Manifest drafting, before any enumeration | Reviews and commits `import-manifest.yaml`: which resource types, hierarchy levels (org/folder/project), and included/excluded subtrees are in scope. |
| **Waiver Signing** | Completeness Gate (`coverage.py`) | Reviews deliberate exclusions in `waivers.yaml` and signs them with attribution (`signed_by`) for unmanaged or auto-generated resources (e.g. default log sinks, default compute service accounts). |
| **Benign Drift Review** | Plan Convergence Gate (`verify_plan.py`) | Evaluates proposed cosmetic provider quirks (e.g. computed labels, default timeouts) and commits reviewed entries to `scripts/benign-drift.yaml`. |
| **Final Review & Apply** | Handover, before `terraform apply` | Inspects the final zero-drift plan, run report, and input provenance digests before running `terraform apply` on their own schedule. |

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

### Terminal / ASCII Workflow Alternative

```text
  [Mode A: Existing .tfstate]         [Mode B: Untracked Brownfield]
  (manifest_from_state.py)             (inventory.py survey + manifest_init.py)
              │                                      │
              └──────────────────┬───────────────────┘
                                 ▼
                     Draft import-manifest.yaml
                                 │
                     ┌───────────▼────────────┐
                     │  GATE: Scope Approval  │◄── Human reviews & commits
                     └───────────┬────────────┘
                                 │ Approved
                                 ▼
           Step 1: inventory.py collect ──► inventory.json (Frozen Denominator)
                                 │
                                 ▼
           Step 2: coverage.py --worklist-out ──► worklist.yaml
                                 │
           ┌─────────────────────┴────────────────────────────────┐
           ▼                                                      ▼
     Agent Scaffolding & Mapping                       GATE: Waiver Signing
     • Canonical Fabric Modules (tf/*.tf)              (Human signs waivers.yaml
     • Paired native import {} blocks                   for deliberate exclusions)
     • tf/coverage-map.yaml                                       │
           │                                                      │
           └─────────────────────┬────────────────────────────────┘
                                 ▼
           Step 3: GATE 1: Completeness (coverage.py)
                   [Missing / Unmapped Assets?] ──► (Loop back to Step 2)
                                 │ 100% Reconciled (Exit 0)
                                 ▼
           Step 4: terraform plan & verify_plan.py
                                 │
                   GATE 2: Plan Convergence
                   [Residual Diffs / Attribute Mismatch?]
                         │                  │
                         ▼                  ▼
                 Fix HCL / Inputs     GATE: Benign Drift Review
                 (Loop back to S2)    (Human accepts quirk in benign-drift.yaml)
                                 │
                                 │ Zero Residual Drift (Exit 0)
                                 ▼
           Step 5: Run Report (Provenance & Input SHA256 Hashes)
                                 │
                     ┌───────────▼────────────┐
                     │ GATE: Apply Sign-Off   │◄── Human Operator
                     └───────────┬────────────┘
                                 ▼
           Output: Zero-Drift Production Fabric Workspace (tf/)
```

---

## Step-by-Step Operator Guide

### 1. Declare the Scope (`import-manifest.yaml`)
You and the agent agree on an `import-manifest.yaml` declaring which resource types to import (e.g., folders, service accounts, VPC networks, org policies), at which container levels (organization, folder, or project), and which subtrees to include or exclude.

**Option A — Inferred from existing Terraform state(s):**
```bash
python3 scripts/manifest_from_state.py --state <state-files...> --out import-manifest.yaml
```
See [references/inferring-manifests-from-state.md](./references/inferring-manifests-from-state.md).

**Option B — Surveyed from live GCP estate:**
```bash
python3 scripts/inventory.py survey --scope organizations/ORG_ID --out survey.json
python3 scripts/manifest_init.py --survey survey.json --scope organizations/ORG_ID --out import-manifest.yaml
```
Ready-made examples aligned with FAST stages are provided in [`examples/`](./examples/).

### 2. Enumerate the Denominator (`inventory.json`)
The enumeration script queries Cloud Asset Inventory (CAI) and service APIs to construct the exact denominator of all matching live assets:
```bash
python3 scripts/inventory.py collect --manifest import-manifest.yaml --out inventory.json
```

### 3. Compute Delta Worklist
The completeness tool reconciles the denominator against any existing code and written waivers:
```bash
python3 scripts/coverage.py --inventory inventory.json --workspace tf \
  --waivers waivers.yaml --worklist-out worklist.yaml
```

### 4. Agent Maps & Emits Terraform
For each item in `worklist.yaml`, the agent writes:
1. Canonical Fabric module configuration matching the live state.
2. A paired Terraform `import {}` block:
   ```hcl
   import {
     to = module.folder-team-a.google_folder.folder[0]
     id = "folders/123456789012"
   }
   ```
3. A ledger entry in `coverage-map.yaml` linking the asset to its Terraform address.

### 5. Automated Verification (Definition of Done)
Work is complete only when two independent gates pass with exit code `0`:
- **Completeness Gate (`coverage.py`)**: Reconciles the inventory against `coverage-map.yaml`, `waivers.yaml`, and emitted `import {}` blocks. Every asset must be mapped or waived.
- **Plan Convergence Gate (`verify_plan.py`)**: Consumes `terraform show -json <planfile>` output (file argument or stdin) and classifies the planned actions. It never invokes Terraform itself. The plan may only contain clean imports, no-ops, and human-reviewed benign drift entries from `scripts/benign-drift.yaml`. Any residual attribute modification or destruction fails the gate.

Run both gates like this:

```bash
terraform -chdir=tf fmt -recursive
python3 scripts/coverage.py --inventory inventory.json --workspace tf \
  --waivers waivers.yaml --require-signed-waivers
terraform -chdir=tf init -input=false
rm -f tf/verify.tfplan   # a stale plan must never answer for a failed one
terraform -chdir=tf plan -input=false -out=verify.tfplan
terraform -chdir=tf show -json verify.tfplan | python3 scripts/verify_plan.py
```

Do not add `-detailed-exitcode` to the plan: it returns 2 for any
non-empty plan, and a converged import plan is always non-empty.
`verify_plan.py` is the verdict.

### 6. Review and Apply
The resulting workspace (`tf/`) is clean, formatted, and ready for you to review and run `terraform apply` at your own pace. The skill **never** runs `terraform apply` or mutates live cloud resources.

---

## Script reference

Run every script from the skill directory. All output paths are relative
to the current working directory.

| Script | Purpose | Flags |
|---|---|---|
| `inventory.py survey` | Enumerate everything in scope, to draft a manifest from | `--scope` (required), `--out` |
| `manifest_init.py` | Draft a manifest from a survey (Mode B) | `--survey` (required), `--scope` (required), `--out` |
| `manifest_from_state.py` | Infer a manifest from existing `.tfstate` (Mode A) | `--state` (1+, required), `--out` (`-` for stdout), `--force` to overwrite an existing manifest |
| `inventory.py collect` | Build the denominator from CAI | `--manifest` (required), `--out` |
| `coverage.py` | Gate 1 — completeness | `--inventory` (required), `--workspace` (required), `--coverage-map`, `--waivers`, `--require-signed-waivers`, `--allow-empty-inventory`, `--worklist-out` |
| `verify_plan.py` | Gate 2 — plan convergence | positional plan JSON (default stdin), `--rules`, `--allow-empty-plan` |
| `integrity.py` | Print the frozen-tools provenance digest | `--verbose` for per-file digests |

`inventory.py` requires the `survey` or `collect` subcommand; it has no
top-level flags.

Exit codes — `coverage.py`: `0` reconciled, `1` malformed input, `2` gaps
or problems. `verify_plan.py`: `0` converged, `1` malformed input, `2`
residual changes, `3` converged but ADVISORY (a substituted `--rules`
file). A substituted ruleset can never exit `0`; a residual plan still
exits `2`. Note that argparse usage errors also exit `2`, so read the
message, not only the code.

There is no checked-in expected digest. To check a recorded gate run,
compute `python3 scripts/integrity.py` from a pristine checkout of the
same commit and compare it with the `frozen tools:` line in the captured
output.

---

## Prerequisites & Permissions

### System Requirements
- **Terraform**: `v1.5.0+` (required for native `import {}` blocks).
- **Google Cloud SDK (`gcloud`)**: Authenticated with a configured quota project.
- **Python**: `3.9+` (the scripts use `str.removeprefix`) with `PyYAML`.

### Minimal Read-Only IAM Permissions
Run the import using a dedicated read-only identity. The following roles on the organization scope provide full read visibility:

| Role | Purpose |
|---|---|
| `roles/cloudasset.viewer` | CAI asset inventory enumeration across the hierarchy |
| `roles/resourcemanager.organizationViewer` | Organization resource details |
| `roles/resourcemanager.folderViewer` | Folder hierarchy discovery |
| `roles/viewer` | Read-only inspection of imported resources via service APIs |
| `roles/iam.securityReviewer` | IAM policy discovery at organization, folder, and project levels |
| `roles/orgpolicy.policyViewer` | Organization policy evaluation |
| `roles/accesscontextmanager.policyReader` | VPC Service Controls discovery (when VPC-SC is in scope) |

No write or admin permissions are required.

---

## User Ownership Boundary

Three human-owned files govern the process. The agent may propose edits, but only you commit them:

| File | Purpose |
|---|---|
| `import-manifest.yaml` | Declares in-scope resource types, container levels, and subtree filters. |
| `waivers.yaml` | Written waivers for resources deliberately excluded from management (e.g. `_Default` log sinks, default compute service accounts). Requires a `signed_by` attribute. |
| `scripts/benign-drift.yaml` | Scoped provider quirks accepted as cosmetic diffs (e.g., computed provider labels or default timeouts). |

---

## Repository Layout

```text
skills/fabric-importer/
├── SKILL.md                     # Agent protocol and operational contract
├── README.md                    # Human operator guide and architecture overview
├── COVERAGE.md                  # Resource family maturity matrix (N / C / V)
├── scripts/                     # Verification gates and helper utilities
│   ├── inventory.py             #   Asset enumeration (CAI + API sweeps)
│   ├── coverage.py              #   Completeness gate & delta worklist generator
│   ├── verify_plan.py           #   Plan-convergence gate (benign-drift aware)
│   ├── manifest_from_state.py   #   Terraform state-driven manifest inference
│   ├── manifest_init.py         #   Starter manifest drafting assistant
│   ├── integrity.py             #   Input binding & runtime provenance stamping
│   └── benign-drift.yaml        #   Human-reviewed provider quirk ruleset
├── examples/                    # Manifest and waiver templates
│   ├── import-manifest.org-foundation.yaml
│   ├── import-manifest.fast-org-setup.yaml
│   ├── import-manifest.fast-security.yaml
│   ├── import-manifest.fast-vpcsc.yaml
│   ├── import-manifest.fast-networking.yaml
│   └── waivers.example.yaml
├── references/                  # Normative mapping rules & technical gotchas
│   ├── mapping-cookbook.md      #   Module map, escaping rules, import IDs
│   ├── inferring-manifests-from-state.md # State-driven manifest inference workflow
│   ├── cai-blind-spots.md       #   Known CAI gaps and service API mitigations
│   └── operating-contract.md    #   Safety invariants and trust boundaries
└── tests/                       # Unit test suite
```
