# Skills Architecture, Naming, and Contributor/Maintainer Revamp

**authors:** [Ludo](https://github.com/ludoo) \
**date:** Nov 23, 2026

## Status

Proposed

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
│   ├── fabric-builder/                  # kept name; update trigger hook to mention module composition
│   ├── fabric-factories/                # new: YAML factory authoring (modules -> FAST datasets)
│   └── fabric-importer/                 # moved from skills/fabric-importer/
├── fast/                                # user-facing FAST skills (self-contained)
│   ├── fast-networking/                 # renamed from skills/fast/networking/
│   └── fast-prerequisites/              # renamed from skills/fast/prerequisites/
├── contributor/                         # repo-facing contributor skills (in-checkout)
│   └── cff-contributing/                # replaces skills/contributing/
└── maintainer/                          # repo-facing maintainer skills (in-checkout, replaces maintenance/)
    ├── cff-pr-review/                   # new: maintainer PR review
    └── cff-release/                     # moved/renamed from skills/maintenance/release-process/
```

**Flat-install naming rule:** Every skill's leaf directory name MUST match the `name:` field in its `SKILL.md` frontmatter and carry its namespace prefix (`fabric-*`, `fast-*`, `cff-*`). Any skill can then be symlinked or installed directly into a flat `.agents/skills/<name>` or `~/.agents/skills/<name>` directory without path remapping or collisions with other repositories. Using `fabric-*` / `fast-*` for user-facing consumer skills and `cff-*` for repo-facing contributor/maintainer skills keeps both groups visually distinct in `<available_skills>`. `fabric-builder` keeps its name to avoid breaking existing `agents-cli` users, while explicitly mentioning module composition in its frontmatter `description`.

### 2. User-Facing Skills (Wave 1 Scope)

User-facing skills under `skills/fabric/` and `skills/fast/` MUST remain self-contained (never relying on repo-internal files like `CONTRIBUTING.md` or `AGENTS.md`) because users install them into consumer repositories via `agents-cli`.

- **`fabric/fabric-builder` (light polish):** Retain its lean structure (`SKILL.md` + `references/conventions.md` + `scripts/fabric.py`). Update the frontmatter description to explicitly mention module composition, tighten recurring convention misses (pre-finish check for alphabetical `variables.tf`, omitting root `required_providers` / `required_version`, avoiding stray `terraform.tfvars`), and hand off factory YAML data authoring to `fabric-factories`.
- **`fabric/fabric-factories` (new):** Cover working with Fabric's YAML data layer, starting from module factories (`project-factory`, `net-vpc-factory`, `vpc-sc`, and in-module `factories_config` keys indexed in `FACTORIES.md`) and graduating cleanly to FAST stage YAML datasets. Cover JSON schema discovery and `# yaml-language-server: $schema=...` modelines, `jsonschema`/`yamllint` validation, `$context:` symbolic interpolation, `data_defaults` / `data_overrides` / `data_merges` precedence, folder-vs-file conventions, and the two-tier module structure used by large factories (such as `project` and `project-iam`) to keep the Terraform dependency chain clean and acyclic.
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
│   └── fast-seam.md                     # thin module-to-FAST boundary contract for Wave 1 (deep FAST internals deferred)
├── conventions/                         # coding and schema conventions
│   └── hcl.md                           # compact optional(), maps vs lists, context lookups, OpenTofu nulls, permadiffs, style
└── workflow/                            # testing and mechanical PR lifecycle (out of SKILL.md so it never drowns design turns)
    ├── testing.md                       # what/how to write (README # tftest, tftest.yaml, inventory diffs, debug dump) & pre-PR test run
    └── pr-lifecycle.md                  # branches, lint.sh, tfdoc, schema_docs, duplicate-diff, versions.py, E2E, PII/PR body
```

*(Note on `design/` granularity: keeping **interface design** explicit — primarily modules while capturing cross-cutting principles that apply across modules, factories, and FAST seams — is a Wave 1 requirement; the exact file boundaries inside `design/` will be finalized while mining source material.)*

**Where Wave 1 draws the FAST line:** FAST stages are their own world of complexity. Wave 1 covers `modules` + `factories` + a concise `fast-seam.md` covering cross-cutting PR boundaries (factories belong in modules unless a stage iterates standard modules, `duplicate-diff.py` schema sync into FAST stages, `tftest.yaml`). Deep FAST stage architecture (`0-org-setup`, `1-vpcsc`, `2-networking`, `2-security` internals) is deferred to a later pass — either expanding `design/fast.md` inside `cff-contributing/` or adding a dedicated `skills/contributor/cff-fast/` skill.

**`skills/maintainer/cff-pr-review/` (new):** Standalone top-level maintainer skill with a distinct trigger and diagnostic posture (starting from an existing diff rather than a feature request). Because both skills operate inside a `cloud-foundation-fabric` checkout, `cff-pr-review/SKILL.md` explicitly points to `../../contributor/cff-contributing/design/`, `conventions/`, and `workflow/testing.md` as its canonical criteria (zero rule duplication) and focuses its own text strictly on reviewing:

- **Step 0 architectural triage:** Does this PR belong in Fabric? Reject single-resource wrapper modules, single-resource-context boundary violations, `project-factory` two-tier/DAG breaks, and unrelated PR scope.
- **Concrete diff-level checks:** OpenTofu `null` crashes, permadiffs, missing `context` / `outputs` / `depends_on`, redundant booleans or locals, stale `.schema.json` / `.schema.md` / `duplicate-diff.py` copies, missing or unexplained test inventory updates, missing `**Breaking Changes**` / `upgrade-note` blocks, and per-module version-pin drift (`tools/versions.py`).
- **Review output discipline:** Verify claims against provider schemas and sibling modules before commenting, separate blocking architectural/correctness defects from nits, and cite exact file/line evidence.

**Step 0 boundary and honest-stop check:** Rejecting out-of-scope requests, single-resource-context violations, non-existent GCP API features, or under-specified requirements is not a separate skill — it sits explicitly at Step 0 of both `cff-contributing` and `cff-pr-review`.

### 4. Reconciling `AGENTS.md`, `CONTRIBUTING.md`, and `agents-cli-extension.yaml`

As part of this ADR's rollout:

- **Rename `GEMINI.md` to `AGENTS.md` and drop the symlink:** Make root `AGENTS.md` the single real repository instruction file (supported directly by `agy`, `pi`, and standard coding agents).
- **Keep `AGENTS.md` as a lean, always-loaded compass (~1–2 pages) rather than an empty pointer:** Move verbose tutorials currently in `GEMINI.md` (such as the full `context` walkthrough and long testing examples) into `skills/contributor/cff-contributing/` so they live in one canonical place. Retain in `AGENTS.md` the repository map, the short non-negotiable architectural compass (single-resource-context boundary, logical-entity encapsulation, compact `optional()`/map interfaces, check siblings and provider schema before designing), critical mechanical gotchas (`tfdoc`, alphabetical variables, `lint.sh`, `pytest`), and direct repo-relative links to `skills/contributor/cff-contributing/SKILL.md` (plus `design/`, `conventions/`, `workflow/`) and `skills/maintainer/cff-pr-review/SKILL.md`. That way, even an agent running without active skill auto-loading still receives core guardrails immediately and knows the exact plain-Markdown files to `read` before designing or reviewing.
- **Reconcile `CONTRIBUTING.md`:** Keep `CONTRIBUTING.md` as the human handbook aligned with the skill principles without requiring agents to ingest 66 KB of prose to find operational design rules.
- **Update `agents-cli-extension.yaml` and `skills/README.md`:** Point consumer entries to the new `skills/fabric/*` and `skills/fast/*` paths and register `fabric-factories` once ready.

### 5. Repeatable Skill Authoring Process and Testing Harness Roadmap

Wave 1 is developed at current `master` while explicitly recording the authoring methodology as a reusable process for future skills and for deriving skills against frozen snapshots or datasets (including downstream evaluation or model-training experiments):

1. **Source mining:** Extract recurring principles and concrete failure modes from current `CONTRIBUTING.md`, `adrs/`, `FACTORIES.md`, golden-path modules (`project`, `compute-vm`, `net-vpc`, `project-factory`, `net-vpc-factory`, `vpc-sc`), maintainer PR review threads, and recorded maintainer sessions.
2. **Role-separated drafting:** Keep `SKILL.md` lean and principle-driven (architectural reasoning heuristics rather than bloated numbered checklists), separate `design/`, `conventions/`, and `workflow/` files, and put Step 0 fit/boundary checks at the top.
3. **Data-backed mechanical evaluation:** Measure every skill iteration quantitatively (`no-skills` vs baseline skill vs candidate skill) across composition (`terraform plan` + `conventions.md`), factory YAML validation, interface design, PR review, and boundary honest-stops across multiple agents before merging.
4. **Follow-up task — publish the sanitized eval suite and revamp `tools/skill-turn-harness/`:** Once Wave 1 skill shapes and deterministic/rubric checks stabilize, publish the sanitized evaluation suite (task manifests, offline `terraform plan`/`conventions.md`/YAML-schema verifiers, and pluggable rubric grading — strictly without raw session traces or personal/internal references) alongside a revamped, model-agnostic `tools/skill-turn-harness/` supporting OpenAI-compatible and Gemini/Antigravity backends plus existing interactive persona playbooks. Over time, the same suite can also support optional comparative agent/model scoreboards and reproducible runs against frozen repository datasets.

## Rollout Plan

1. **PR 1 — ADR and skill hierarchy migration:** Land this ADR, move/rename existing skills into `skills/{fabric,fast,contributor,maintainer}/` with flat-safe leaf names, and update `agents-cli-extension.yaml`, `skills/README.md`, and any internal references/lint checks.
2. **PR 2 — Wave 1 skill authoring and eval data:** Polish `fabric/fabric-builder`, author `fabric/fabric-factories`, replace `contributor/cff-contributing` (`SKILL.md` + `design/`, `conventions/`, `workflow/`), and author `maintainer/cff-pr-review`, documenting the authoring process and iterating until evaluation metrics show clear gains across agents.
3. **PR 3 — `AGENTS.md` (renamed from `GEMINI.md`) and `CONTRIBUTING.md` reconciliation:** Replace the `AGENTS.md -> GEMINI.md` symlink with a lean root `AGENTS.md` compass pointing directly at the new skills, and align `CONTRIBUTING.md` pointers once Wave 1 skills are merged.
4. **Follow-up PR — public eval suite and `tools/skill-turn-harness/` revamp:** Publish the sanitized eval suite in-repo and port the proven runner, deterministic verifiers, and A/B skill grading patterns into `tools/skill-turn-harness/`.

## Consequences

- **Flat-install portability:** Every skill can be installed into a flat `.agents/skills/` or `~/.agents/skills/` folder with zero name collisions or manual remapping.
- **Single source of design truth with safe fallback:** `cff-contributing` and `cff-pr-review` share one canonical set of `design/`, `conventions/`, and `workflow/testing.md` files, while a lean root `AGENTS.md` keeps core guardrails and direct file pointers visible even when skills are not auto-loaded.
- **Migration impact:** Existing `agents-cli` users keep `fabric-builder`, `fast-networking`, and `fast-prerequisites` under the same installed skill names (only internal repo paths in `agents-cli-extension.yaml` change); contributors using `skills/contributing`, `skills/maintenance/release-process`, or `GEMINI.md` update to `skills/contributor/cff-contributing`, `skills/maintainer/cff-release`, and `AGENTS.md` (documented with an `upgrade-note`).
- **Reusable authoring and grading process:** Documenting the mining-to-eval loop and publishing the sanitized evaluation suite gives Fabric a repeatable way to evolve future skills (including deep FAST skills), grade skills mechanically across agents, and run reproducible evaluations against frozen snapshots.

---

## Implementation Tracker (temporary — remove before PR)

<!-- TEMPORARY: Delete this entire section before opening the PR (covered in Step 5). -->

### Settled branch decisions

- Implement the ADR in a single PR on branch `ludo/skills-architecture` using clean atomic commits per step (one fresh session per major authoring step).
- Leave `fabric-importer` out of `agents-cli-extension.yaml` for now.
- Defer Step 6 (evaluation loop and `tools/skill-turn-harness/` revamp scope) until Steps 1–5 are complete.

### Progress

- [x] **Step 0 (preliminary) — Refresh `FACTORIES.md`:** Audited all 21 modules, 6 FAST stages, FAST addons, and FAST project templates; added `Schema` column (99/99 `*.schema.json` mapped, 0 broken links) and updated Maintenance Guide (`6f0fa0b1560a7779e322135436df154711504864`).
- [x] **Step 1 — Hierarchy migration:** Moved all 6 existing skills into `skills/{fabric,fast,contributor,maintainer}/` with flat-safe leaf names matching `SKILL.md` frontmatter `name:`, updated `agents-cli-extension.yaml`, `skills/README.md`, `CONTRIBUTING.md`, and internal paths in `fast-networking` and `fabric-importer`; verified all 23 `fast-networking` and 225 `fabric-importer` unit tests pass (`a67638f46fe6c670da2cff96408c8b85cb5cb872`).
- [ ] **Step 2 — Author `skills/contributor/cff-contributing/`:** Mine source material, settle the `design/` file split with the human, and replace the legacy `SKILL.md` with the lean router plus `design/`, `conventions/`, and `workflow/` files.
- [ ] **Step 3 — Author `skills/maintainer/cff-pr-review/`:** Draft the standalone maintainer PR review skill referencing `../../contributor/cff-contributing/` criteria with zero rule duplication.
- [ ] **Step 4 — Consumer skills (`fabric-factories` + `fabric-builder` polish):** Author `skills/fabric/fabric-factories/` anchored on `FACTORIES.md`, and apply the light polish to `skills/fabric/fabric-builder/` (frontmatter trigger, convention checks, handoff to `fabric-factories`).
- [ ] **Step 5 — Reconciliation & PR prep:** Replace `AGENTS.md -> GEMINI.md` symlink with lean root `AGENTS.md` compass; align `CONTRIBUTING.md`, `skills/README.md`, `agents-cli-extension.yaml` (register `fabric-factories` and update `skills/fast/fast-networking/tests/test_validate_dataset.py` manifest assertion), and `tools/skill-turn-harness/playbooks/fast/prerequisites/*.yaml` (`link_paths`); flip ADR `Status` to `Accepted` and delete this temporary `Implementation Tracker` section.
- [ ] **Step 6 — Verification & evaluation loop:** Discuss and execute evals / `tools/skill-turn-harness/` plan once Steps 1–5 are complete.

### Next pickup (Step 2 — `cff-contributing`)

Start by mining source material (via parallel reads or a read-only subagent) before proposing the exact `design/` file split and outline for sign-off:

- `CONTRIBUTING.md` (66 KB), `GEMINI.md` (tutorials/patterns to migrate into `cff-contributing/`), `CURSED_KNOWLEDGE.md`, and `adrs/`.
- Existing `skills/contributor/cff-contributing/SKILL.md` (25 KB mechanical workflow to split/distill into `workflow/`).
- Golden-path modules (`modules/project`, `modules/compute-vm`, `modules/net-vpc`, `modules/project-factory`, `modules/net-vpc-factory`, `modules/vpc-sc`) and `FACTORIES.md`.
- Note on tests in this environment: `uv run --with-requirements tests/requirements.txt` currently hits a resolution error on `tftest>=2.0.0`; run pure Python skill tests directly with `uv run --with pyyaml --with jsonschema --with pytest pytest ...` (or check local `.venv` / `~/venv` when Terraform plan tests are needed).
