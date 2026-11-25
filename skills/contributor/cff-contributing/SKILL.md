---
name: cff-contributing
description: "Design-first contributor guide and PR workflow for Cloud Foundation Fabric. Use when implementing a Fabric GitHub issue, designing or modifying modules, YAML factories, schemas, or FAST boundaries, writing tftest/README tests, or preparing a Fabric pull request. For reviewing an existing PR or local branch diff, use cff-pr-review; for triaging incoming GitHub issues or sweeping the issue backlog, use cff-issue-triage instead."
---

# Contributing to Cloud Foundation Fabric

Design-first entry skill for implementing changes and preparing pull requests in Cloud Foundation Fabric (CFF). For reviewing an existing PR or local branch diff, use [cff-pr-review](../../../skills/maintainer/cff-pr-review/SKILL.md); for triaging incoming GitHub issues or sweeping the issue backlog, use [cff-issue-triage](../../../skills/maintainer/cff-issue-triage/SKILL.md) first. If implementing an existing issue, inspect it via `gh issue view <n>`, complete Step 0 and Pre-Design Research, and stop at **Design Sign-off** before writing code (skippable only for trivial, obvious fixes).

## Step 0: Fit, Boundary, and Honest-Stop Check

Before designing or coding, verify the change actually belongs in Fabric:

1. **Logical-entity test:** Modules encapsulate one complete functional unit (resource + IAM + sub-resources + org policies/sinks where relevant). Reject thin single-resource pass-through wrappers, standalone product/feature modules (such as a central IAM module), unrelated resource bundles outside `project-factory` / `net-vpc-factory`, and one-off customer topologies. End-to-end reference designs that do not fit in `modules/` or FAST belong in `fast/project-templates/` (reference implementations of designs that cannot fit in FAST) or module-level recipes (`modules/<module>/recipe-*`, GCP documentation end-to-end examples ported to Fabric).
2. **Canonical interfaces and resource-management parity:** Reuse Fabric's canonical interfaces verbatim (`iam*`, org policies, tags, log sinks, secrets, `context`, bindings) rather than inventing variants. The three resource management modules (`organization`, `folder`, `project`) always move in unison for every shared feature they support. Service modules never grant project-level companion IAM (expose wiring outputs instead).
3. **Provider selection and repo-wide version constraints:** Prefer the `google` provider, use `google-beta` only on specific resources when a feature exists only there, avoid `google-nightly`, and confirm features exist in a released provider version. Every Fabric module keeps its own `versions.tf` and `versions.tofu`, synced verbatim from root [default-versions.tf](../../../default-versions.tf) and [default-versions.tofu](../../../default-versions.tofu) via `tools/versions.py` so consumers can compose any combination of modules without provider constraint conflicts. If a feature requires a newer released provider version, update `default-versions.*` repo-wide and propagate with `tools/versions.py` (see [workflow/pr-lifecycle.md](workflow/pr-lifecycle.md#pre-design-research-commands)) rather than bumping an isolated module or introducing an extra provider.
4. **Honest stop on ambiguity:** If requirements, target boundaries, or trade-offs are under-specified, stop and ask instead of guessing an interface.
5. **Issue discipline:** If a linked GitHub issue fails the fit test, report your reasoning to the human and stop — never comment on, label, or close GitHub issues yourself.

## The Zen of Fabric

- **Design for composition:** Modules and stages compose into complete infrastructures, not isolated demos.
- **Encapsulate logical entities:** Bundle functionally coupled resources into one self-contained unit with outputs that wait for internal setup.
- **Reuse canonical interfaces and keep variable spaces compact:** Lower cognitive load across modules with consistent shapes and `optional()` objects.
- **Make prototyping trivial and production complete:** Supply sane defaults for quick prototyping while keeping every production override cleanly accessible without opinionated lock-in.
- **Write flat, legible code:** Prefer IaC-as-documentation over clever abstractions; avoid `data` sources, `local-exec`, and external tools.

## Pre-Design Research Habit

Run these checks **before** proposing an interface or editing `.tf` files:

1. **Read full released provider docs:** Never rely on partial snippets in an issue description. Check [default-versions.tf](../../../default-versions.tf) for the pinned minimum provider version (see [workflow/pr-lifecycle.md](workflow/pr-lifecycle.md#pre-design-research-commands) for the raw-markdown `curl` fallback and repo-wide version bump command).
2. **Inspect golden-path sibling modules:** Cross-check [modules/project](../../../modules/project), [modules/compute-vm](../../../modules/compute-vm), [modules/net-vpc](../../../modules/net-vpc), [modules/project-factory](../../../modules/project-factory), [modules/net-vpc-factory](../../../modules/net-vpc-factory), and [modules/vpc-sc](../../../modules/vpc-sc), plus any sibling in the same module family.
3. **Check ADRs and runtime hazards:** Scan [adrs/](../../../adrs/) by status (ignore `Rejected`, treat `Draft`/`Proposed` as directional; on conflict, current golden-path code wins) and review [CURSED_KNOWLEDGE.md](../../../CURSED_KNOWLEDGE.md).

## Reference Routing and Always-On Baselines

Each guide covers one layer of the repository. Use the baselines below on every change, and open only the 1–2 guides whose trigger matches what you are changing so your context stays focused on the actual module and sibling code.

| Guide | Always-on baseline (applies to every PR) | Open the full guide when... |
| :--- | :--- | :--- |
| [design/modules.md](design/modules.md) | Encapsulate one logical functional unit ("ready to use"); reject single-resource wrappers and cross-service/project-IAM leakage; keep `organization`/`folder`/`project` in unison; tie primary outputs with `depends_on` where appropriate. | Creating a module, changing module scope or boundaries, adding policy/tag bindings, or considering `data` sources, `local-exec`, or output dependency tiering. |
| [design/interfaces.md](design/interfaces.md) | Support quick prototyping with sane defaults while unlocking full prod control; compact `object()` + `optional()` (omit defaults unless module logic or ergonomics need them); 1–2 value attributes become booleans; maps over lists; no `any`; enum `validation`; reuse canonical Fabric shapes verbatim (`iam*`, `context` + `_vars`, secrets `{value, path, wo_version}`, `tag_bindings`, `prefix`). | Adding or changing any variable or output interface. |
| [design/factories.md](design/factories.md) | Schema, `.schema.md`, `tools/duplicate-diff.py` copies, and `FACTORIES.md` move together; in `project-factory`, `projects` -> `projects-iam` -> encrypted sub-resources (`buckets`, `log-buckets`, `pubsub`) stay acyclic. | Modifying `factories_config`, `schemas/`, `project-factory`, or `net-vpc-factory`. |
| [design/fast.md](design/fast.md) | High-blast-radius modules (`project`, `folder`, `organization`, `net-vpc*`, `vpc-sc`, `net-cloud-armor`, `billing-account`, `iam-service-account`) carry duplicated schemas/files checked by `duplicate-diff.py` and `check_yaml_schema.py`. | Changing a FAST stage or any module with FAST schema or factory impact. |
| [conventions/hcl.md](conventions/hcl.md) | 79-char lines; strict alphabetical `variables*.tf` and `outputs*.tf`; `_` private locals; `!= null` (not `== true`) on dynamic blocks; `try(var.x.y, {})` does not catch explicit `null`; no `provider::` functions (OpenTofu); `== null` instead of `try()` on partially-known `for_each` maps. | Writing non-trivial locals, `context` lookups, dynamic blocks, or resource refactors. |
| [workflow/testing.md](workflow/testing.md) | Any resource-block change requires updated test inventories (`generate_plan_summary.py --save` + mandatory `git diff tests/` audit); test directories use underscores (`tests/modules/net_vpc`); run `pytest` on impacted suites and README examples. | Authoring `# tftest` examples, `tftest.yaml` or `context` tests, or debugging locals with `terraform_data`. |
| [workflow/pr-lifecycle.md](workflow/pr-lifecycle.md) | Run `tools/lint.sh` and `tfdoc.py`; capitalized imperative PR titles (no Conventional Commits); scrub all PII; include `upgrade-note` for breaking changes; leave `CHANGELOG.md` to release automation. | Running provider research or version bumps, full CI lint checks, pre-PR self-review, live E2E sandbox verification, or PR submission. |

## Human-in-the-Loop Gates

Keep reversible mechanical steps (linting, tests, `tfdoc`, inventory regeneration) autonomous. Gates below are **blocking** — if running non-interactively and you cannot get an answer, stop rather than assuming approval.

| Gate | When | What the human decides |
| :--- | :--- | :--- |
| **Design Sign-off** | Before writing code | Approves target module(s), variable/output interface, provider include/exclude list, and any provider version bump. Mandatory for features and interface changes; skippable for trivial obvious fixes. |
| **E2E Opt-in** | After tests & self-review pass | Whether to deploy live (providing a sandbox project ID authorizes `-auto-approve` deploy and destroy). |
| **Behavioral Verification Opt-in** | After E2E read-back passes | Whether to run live runtime/traffic checks given described time and cost. |
| **PR Approval** | Before `gh pr create` | Reviews the final sanitized PR title and body. |
