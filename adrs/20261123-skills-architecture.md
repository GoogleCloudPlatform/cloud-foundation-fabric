# Skills architecture, naming and contributor revamp

**authors:** [Ludo](https://github.com/ludoo) \
**date:** 23 November 2026

## Status

Ready

## Contents

- [Context](#context)
- [Decision](#decision)
  - [Four audience buckets and flat install naming](#four-audience-buckets-and-flat-install-naming)
  - [Auto-discovery publication via `.agents/skills/` and `.claude/skills`](#auto-discovery-publication-via-agentsskills-and-claudeskills)
  - [Consumer skills in Wave 1](#consumer-skills-in-wave-1)
  - [Repository skills for contributors](#repository-skills-for-contributors)
  - [Repository skills for maintainers](#repository-skills-for-maintainers)
  - [Root instructions, manifests and contract tests](#root-instructions-manifests-and-contract-tests)
  - [Repeatable skill authoring and evaluation gate](#repeatable-skill-authoring-and-evaluation-gate)
- [Rollout plan](#rollout-plan)
- [Consequences](#consequences)
- [Validation](#validation)
  - [Suite and measurement protocol](#suite-and-measurement-protocol)
  - [Results across models](#results-across-models)
  - [Design lessons from ablations](#design-lessons-from-ablations)
  - [Next steps for Wave 2](#next-steps-for-wave-2)

## Context

Cloud Foundation Fabric previously shipped 6 skills under `skills/` (`contributing`, `fabric-builder`, `fabric-importer`, `fast/networking`, `fast/prerequisites` and `maintenance/release-process`). Those skills grew independently and organically over the past months as individual needs came up, so their folder layout, install names, architectural depth and authoring habits diverged (for example, `skills/fast/networking` declared `name: fast-networking` and needed manual remapping in `agents-cli-extension.yaml`). This ADR rationalizes them into one deliberate architecture, naming convention and maintenance lifecycle.

Multi-model evaluations and daily maintainer use exposed 2 structural gaps in those skills.

First, consumer skills covered HCL module composition well in `fabric-builder` and left YAML factories uncovered. Authoring and validating YAML datasets for `project-factory`, `net-vpc-factory`, `vpc-sc`, in-module `factories_config` options in `FACTORIES.md` and FAST stages relies on JSON schemas, modelines, `$context:` interpolation, `data_defaults` / `data_overrides` / `data_merges` precedence and the two-pass module split, so consumer agents lacked guidance on that entire layer.

Second, repository skills buried design guidance inside a 25 KB `skills/contributing/SKILL.md` pull-request checklist and omitted pull-request review altogether. Operational design rules lived across a 66 KB `CONTRIBUTING.md`, `GEMINI.md`, ADRs and maintainer review habits, which meant that even capable models produced raw provider-schema translations or ad-hoc wrappers on module design and pull-request review.

We set 3 goals for this revamp:

- rationalize existing and new Fabric skills into a clean hierarchy with consistent flat-install naming and clear boundaries at current `master`
- replace ad-hoc skill editing and manual spot checks with a repeatable authoring workflow and quality gate backed by an evaluation bundle, so every future skill addition or revision is measured deterministically and qualitatively before merge
- publish a sanitized version of that evaluation suite in the repository as a Wave 2 follow-up (task definitions, deterministic offline verifiers and rubric grading, excluding contributor session traces) so maintainers can test skills mechanically across agents and frozen snapshots

## Decision

### Four audience buckets and flat install naming

We reorganize `skills/` into 4 top-level buckets grouped by audience, moving every existing and new skill into this layout immediately:

```text
skills/
├── fabric/                              # user-facing Fabric consumer skills (self-contained)
│   ├── fabric-builder/                  # module composition and YAML factory authoring/validation
│   └── fabric-importer/                 # moved from skills/fabric-importer/
├── fast/                                # user-facing FAST skills (self-contained)
│   ├── fast-networking/                 # renamed from skills/fast/networking/
│   └── fast-prerequisites/              # renamed from skills/fast/prerequisites/
├── contributor/                         # repo-facing contributor skills (in-checkout)
│   └── cff-contributing/                # replaces skills/contributing/
└── maintainer/                          # repo-facing maintainer skills (in-checkout, replaces maintenance/)
    ├── cff-issue-triage/                # new: maintainer issue triage with handoff into cff-contributing
    ├── cff-pr-review/                   # new: maintainer pull-request review
    └── cff-release/                     # moved/renamed from skills/maintenance/release-process/
```

Every skill's leaf directory name must match the `name:` field in its `SKILL.md` frontmatter and carry its audience prefix (`fabric-`, `fast-` or `cff-`). That rule allows any harness to symlink or install any skill straight into a flat `.agents/skills/<name>` or `~/.agents/skills/<name>` directory without path remapping or name collisions with other repositories. Using `fabric-` and `fast-` for consumer skills and `cff-` for repository skills keeps both groups visually distinct in `<available_skills>`. `fabric-builder` keeps its existing name so current `agents-cli` users face no breaking change, while its frontmatter description now names both module composition and YAML factory datasets.

### Auto-discovery publication via `.agents/skills/` and `.claude/skills`

Canonical skill sources remain visible and audience-grouped under `skills/`, rather than moving into a hidden dot-directory. To give anyone cloning Fabric zero-setup skill auto-discovery across standard coding agents, we track `.agents/skills/` as a curated publication layer containing per-skill relative symlinks (`../../skills/<bucket>/<name>`) and alias `.claude/skills` to `../.agents/skills` for Claude Code:

```text
.agents/skills/
├── cff-contributing -> ../../skills/contributor/cff-contributing
├── fabric-builder -> ../../skills/fabric/fabric-builder
├── fast-networking -> ../../skills/fast/fast-networking
└── fast-prerequisites -> ../../skills/fast/fast-prerequisites

.claude/skills -> ../.agents/skills
```

Publishing per-skill symlinks rather than exposing the full `skills/` tree solves 3 constraints at once:

- flat 1-level discovery without sacrificing audience buckets: most harnesses scan `.agents/skills/*/SKILL.md` at depth 1, while canonical sources keep their `skills/{fabric,fast,contributor,maintainer}/` organization and preserve depth-3 relative links cleanly across `skills/`, `.agents/skills/` and `.claude/skills/`
- graduation gate for incubating skills: beta skills such as `fabric-importer` live under `skills/fabric/` without being auto-discovered by cloners until ready, matching `agents-cli-extension.yaml`
- separation of contributor and maintainer surfaces: cloners (both fork-and-own FAST/Fabric consumers and contributors) auto-discover the stable consumer skills plus `cff-contributing`, while maintainer-only skills (`cff-issue-triage`, `cff-pr-review` and `cff-release`) stay opt-in; `.gitignore` allowlists only the published symlinks under `.agents/skills/` and `.claude/skills` so personal local `.agents/` or `.claude/` files and maintainer symlinks remain untracked

Note on single-skill installs and relative links: consumer skills under `skills/fabric/` and `skills/fast/` have zero links outside their own directory and can be installed standalone anywhere (`~/.agents/skills/` or another repository). Repo-facing contributor and maintainer skills (`cff-contributing`, `cff-pr-review` and `cff-issue-triage`) link to repository files (`adrs/`, `CURSED_KNOWLEDGE.md`, `default-versions.*`, `FACTORIES.md`, `tools/`) and cross-link via repo root (`../../../skills/...`) at depth 3, so they should always be installed by symlinking inside a Fabric checkout (`.agents/skills/<name> -> ../../skills/<bucket>/<name>`, already tracked for `cff-contributing` and gitignored for opt-in maintainer skills) rather than copied standalone; each of those 3 `SKILL.md` files also ends with a short path-resolution fallback telling agents to strip leading `../` segments and resolve from the Fabric repository root if a link ever fails under a global install.

We considered flattening `skills/` directly to `skills/<name>/` because the `fabric-`, `fast-` and `cff-` prefixes already encode audience and flat sibling links (`../cff-contributing/SKILL.md`) would simplify cross-skill references. Keeping the 4 audience buckets is preferable as long as `.agents/skills/` acts as a curated symlink layer over visible `skills/` sources: `skills/<bucket>/<name>/` sits at depth 3 from the repository root, matching `.agents/skills/<name>/` and `.claude/skills/<name>/`, so every repo-root relative link (`../../../adrs/...`, `../../../../FACTORIES.md`, `../../../tools/...`) resolves identically both physically and lexically across all three paths while staying clickable on GitHub and verified by `tools/check_links.py`. Flattening `skills/` to depth 2 would introduce a 1-level lexical mismatch whenever a harness loads a skill through `.agents/skills/<name>/SKILL.md` (turning `../../FACTORIES.md` into `.agents/FACTORIES.md`), which could only be avoided by dropping relative Markdown links to repository files or moving canonical sources into `.agents/skills/` and giving up the visible tree and opt-in publication boundary.

### Consumer skills in Wave 1

Consumer skills under `skills/fabric/` and `skills/fast/` stay self-contained and never reference repository-only files such as `CONTRIBUTING.md` or `AGENTS.md`, because users install them into external repositories through `agents-cli`.

We keep module composition and YAML factories together inside `skills/fabric/fabric-builder/` (`SKILL.md`, `references/conventions.md`, `references/factories.md` and `scripts/fabric.py`). Users routinely mix HCL root modules and YAML factory datasets in the same workspace, so keeping both in one lean skill ensures that an agent loading factory guidance also sees root-module conventions. We extended `scripts/fabric.py` so agents can look up `FACTORIES.md` entries on demand (`factories [target]`), fetch module or FAST stage schemas (`fetch schemas [--stage] [--ref] [--out]`) and validate YAML modelines against JSON schemas (`validate`) without ingesting a static catalog table. Both reference files stay short and orthogonal so agents load only the file that applies.

We moved `fabric/fabric-importer`, `fast/fast-networking` and `fast/fast-prerequisites` into the new hierarchy in Wave 1 while keeping their contents unchanged, because interactive FAST skills follow a separate track.

### Repository skills for contributors

In Fabric, modules and factories are tightly coupled (21 modules under `modules/` declare `variable "factories_config"` as of `master` `2fd071954`). Splitting contributor rules into separate module and factory skills risks an agent editing a module and missing schema synchronization or `duplicate-diff.py` copies. We therefore use `skills/contributor/cff-contributing/` as one lean, design-first router whose subdirectories separate architecture, HCL craft and pull-request mechanics:

```text
skills/contributor/cff-contributing/
├── SKILL.md                             # lean router: Step 0 fit check, Fabric Zen, verification habit, routing table
├── design/                              # architectural and interface design
│   ├── interfaces.md                    # caller-facing ergonomics, compact optional(), canonical IAM/context/secrets
│   ├── modules.md                       # logical-entity boundaries, ownership, outputs and when to reject a module
│   ├── factories.md                     # in-module and pure factories, two-pass DAG invariants, schemas
│   └── fast.md                          # concise module-to-FAST contract for Wave 1 (deep FAST internals deferred)
├── conventions/                         # HCL craft and runtime safety
│   └── hcl.md                           # context lookups, OpenTofu null traps, permadiffs, style
└── workflow/                            # testing and mechanical pull-request lifecycle
    ├── testing.md                       # README # tftest, tftest.yaml, inventory audits, debug dumps, pytest
    └── pr-lifecycle.md                  # branches, lint.sh, tfdoc, schema_docs, duplicate-diff, versions.py, PR body
```

Wave 1 scopes `design/fast.md` to cross-cutting module-to-FAST boundaries (where factories belong, `duplicate-diff.py` schema copies into FAST stages and `tftest.yaml` coverage), so deep FAST stage architecture (`0-org-setup`, `1-vpcsc`, `2-networking` and `2-security` internals) stays deferred to Wave 2. We will add that depth either by expanding `design/fast.md` or by introducing a dedicated `skills/contributor/cff-fast/` skill.

### Repository skills for maintainers

We added 2 standalone maintainer skills under `skills/maintainer/` alongside the moved `cff-release` skill. Both run inside a `cloud-foundation-fabric` checkout and point directly to `../../../skills/contributor/cff-contributing/` for all canonical design, HCL and testing rules so there is one source of truth (working both from `skills/maintainer/` and when symlinked locally into `.agents/skills/`).

`cff-pr-review` starts from an existing pull request or branch diff. It enforces Step 1 architectural triage (rejecting thin single-resource wrappers, companion project IAM inside service modules, `project-factory` two-pass DAG breaks and unrelated cross-module churn), routes selectively to 1 to 2 diff-triggered guides and sweeps every modified block for nesting, explicit-`null` and empty-`dynamic` defects. All GitHub write commands stay behind explicit maintainer approval.

`cff-issue-triage` classifies incoming GitHub issues (`bug`, `enhancement`, `question`, `duplicate`, `invalid` and `wontfix`) and verifies claims against current code, released provider docs and ADRs. It drafts labels and replies behind a GitHub write gate and hands off cleanly into `cff-contributing` at Design Sign-off when a maintainer chooses to implement the issue directly.

Across all 3 repository skills (`cff-contributing`, `cff-pr-review` and `cff-issue-triage`), boundary checks and honest stops sit at Step 0 and Step 1, so agents push back on invalid boundaries, missing GCP API features or under-specified requirements before writing code.

### Root instructions, manifests and contract tests

To keep every agent harness aligned with the new skill tree, we reconciled the repository's root files and contract tests:

- renamed `GEMINI.md` to `AGENTS.md` and dropped the symlink so `AGENTS.md` is the single real repository instruction file across `agy`, `pi` and standard coding agents
- trimmed `AGENTS.md` to a concise 1 to 2 page compass carrying the repository map, core architectural principles, mechanical gotchas (`tfdoc`, alphabetical variables, `lint.sh` and `pytest`) and direct links to the `cff-*` skills, so agents without skill auto-loading still get core guardrails immediately
- aligned `CONTRIBUTING.md` with the same design principles so human readers keep the full handbook while agents rely on the concise skill files
- updated `agents-cli-extension.yaml`, `skills/README.md` and `tools/skill-turn-harness/` playbook `link_paths` to point to `skills/fabric/*` and `skills/fast/*` (keeping `fabric-importer` excluded from `agents-cli-extension.yaml` and `.agents/skills/` for now)
- narrowed `.gitignore` to track only the curated symlinks under `.agents/skills/` and the `.claude/skills` alias while keeping personal local `.agents/` and `.claude/` entries untracked
- relocated `test_agents_cli_extension_manifest_is_valid` from `skills/fast/fast-networking/tests/test_validate_dataset.py` into `tests/skills/test_skills.py`, which validates `agents-cli-extension.yaml`, the flat-install naming rule across every directory under `skills/*/*/` and the `.agents/skills/` and `.claude/skills` publication symlinks

### Repeatable skill authoring and evaluation gate

Previously, skill authoring followed an ad-hoc process of editing prose by intuition and running informal spot checks in interactive chats, which hid regressions and made design trade-offs hard to judge. This ADR introduces a repeatable workflow and qualitative evaluation gate backed by a frozen evaluation bundle (combining deterministic offline Terraform and YAML verifiers with rubric-based grading across design, pull-request review and honest-stop boundaries), so future skill development and maintenance stay grounded in repeatable evidence.

1. Mine recurring principles and real failure modes from `CONTRIBUTING.md`, `adrs/`, `FACTORIES.md`, golden-path modules (`project`, `compute-vm`, `net-vpc`, `project-factory`, `net-vpc-factory` and `vpc-sc`), maintainer review threads and recorded sessions.
2. Draft lean, rationale-first `SKILL.md` routers with role-separated reference files (`design/`, `conventions/` and `workflow/`) and Step 0 / Step 1 boundary checks at the top.
3. Put every change through the evaluation gate across bare (`none`), baseline (`master`) and candidate skill trees using a compact local coding model for fast slice iteration and a stronger model for milestone validation, keeping decoding settings fixed and inspecting per-criterion hits alongside headline buckets.
4. Publish the sanitized evaluation bundle and a revamped, model-agnostic `tools/skill-turn-harness/` in a Wave 2 pull request once Wave 1 stabilizes, excluding all raw contributor session traces and internal references.

## Rollout plan

1. Wave 1 (this branch) lands this ADR, refreshes `FACTORIES.md`, migrates existing skills into `skills/{fabric,fast,contributor,maintainer}/` with flat-safe names, publishes the curated cloner set via `.agents/skills/` and `.claude/skills` symlinks, adds `cff-contributing`, `cff-pr-review` and `cff-issue-triage`, extends `fabric-builder` with YAML factory guidance and `scripts/fabric.py` validation, replaces `GEMINI.md` with a lean `AGENTS.md`, reconciles `CONTRIBUTING.md`, `skills/README.md`, `agents-cli-extension.yaml` and playbook `link_paths`, and adds repo-wide skill contract tests in `tests/skills/test_skills.py`.
2. Wave 2 (follow-up pull request) publishes the sanitized evaluation suite in-repo and ports the runner, deterministic verifiers and A/B skill grading flow into `tools/skill-turn-harness/`.

## Consequences

This architecture produces 4 operational effects:

- flat-install portability and zero-setup clone discovery: every skill installs into a flat `.agents/skills/` or `~/.agents/skills/` directory with zero name collisions or manual remapping, and cloning the repository automatically exposes the curated consumer and contributor skills through `.agents/skills/` and `.claude/skills` while keeping incubating and maintainer-only skills opt-in
- one source of design truth with a safe fallback: `cff-contributing`, `cff-pr-review` and `cff-issue-triage` share one canonical set of `design/`, `conventions/` and `workflow/` guides, while root `AGENTS.md` keeps core guardrails and direct file links visible even when skills are inactive
- low migration friction: existing `agents-cli` users keep `fabric-builder`, `fast-networking` and `fast-prerequisites` under the same installed names because only internal repository paths in `agents-cli-extension.yaml` changed, while contributors referencing `skills/contributing`, `skills/maintenance/release-process` or `GEMINI.md` move to the new paths (documented with an `upgrade-note`)
- repeatable skill evolution: pairing the mining-to-evaluation workflow with the upcoming public evaluation suite gives maintainers a mechanical way to evolve deep FAST skills and test new models against frozen snapshots

## Validation

### Suite and measurement protocol

We validated Wave 1 mechanically against a frozen 34-item post-cutoff evaluation suite. Every contributor and pull-request review task comes from Fabric pull requests merged after 22 March 2026 and is pinned to its pre-PR parent commit through `git archive`:

| Slice | Items | Count | Sandbox surface | Grading |
| --- | --- | --- | --- | --- |
| Contributor design | `C01` to `C10` | 10 | Read-only repo checkout | Offline 3-bucket rubric (`+/~/-`) and per-criterion hit rate |
| Composition and YAML factories | `U01` to `U10` | 10 | Writable workspace and read-only `./fabric` | Offline `terraform fmt`/`init`/`plan`, resource/attribute checks, JSON schema validation and `conventions.md` lint |
| Honest-stop and boundaries | `H01` to `H06` | 6 | Mixed (`user`, `contributor`, editable) | Mechanical exit slot (`stop_and_clarify`), `imm_w == 0` and semantic verification |
| Pull-request review | `P01` to `P08` | 8 | Read-only repo checkout | Offline 3-bucket rubric (`+/~/-`) and per-criterion hit rate |

Every rollout runs inside an isolated, network-disabled `bwrap` sandbox exposing standard coding-agent tools (`read`, `bash`, `edit`, `write`, an offline `provider_schema` lookup pinned to `hashicorp/google` and `hashicorp/google-beta` `8.10.0` and a non-penalized `stop_and_clarify` exit slot). All compared arms share fixed decoding parameters (`temperature=0.7`, `top_p=0.95`, `top_k=20`, `presence_penalty=0.0`, `seed=42`, `max_turns=100` and `reasoning_effort=medium`).

Before execution, the runner strips `skills/`, `AGENTS.md`, `GEMINI.md` and `agents-cli-extension.yaml` from every materialized snapshot so historical files never leak across conditions. Bare arms run against the stripped human repository alone, while skill arms overlay only the tested commit's coupled `AGENTS.md`/`GEMINI.md` and `skills/` tree through `<available_skills>` discovery (plus offline `fabric.py` shims in consumer mode).

In the results table below, `+ / ~ / -` is strictly ordered: `+` is idiomatic, maintainer-grade Fabric meeting all core criteria, `~` is a coherent partial design or review (or a verified schema-gap stop), and `-` is a wrong module boundary, missed core requirement, rubber-stamped broken pull request or premature stop. `Strict` counts `+` on Design and PR review, full deterministic pass on Composition and verified valid stops on Honest-stop (`x/34`). `imm_w` counts attempted writes to read-only fixtures (`0` required).

### Results across models

We measured Bare, pre-revamp `master` and Wave 1 across 2 model tiers (a compact local dense coding model, `Qwen3.8-27B`, and a stronger MoE validator, `Qwen3.8-Flash-Next`) alongside a `Qwen3.6-35B-A3B` bare floor:

| Model | Condition | Design (`+/~/-`, crit) | PR review (`+/~/-`, crit) | Comp (`plan` / full) | Honest-stop (`m/v`) | `imm_w` | Strict | Avg / item (`turns · tok`) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Qwen3.6-35B-A3B` | Bare | `0 / 2 / 8` (`42.7%`) | `0 / 3 / 5` (`28.1%`) | `10/10` / `1/10` | `3/6` / `3/6` | `1` | `4/34` | `17.7t · 7.2k` |
| `Qwen3.8-27B` | Bare | `0 / 9 / 1` (`58.4%`) | `0 / 7 / 1` (`51.9%`) | `10/10` / `0/10` | `4/6` / `3/6` | `0` | `3/34` | `18.9t · 12.2k` |
| `Qwen3.8-27B` | `master` | `0 / 8 / 2` (`60.3%`) | `2 / 6 / 0` (`56.4%`) | `10/10` / `7/10` | `5/6` / `5/6` | `0` | `14/34` | `16.4t · 9.9k` |
| `Qwen3.8-27B` | Wave 1 | `1 / 8 / 1` (`61.8%`) | `4 / 4 / 0` (`72.9%`) | `10/10` / `9/10` | `5/6` / `4/6` | `0` | `18/34` | `16.8t · 11.3k` |
| `Qwen3.8-Flash-Next` | Bare | `0 / 8 / 2` (`59.5%`) | `3 / 5 / 0` (`62.5%`) | `10/10` / `0/10` | `5/6` / `4/6` | `0` | `7/34` | `27.7t · 16.2k` |
| `Qwen3.8-Flash-Next` | `master` | `1 / 7 / 2` (`57.7%`) | `3 / 5 / 0` (`63.5%`) | `9/10` / `9/10` | `5/6` / `5/6` | `1` | `18/34` | `24.6t · 15.1k` |
| `Qwen3.8-Flash-Next` | Wave 1 | `3 / 5 / 2` (`68.9%`) | `7 / 1 / 0` (`80.9%`) | `10/10` / `10/10` | `6/6` / `6/6` | `0` | `26/34` | `24.6t · 14.5k` |

We also verified a final tightening pass on `skills/maintainer/cff-pr-review/SKILL.md` (leaving every other skill file unchanged) on the `pr_review` slice across both tiers. On `Qwen3.8-Flash-Next`, PR review held `7 / 1 / 0` (0 broken) while lifting per-criterion accuracy from 80.9% to 85.0% (`34/40`) and cutting average PR-review turns from `23.4t` to `20.1t`. On `Qwen3.8-27B`, PR review held `4/8` `+` and recovered Step 1 single-resource-wrapper rejection on `P02` (`4/4` in 10 turns).

Four broad shifts explain the `14 -> 18/34` (`Qwen3.8-27B`) and `18 -> 26/34` (`Qwen3.8-Flash-Next`) lift over `master`:

- skill activation reached 100% across every slice on both tiers (`10/10` `cff-contributing`, `8/8` `cff-pr-review`, `10/10` `fabric-builder` and `3/3` `references/factories.md` on YAML factory tasks) with 0 read-only write violations
- PR review showed the largest gain on both models (`2/6/0` 56.4% to `4/4/0` 72.9% on `Qwen3.8-27B`, and `3/5/0` 63.5% to `7/1/0` 85.0% on `Qwen3.8-Flash-Next`)
- composition reached `10/10` strict pass on `Qwen3.8-Flash-Next` and `9/10` (`10/10` plan) on `Qwen3.8-27B`, fixing `master`'s YAML factory plan failure on `U01`
- contributor design rose from `1/7/2` (57.7%) to `3/5/2` (68.9%) on `Qwen3.8-Flash-Next`, while honest-stop reached `6/6` verified stops (`H01` to `H06`)

### Design lessons from ablations

Three empirical findings from Wave 1 iterations and controlled ablations should guide future skill authoring:

- selective progressive disclosure ('Open only the 1–2 guides whose trigger appears in the diff') protects attention on both compact and larger models: a controlled 1-line ablation that relaxed the rule to opening every triggered guide regressed both `Qwen3.8-Flash-Next` (`7/1/0` 85.0% to `4/4/0` 76.2%, `20.1t` to `25.5t`) and `Qwen3.8-27B` (`4/3/1` 66.0% to `3/5/0` 64.4%)
- rationale-first rules prevent fabricated blocking nits because explaining why per-module `versions.*` stay synced from `default-versions.*`, why `project-factory` stays at 2 passes and why older single-resource modules are legacy gives models the reasoning needed to judge edge cases accurately
- explicit parity rules and exhaustive diff-wide sweeps materially improve PR review because separating unrelated cross-module churn from required wiring in paired aggregation factories (`net-vpc` / `net-vpc-factory`, `project` / `project-factory`) and full-surface `var.context` coverage stops models from dismissing needed wiring as out of scope, while sweeping every modified block catches nested `null` crashes and empty `dynamic` permadiffs that single-defect stops miss

### Next steps for Wave 2

Three focused items remain for Wave 2 once this branch merges:

- close the residual `P03` PR-review gaps still missed on both tiers (`location = null` in `lower(v.location)`, nullable map-entry values in OpenTofu `validation` blocks, `local.ctx.locations` interpolation and `google_project_iam_member.service_agents` in `depends_on`)
- raise Contributor Design alignment (`C01` to `C10`), starting with target-side ownership on `C05` (`modules/organization` and `modules/vpc-sc`) and the remaining `Provider/AdHoc` near-misses
- expand deep FAST stage guidance and publish the sanitized evaluation suite alongside the revamped `tools/skill-turn-harness/`
