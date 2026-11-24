# Skills Architecture, Naming, and Contributor/Maintainer Revamp

**authors:** [Ludo](https://github.com/ludoo) \
**date:** Nov 23, 2026

## Status

Accepted

## Context

Cloud Foundation Fabric currently ships six skills under `skills/` (`contributing`, `fabric-builder`, `fabric-importer`, `fast/networking`, `fast/prerequisites`, `maintenance/release-process`) with inconsistent folder hierarchy, inconsistent flat-install naming (`skills/fast/networking` carries `name: fast-networking` and requires remapping in `agents-cli-extension.yaml`), and uneven architectural depth.

In practice and in multi-model evaluations across local and hosted agents, two structural gaps stand out:

1. **Consumer skills cover HCL composition well (`fabric-builder`) but omit Fabric's YAML factory layer.** Authoring and validating YAML datasets for `project-factory`, `net-vpc-factory`, `vpc-sc`, in-module `factories_config` keys (`FACTORIES.md`), and FAST stages is a distinct mental model (JSON schemas and modelines, `$context:` interpolation, `data_defaults` / `data_overrides` / `data_merges` precedence, and the two-tier module split used to keep dependency chains clean) that has no dedicated skill.
2. **Repo-facing skills bury design and omit PR review.** `skills/contributing/SKILL.md` is a 25 KB mechanical PR workflow checklist with thin interface-design guidance, while operational design knowledge is scattered across a 66 KB `CONTRIBUTING.md`, `GEMINI.md`, `adrs/`, and maintainer review habits. There is no dedicated skill for reviewing pull requests. Even strong frontier and local models mostly produce raw provider-schema translations or ad-hoc wrappers rather than idiomatic Fabric interfaces on module design and PR review under the current `contributing` skill.

Our primary short- and long-term goals are twofold:

1. **Ship a core initial set of evergreen Fabric skills while rationalizing the hierarchy and laying out clear conventions and a repeatable process for future skills** at current `master`.
2. **Publish a sanitized Fabric agent evaluation suite in the repository** (task definitions, deterministic verifiers, and rubric grading — strictly excluding any contributor session traces) to mechanically grade skills across a variety of agents and support reproducible runs over frozen repository snapshots and datasets.

## Decision

### 1. Four-Bucket Top-Level Hierarchy and Flat-Install Naming

Reorganize `skills/` into four audience-oriented top-level buckets immediately — applying the layout to all existing and new skills, even those whose contents are untouched in Wave 1:

```text
skills/
├── fabric/                              # user-facing Fabric consumer skills (self-contained)
│   ├── fabric-builder/                  # module composition + YAML factory authoring/lookup/validation
│   └── fabric-importer/                 # moved from skills/fabric-importer/
├── fast/                                # user-facing FAST skills (self-contained)
│   ├── fast-networking/                 # renamed from skills/fast/networking/
│   └── fast-prerequisites/              # renamed from skills/fast/prerequisites/
├── contributor/                         # repo-facing contributor skills (in-checkout)
│   └── cff-contributing/                # replaces skills/contributing/
└── maintainer/                          # repo-facing maintainer skills (in-checkout, replaces maintenance/)
    ├── cff-issue-triage/                # new: maintainer issue triage with handoff into cff-contributing
    ├── cff-pr-review/                   # new: maintainer PR review
    └── cff-release/                     # moved/renamed from skills/maintenance/release-process/
```

**Flat-install naming rule:** Every skill's leaf directory name MUST match the `name:` field in its `SKILL.md` frontmatter and carry its namespace prefix (`fabric-*`, `fast-*`, `cff-*`). Any skill can then be symlinked or installed directly into a flat `.agents/skills/<name>` or `~/.agents/skills/<name>` directory without path remapping or collisions with other repositories. Using `fabric-*` / `fast-*` for user-facing consumer skills and `cff-*` for repo-facing contributor/maintainer skills keeps both groups visually distinct in `<available_skills>`. `fabric-builder` keeps its name to avoid breaking existing `agents-cli` users, while explicitly mentioning both module composition and YAML factory datasets in its frontmatter `description`.

### 2. User-Facing Skills (Wave 1 Scope)

User-facing skills under `skills/fabric/` and `skills/fast/` MUST remain self-contained (never relying on repo-internal files like `CONTRIBUTING.md` or `AGENTS.md`) because users install them into consumer repositories via `agents-cli`.

- **`fabric/fabric-builder` (module composition + YAML factories):** Retain its lean structure (`SKILL.md` + `references/conventions.md` + `references/factories.md` + `scripts/fabric.py`) rather than splitting YAML factories into a separate skill — just as on the contributor side, HCL module composition and YAML factory datasets are tightly coupled in practice, and splitting them risks agents loading factory guidance while skipping root-module conventions. Extend `scripts/fabric.py` to surface `FACTORIES.md` entries on demand (`factories [target]`), fetch module or FAST stage schemas (`fetch schemas [--stage] [--ref] [--out]`), and validate YAML modelines against JSON schemas (`validate`) so agents never ingest a static catalog table. Keep `references/conventions.md` (HCL root modules) and `references/factories.md` (modelines, `$context:`, precedence, multi-pass DAG order, schema gotchas) compact and orthogonal so agents load only what applies.
- **`fabric/fabric-importer`, `fast/fast-networking`, `fast/fast-prerequisites`:** Move/rename into the new hierarchy in Wave 1 without rewriting their contents; interactive FAST skills remain a separate track.

### 3. Repo-Facing Skills: Lean Contributor Router + Shared References + Standalone PR Review

Because Fabric modules and factories are tightly coupled (`21` modules under `modules/` declare `variable "factories_config"` as of `master` `2fd071954`), splitting contributor guidance into separate `modules` and `factories` top-level skills risks smaller agents loading one and missing schema sync or `duplicate-diff.py` rules on cross-cutting PRs. Instead, `skills/contributor/cff-contributing/` serves as one lean, design-first entry skill with role-named subdirectories that clearly separate architectural design, coding conventions, and testing/PR workflow:

```text
skills/contributor/cff-contributing/
├── SKILL.md                             # lean router: Step 0 fit/boundary check, Fabric Zen, verification habit, routing table
├── design/                              # architectural & interface design (exact file split finalized during authoring)
│   ├── interfaces.md                    # interface design principles (mostly modules, plus cross-cutting interface grammar)
│   ├── modules.md                       # logical-entity boundaries, ownership, IAM/context/outputs, when NOT to add a module
│   ├── factories.md                     # in-module vs pure factories, two-tier splits (project + project-iam), DAG invariants, schemas
│   └── fast.md                          # thin module-to-FAST boundary contract for Wave 1 (deep FAST internals deferred)
├── conventions/                         # coding and schema conventions
│   └── hcl.md                           # compact optional(), maps vs lists, context lookups, OpenTofu nulls, permadiffs, style
└── workflow/                            # testing and mechanical PR lifecycle (out of SKILL.md so it never drowns design turns)
    ├── testing.md                       # what/how to write (README # tftest, tftest.yaml, inventory diffs, debug dump) & pre-PR test run
    └── pr-lifecycle.md                  # branches, lint.sh, tfdoc, schema_docs, duplicate-diff, versions.py, E2E, PII/PR body
```

*(Note on `design/` granularity: keeping **interface design** explicit — primarily modules while capturing cross-cutting principles that apply across modules, factories, and FAST boundaries — is a Wave 1 requirement; the exact file boundaries inside `design/` will be finalized while mining source material.)*

**Where Wave 1 draws the FAST line:** FAST stages are their own world of complexity. Wave 1 covers `modules` + `factories` + a concise `fast.md` covering cross-cutting PR boundaries (factories belong in modules unless a stage iterates standard modules, `duplicate-diff.py` schema sync into FAST stages, `tftest.yaml`). Deep FAST stage architecture (`0-org-setup`, `1-vpcsc`, `2-networking`, `2-security` internals) is deferred to a later pass — either expanding `design/fast.md` inside `cff-contributing/` or adding a dedicated `skills/contributor/cff-fast/` skill.

**`skills/maintainer/cff-pr-review/` (new):** Standalone top-level maintainer skill with a distinct trigger and diagnostic posture (starting from an existing diff rather than a feature request). Because both skills operate inside a `cloud-foundation-fabric` checkout, `cff-pr-review/SKILL.md` explicitly points to `../../contributor/cff-contributing/design/`, `conventions/`, and `workflow/testing.md` as its canonical criteria (zero rule duplication) and focuses its own text strictly on reviewing:

- **Step 0 architectural triage:** Does this PR belong in Fabric? Reject single-resource wrapper modules, single-resource-context boundary violations, `project-factory` two-tier/DAG breaks, and unrelated PR scope.
- **Concrete diff-level checks:** OpenTofu `null` crashes, permadiffs, missing `context` / `outputs` / `depends_on`, redundant booleans or locals, stale `.schema.json` / `.schema.md` / `duplicate-diff.py` copies, missing or unexplained test inventory updates, missing `**Breaking Changes**` / `upgrade-note` blocks, and per-module version-pin drift (`tools/versions.py`).
- **Review output discipline:** Verify claims against provider schemas and sibling modules before commenting, separate blocking architectural/correctness defects from nits, and cite exact file/line evidence.

**`skills/maintainer/cff-issue-triage/` (new):** Sister maintainer skill for triaging incoming GitHub issues or sweeping the backlog. Like `cff-pr-review`, it points directly to `../../contributor/cff-contributing/design/` and `workflow/pr-lifecycle.md` with zero rule duplication, focusing strictly on issue classification (`bug`, `enhancement`, `question`, `duplicate`, `invalid`, `wontfix`), duplicate/stale-version checks, verifying claims against current code, released provider docs, and ADRs, recommending area/disposition labels (`on:*`) and a drafted reply behind a GitHub write gate, and handing off cleanly into `cff-contributing` at Design Sign-off if the maintainer decides to implement the issue directly.

**Step 0 boundary and honest-stop check:** Rejecting out-of-scope requests, single-resource-context violations, non-existent GCP API features, or under-specified requirements is not a separate skill — it sits explicitly at Step 0/Step 1 of `cff-contributing`, `cff-pr-review`, and `cff-issue-triage`.

### 4. Reconciling `AGENTS.md`, `CONTRIBUTING.md`, and `agents-cli-extension.yaml`

As part of this ADR's rollout:

- **Rename `GEMINI.md` to `AGENTS.md` and drop the symlink:** Make root `AGENTS.md` the single real repository instruction file (supported directly by `agy`, `pi`, and standard coding agents).
- **Keep `AGENTS.md` as a lean, always-loaded compass (~1–2 pages) rather than an empty pointer:** Move verbose tutorials currently in `GEMINI.md` (such as the full `context` walkthrough and long testing examples) into `skills/contributor/cff-contributing/` so they live in one canonical place. Retain in `AGENTS.md` the repository map, the short non-negotiable architectural compass (single-resource-context boundary, logical-entity encapsulation, compact `optional()`/map interfaces, check siblings and provider schema before designing), critical mechanical gotchas (`tfdoc`, alphabetical variables, `lint.sh`, `pytest`), and direct repo-relative links to `skills/contributor/cff-contributing/SKILL.md` (plus `design/`, `conventions/`, `workflow/`), `skills/maintainer/cff-pr-review/SKILL.md`, and `skills/maintainer/cff-issue-triage/SKILL.md`. That way, even an agent running without active skill auto-loading still receives core guardrails immediately and knows the exact plain-Markdown files to `read` before designing, triaging, or reviewing.
- **Reconcile `CONTRIBUTING.md`:** Keep `CONTRIBUTING.md` as the human handbook aligned with the skill principles without requiring agents to ingest 66 KB of prose to find operational design rules.
- **Update `agents-cli-extension.yaml` and `skills/README.md`:** Point consumer entries to the new `skills/fabric/*` and `skills/fast/*` paths (`fabric-importer` stays excluded from `agents-cli-extension.yaml` for now).
- **Move repo-wide skill manifest validation out of `fast-networking`:** Relocate `test_agents_cli_extension_manifest_is_valid` from `skills/fast/fast-networking/tests/test_validate_dataset.py` into a repo-level test (e.g. `tests/skills/`) that validates both `agents-cli-extension.yaml` and the flat-install naming invariant (`leaf dir == SKILL.md frontmatter name:` and bucket prefix) across all `skills/*/*/` directories.

### 5. Repeatable Skill Authoring Process and Testing Harness Roadmap

Wave 1 is developed at current `master` while explicitly recording the authoring methodology as a reusable process for future skills and for deriving skills against frozen snapshots or datasets (including downstream evaluation or model-training experiments):

1. **Source mining:** Extract recurring principles and concrete failure modes from current `CONTRIBUTING.md`, `adrs/`, `FACTORIES.md`, golden-path modules (`project`, `compute-vm`, `net-vpc`, `project-factory`, `net-vpc-factory`, `vpc-sc`), maintainer PR review threads, and recorded maintainer sessions.
2. **Role-separated drafting:** Keep `SKILL.md` lean and principle-driven (architectural reasoning heuristics rather than bloated numbered checklists), separate `design/`, `conventions/`, and `workflow/` files, and put Step 0 fit/boundary checks at the top.
3. **Data-backed mechanical evaluation:** Measure every skill iteration quantitatively (`no-skills` vs baseline skill vs candidate skill) across composition (`terraform plan` + `conventions.md`), factory YAML validation, interface design, PR review, and boundary honest-stops across multiple agents before merging. In practice, we pair a capable compact local coding model (`Qwen3.8-27B`) for fast branch iteration with a stronger next-tier model (`Qwen3.8-Flash-Next`) as the milestone validator, using fixed coding-appropriate sampling (`temperature=0.7`, `top_p=0.95`, `top_k=20`, matched `reasoning_effort`) across all compared arms so run-to-run variance does not mask structural skill deltas. During iteration, we run targeted slice-only passes (for example `pr_review` or `contributor` alone, inspecting per-criterion hits alongside headline buckets) and reserve full-suite runs for milestone commits, naming every eval arm by its exact short git commit SHA so progress stays reproducible and comparable.
4. **Follow-up task — publish the sanitized eval suite and revamp `tools/skill-turn-harness/`:** Once Wave 1 skill shapes and deterministic/rubric checks stabilize, publish the sanitized evaluation suite (task manifests, offline `terraform plan`/`conventions.md`/YAML-schema verifiers, and pluggable rubric grading — strictly without raw session traces or personal/internal references) alongside a revamped, model-agnostic `tools/skill-turn-harness/` supporting OpenAI-compatible and Gemini/Antigravity backends plus existing interactive persona playbooks. Over time, the same suite can also support optional comparative agent/model scoreboards and reproducible runs against frozen repository datasets.

## Rollout Plan

1. **Wave 1 — Skills architecture, authoring, and repository reconciliation:** Land this ADR, refresh `FACTORIES.md`, migrate existing skills into `skills/{fabric,fast,contributor,maintainer}/` with flat-safe leaf names, author `contributor/cff-contributing` (`SKILL.md` + `design/`, `conventions/`, `workflow/`), `maintainer/cff-pr-review`, and `maintainer/cff-issue-triage`, extend `fabric/fabric-builder` with YAML factory guidance (`references/factories.md`) and script-backed factory lookup/schema validation (`scripts/fabric.py`), replace the `AGENTS.md -> GEMINI.md` symlink with a lean root `AGENTS.md` compass, align `CONTRIBUTING.md`, `skills/README.md`, `agents-cli-extension.yaml`, and playbook `link_paths`, and move manifest/hierarchy contract tests into `tests/skills/`.
2. **Follow-up PR — public eval suite and `tools/skill-turn-harness/` revamp:** Publish the sanitized eval suite in-repo and port the proven runner, deterministic verifiers, and A/B skill grading patterns into `tools/skill-turn-harness/`.

## Consequences

- **Flat-install portability:** Every skill can be installed into a flat `.agents/skills/` or `~/.agents/skills/` folder with zero name collisions or manual remapping.
- **Single source of design truth with safe fallback:** `cff-contributing`, `cff-pr-review`, and `cff-issue-triage` share one canonical set of `design/`, `conventions/`, and `workflow/` files, while a lean root `AGENTS.md` keeps core guardrails and direct file pointers visible even when skills are not auto-loaded.
- **Migration impact:** Existing `agents-cli` users keep `fabric-builder`, `fast-networking`, and `fast-prerequisites` under the same installed skill names (only internal repo paths in `agents-cli-extension.yaml` change); contributors using `skills/contributing`, `skills/maintenance/release-process`, or `GEMINI.md` update to `skills/contributor/cff-contributing`, `skills/maintainer/cff-release`, and `AGENTS.md` (documented with an `upgrade-note`).
- **Reusable authoring and grading process:** Documenting the mining-to-eval loop and publishing the sanitized evaluation suite gives Fabric a repeatable way to evolve future skills (including deep FAST skills), grade skills mechanically across agents, and run reproducible evaluations against frozen snapshots.

## Evaluation Results and Backlog

### Measurement Protocol and Suite

To validate Wave 1 mechanically without relying on subjective spot-checks, every skill iteration is measured against a frozen 34-item post-cutoff evaluation suite (all contributor and PR-review tasks drawn from Fabric PRs merged after March 22, 2026 and pinned to their pre-PR parent commits via `git archive`):

| Slice | Items | Count | Sandbox surface | Grading |
| --- | --- | --- | --- | --- |
| Contributor design | `C01`–`C10` | 10 | Read-only repo checkout | Offline 3-bucket rubric (`+/~/-`) + per-criterion hit rate |
| Composition & YAML factories | `U01`–`U10` | 10 | Writable workspace + read-only `./fabric` | Deterministic offline `terraform fmt`/`init`/`plan`, resource/attribute checks, JSON schema validation, `conventions.md` lint |
| Honest-stop & boundaries | `H01`–`H06` | 6 | Mixed (`user`, `contributor`, editable) | Mechanical exit slot (`stop_and_clarify`) + `imm_w == 0` + semantic stop verification |
| PR review | `P01`–`P08` | 8 | Read-only repo checkout | Offline 3-bucket rubric (`+/~/-`) + per-criterion hit rate |

Every rollout runs inside an isolated, network-disabled `bwrap` sandbox exposing standard coding-agent tools (`read`, `bash`, `edit`, `write`, an offline `provider_schema` lookup pinned to `hashicorp/google` and `hashicorp/google-beta` `8.10.0`, and a non-penalized `stop_and_clarify` exit slot). All compared arms share fixed decoding parameters (`temperature=0.7`, `top_p=0.95`, `top_k=20`, `presence_penalty=0.0`, `seed=42`, `max_turns=100`, matched `reasoning_effort=medium`).

To prevent historical files in pinned snapshots from contaminating comparisons, every materialized snapshot strips `skills/`, `AGENTS.md`, `GEMINI.md`, and `agents-cli-extension.yaml` before execution:

- **Bare baseline (`none`):** runs against the stripped human repository (`modules/`, `fast/`, `adrs/`, `CONTRIBUTING.md`, `CURSED_KNOWLEDGE.md`, `FACTORIES.md`) with zero agent-instruction or skill files reachable on disk.
- **Skill arms (`blurb-<short-sha>`):** overlay only that exact git commit's coupled `AGENTS.md`/`GEMINI.md` and `skills/` tree via realistic `<available_skills>` discovery (and offline `fabric.py` shims in consumer mode), preventing stale snapshot files (such as deleted `GEMINI.md` alongside Wave 1 `AGENTS.md`, or `./fabric/skills/` in consumer workspaces) from leaking across arms.

In the tables below, `+ / ~ / -` is strictly ordered (`+` `Aligned` = idiomatic, maintainer-grade Fabric meeting all core criteria; `~` `Provider/AdHoc` = coherent partial design/review or verified schema-gap stop; `-` `Broken` = wrong module boundary, missed core requirements, rubber-stamped broken PR, or premature stop). `Strict` counts `+` on Design and PR Review, full deterministic pass on Composition, and verified valid stops on Honest-stop (`x/34`). `imm_w` counts attempted writes to read-only fixtures (`0` required).

### Temperature 0.7 Measurements

All seven `temperature=0.7` anchor runs are complete across three models — the compact MoE bare floor (`Qwen3.6-35B-A3B`), the Tier 1 dense iteration model (`Qwen3.8-27B`), and the Tier 2 milestone validator (`Qwen3.8-Flash-Next`):

| Model | Arm | Design (`+/~/-`, crit) | PR Rev (`+/~/-`, crit) | Comp (`plan` / full) | Honest-stop (`m/v`) | `imm_w` | Strict | Avg / item (`turns · tok`) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Qwen3.6-35B-A3B` | `q35b-none` *(bare)* | `0 / 2 / 8` (`42.7%`) | `0 / 3 / 5` (`28.1%`) | `10/10` / `1/10` | `3/6` / `3/6` | `1` | `4/34` | `17.7t · 7.2k` |
| `Qwen3.8-27B` | `q27b-none` *(bare)* | `0 / 9 / 1` (`58.4%`) | `0 / 7 / 1` (`51.9%`) | `10/10` / `0/10` | `4/6` / `3/6` | `0` | `3/34` | `18.9t · 12.2k` |
| `Qwen3.8-27B` | `q27b-blurb-2fd071954` *(`master`)* | `0 / 8 / 2` (`60.3%`) | `2 / 6 / 0` (`56.4%`) | `10/10` / `7/10` | `5/6` / `5/6` | `0` | `14/34` | `16.4t · 9.9k` |
| `Qwen3.8-27B` | `q27b-blurb-6c2c92c95` *(Wave 1)* | **`2 / 6 / 2` (`63.2%`)** | **`2 / 6 / 0` (`66.7%`)** | **`10/10` / `8/10`** | `5/6` / `4/6` | **`0`** | **`16/34`** | **`15.6t · 11.0k`** |
| `Qwen3.8-Flash-Next` | `qfn-none` *(bare)* | `0 / 8 / 2` (`59.5%`) | `3 / 5 / 0` (`62.5%`) | `10/10` / `0/10` | `5/6` / `4/6` | `0` | `7/34` | `27.7t · 16.2k` |
| `Qwen3.8-Flash-Next` | `qfn-blurb-2fd071954` *(`master`)* | `1 / 7 / 2` (`57.7%`) | `3 / 5 / 0` (`63.5%`) | `9/10` / `9/10` | `5/6` / `5/6` | `1` | `18/34` | `24.6t · 15.1k` |
| `Qwen3.8-Flash-Next` | `qfn-blurb-6c2c92c95` *(Wave 1)* | **`3 / 6 / 1` (`67.1%`)** | **`5 / 2 / 1` (`73.5%`)** | **`10/10` / `10/10`** | **`6/6` / `5/6`** | **`0`** | **`23/34`** | **`22.4t · 13.2k`** |

Slice-by-slice progression across both `Qwen3.8-27B` and `Qwen3.8-Flash-Next` isolates what current `master` already delivers versus what Wave 1 adds:

| Dimension | `none` -> `master` (`2fd071954`) | `master` -> Wave 1 (`6c2c92c95`) | Key observation |
| --- | --- | --- | --- |
| Design (`C01`–`C10`) | `27B`: `0/9/1` -> `0/8/2` (`+1.9%`); `QFN`: `0/8/2` -> `1/7/2` (`-1.8%`) | `27B`: **`2/6/2`** (`+2.9%`); `QFN`: **`3/6/1`** (**`+9.4%`**) | `master` barely moved Design (`0` `+` on `27B`, `1` `+` on `QFN`); Wave 1 unlocked `+` designs on both models (`C01`/`C03` on `27B`, `C03`/`C04`/`C07` on `QFN`) and cut `QFN` `-` to `C05` (`vpc-sc` vs `organization` ownership). |
| PR Review (`P01`–`P08`) | `27B`: `0/7/1` -> `2/6/0` (`+4.5%`); `QFN`: `3/5/0` -> `3/5/0` (`+1.0%`) | `27B`: `2/6/0` (**`+10.3%`**, `66.7%`); `QFN`: **`5/2/1`** (**`+10.0%`**, `73.5%`) | `100%` `cff-pr-review` activation (`8/8` on both models) drove an identical `+10%` criterion lift on both tiers, unlocking `+` on `P02`/`P07` (`27B`) and `P02`/`P04`/`P06`/`P07`/`P08` (`QFN`). |
| Composition (`U01`–`U10`) | `27B`: `0/10` -> `7/10`; `QFN`: `0/10` -> `9/10` (`9/10` plan) | `27B`: **`8/10`** (`10/10` plan); `QFN`: **`10/10` full** (`10/10` plan) | `10/10` `fabric-builder` activation and `3/3` `references/factories.md` usage on `U01`/`U04`/`U09` on both models; `QFN` hit `10/10` strict (fixing `master`'s `U01` failure), while `27B` missed only `U06` (additive vs authoritative GCS IAM on 2/3 roles) and `U09` (`variables.tf` ordering). |
| Honest-stop (`H01`–`H06`) | `27B`: `3/6` -> `5/6`; `QFN`: `4/6` -> `5/6` verified | `27B`: `4/6` (`5/6` mech); `QFN`: **`5/6` verified (`6/6` mech)** | Both models clear `H05` (single-resource-context pushback) under skills; `QFN` Wave 1 is the only arm to pass `H01` (`H01`–`H05` verified, `0` `imm_w`). |
| Efficiency & hygiene | `27B`: `18.9t` -> `16.4t`; `QFN`: `27.7t` -> `24.6t` (`1` `imm_w`) | `27B`: **`15.6t`**, `0` `imm_w`; `QFN`: **`22.4t`**, **`0` `imm_w`** | Role-separated skills hit `100%` activation across all slices while trimming average turns and completion tokens below both `master` and bare `none` on both tiers. |

### Follow-up Backlog (Near-Miss Structural Patterns)

Two structural near-miss patterns surfaced in `q27b-blurb-6c2c92c95` PR-review traces (with Pattern 2 reproduced identically on `qfn-blurb-6c2c92c95`) for the next targeted iteration on `skills/maintainer/cff-pr-review/`:

1. **Over-applying scope restraint to paired wrapper/factory plumbing and `var.context` parity:**
   - **Traces:** `q27b-blurb-6c2c92c95` / `P08` (PR `#4052`, `modules/net-vpc` BGP configuration, `3/4` criteria, 13 turns) and `q27b-blurb-6c2c92c95` / `P04` (PR `#4425`, `modules/cloud-build-v2-connection` `var.context` and IAM conditions, `3/5` criteria, 22 turns). *(Note: `qfn-blurb-6c2c92c95` passed both `P08` and `P04` as `+`, confirming the gap hits smaller models harder.)*
   - **Observed failure:** On `P08`, the reviewer caught the unrelated `modules/iam-service-account` hunk and missing enum validations, then explicitly dismissed wiring `bgp_config` through `modules/net-vpc-factory` and mirrored `vpc-factory.schema.json` copies (`modules/net-vpc-factory/schemas/`, `fast/stages/0-org-setup/schemas/`) as unnecessary because the new variable was optional. On `P04`, the reviewer spotted `repositories[].triggers[].service_account` as a `service_account_ids` context candidate and explicitly dismissed it as out-of-scope ("do not expand scope in this PR") while also missing `secrets` context interpolation on `*_secret_version` fields.
   - **Planned refinement:** Clarify in `skills/maintainer/cff-pr-review/SKILL.md` the distinction between unrelated cross-module edits (split out) and paired wrapper/factory parity (`net-vpc` <-> `net-vpc-factory`, `project` <-> `project-factory`) or complete `var.context` coverage across a PR's target resource surface (blocking parity gaps).
2. **Stopping after the first diff-level HCL or null-handling defect instead of sweeping every block in the diff:**
   - **Traces:** `q27b-blurb-6c2c92c95` / `P01` (PR `#4424`, `modules/project-factory` `logging_sinks`, `3/4` criteria, 12 turns), `q27b-blurb-6c2c92c95` and `qfn-blurb-6c2c92c95` / `P05` (PR `#4310`, `modules/organization` Model Armor floor setting, `5/9` on `27B`, `4/8` on `QFN`), and `q27b-blurb-6c2c92c95` and `qfn-blurb-6c2c92c95` / `P03` (PR `#4423`, `modules/project` + `project-factory` Model Armor templates, `4/8` on `27B`, `4/7` on `QFN`).
   - **Observed failure:** On `P01` (`27B`), the reviewer nailed the two-tier DAG and CMEK/org-policy rejection, then missed that `logging_sinks` in `modules/project-factory/projects.tf` was nested inside `module.projects-iam`'s `context = { ... }` block rather than passed as a top-level argument. On `P05` and `P03` (both `27B` and `QFN`), the reviewer caught the first explicit-`null` crash (`integrated_services = null`, `filters = null`) and silent `count`, then stopped short of auditing remaining nullable sub-objects and `dynamic` blocks (`rai = null`, `location = null`, and empty `sdp = {}` emitting an empty `sdp_settings {}` permadiff).
   - **Planned refinement:** Reinforce a full-diff verification pass in `skills/maintainer/cff-pr-review/SKILL.md`: verify exact block nesting for every added or moved argument in the diff, and check every nullable sub-object and `dynamic` block for explicit-`null` crashes and empty-block permadiffs rather than stopping after the first defect.
