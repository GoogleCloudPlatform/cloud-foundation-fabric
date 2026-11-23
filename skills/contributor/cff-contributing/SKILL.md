---
name: cff-contributing
description: "Design-first contributor guide and PR workflow for Cloud Foundation Fabric. Use when implementing a Fabric GitHub issue, designing or modifying modules, YAML factories, schemas, or FAST boundaries, writing tftest/README tests, or preparing a Fabric pull request. For reviewing an existing PR or local branch diff, use cff-pr-review; for triaging incoming GitHub issues or sweeping the issue backlog, use cff-issue-triage instead."
---

# Contributing to Cloud Foundation Fabric

Design-first entry skill for implementing changes and preparing pull requests in Cloud Foundation Fabric (CFF). For reviewing an existing PR or local branch diff, use [cff-pr-review](../../maintainer/cff-pr-review/SKILL.md); for triaging GitHub issues, use [cff-issue-triage](../../maintainer/cff-issue-triage/SKILL.md) first. When implementing an issue, inspect it via `gh issue view <n>`, complete Step 0 and Pre-Design Research, and stop at **Design Sign-off** before writing code (skippable only for trivial, obvious fixes).

## Step 0: Fit, Boundary, and Honest-Stop Check

Before designing or coding, verify the change belongs in Fabric (see root `AGENTS.md` for the repo compass):

1. **Logical-entity boundary:** Keep each module to one functional unit; redirect thin single-resource wrappers, standalone feature modules, unrelated resource bundles (outside `project-factory` / `net-vpc-factory`), and one-off topologies (`fast/project-templates/` or `modules/<module>/recipe-*`).
2. **Parity and ownership:** Reuse canonical interfaces (`iam*`, `context` + `_vars`, secrets, `tag_bindings`, `prefix`), move `organization`/`folder`/`project` in unison for shared features, and expose wiring outputs instead of granting project-level companion IAM inside service modules.
3. **Provider selection and uniform version pins:** Prefer `google`, use `google-beta` only on resources that require it, avoid `google-nightly`, and confirm features exist in a released version. Because every module carries `versions.tf`/`versions.tofu` synced from [default-versions.tf](../../../default-versions.tf) / [default-versions.tofu](../../../default-versions.tofu) via `tools/versions.py` so consumers can compose modules without constraint conflicts, needing a newer provider version is a repo-wide bump (see [workflow/pr-lifecycle.md](workflow/pr-lifecycle.md#pre-design-research-commands)) rather than an isolated edit or new provider.
4. **Honest stop & issue hygiene:** Stop and ask if requirements, boundaries, or trade-offs are under-specified. Never comment on, label, or close GitHub issues yourself.

## The Zen of Fabric

- **Design for composition:** Modules and stages compose into complete infrastructures, not isolated demos.
- **Make prototyping trivial and production complete:** Supply sane defaults for quick prototyping while keeping every production override accessible without lock-in.
- **Write flat, legible code:** Prefer IaC-as-documentation over clever abstractions; avoid `data` sources, `local-exec`, and external tools.

## Pre-Design Research Habit

Run these checks **before** proposing an interface or editing `.tf` files:

1. **Read full released provider docs:** Check [default-versions.tf](../../../default-versions.tf) for the pinned minimum provider version and verify full released `google`/`google-beta` docs (not partial issue snippets).
2. **Inspect golden-path siblings:** Cross-check [modules/project](../../../modules/project), [modules/compute-vm](../../../modules/compute-vm), [modules/net-vpc](../../../modules/net-vpc), [modules/project-factory](../../../modules/project-factory), [modules/net-vpc-factory](../../../modules/net-vpc-factory), [modules/vpc-sc](../../../modules/vpc-sc), plus same-family siblings.
3. **Check ADRs and runtime hazards:** Scan [adrs/](../../../adrs/) by status (ignore `Rejected`; on conflict with `Draft`/`Proposed`, current golden-path code wins) and check [CURSED_KNOWLEDGE.md](../../../CURSED_KNOWLEDGE.md).

## Selective Reference Routing

Each guide covers one layer of the repository. Open **only** the 1–2 guides whose trigger matches what you are changing so your context stays focused on the actual module and sibling code:

| Guide | Open when... |
| :--- | :--- |
| [design/modules.md](design/modules.md) | Creating a module, changing module scope or binding ownership, or considering `data` sources, `local-exec`, or output dependency tiering. |
| [design/interfaces.md](design/interfaces.md) | Adding or changing any caller-facing variable or output interface (prototyping defaults, `optional()`, maps vs lists, enum validation, canonical `iam*`/`context`/secret/`tag_bindings`/`prefix` shapes). |
| [design/factories.md](design/factories.md) | Modifying `factories_config`, `schemas/`, `project-factory`, or `net-vpc-factory` (multi-pass DAG, `data_defaults`/`data_overrides`/`data_merges`, schema + `duplicate-diff.py` + `FACTORIES.md` sync). |
| [design/fast.md](design/fast.md) | Changing a FAST stage or high-blast-radius module (`project`, `folder`, `organization`, `net-vpc*`, `vpc-sc`, `net-cloud-armor`, `billing-account`, `iam-service-account`). |
| [conventions/hcl.md](conventions/hcl.md) | Writing non-trivial locals, `context` lookups, `count`/`dynamic` blocks, or refactors (`try(null, {})` trap, partially-known `for_each`, OpenTofu traps, `create_before_destroy`, `ignore_changes`). |
| [workflow/testing.md](workflow/testing.md) | Authoring `# tftest` examples, `tftest.yaml` or `context` tests, updating/auditing inventory YAMLs (`generate_plan_summary.py --save`), or debugging locals with `terraform_data`. |
| [workflow/pr-lifecycle.md](workflow/pr-lifecycle.md) | Running provider doc fetches or `tools/versions.py` bumps, `tools/lint.sh`, `tfdoc.py`, pre-PR self-review, live E2E verification, or sanitized PR submission. |

## Human-in-the-Loop Gates

Keep reversible mechanical steps (linting, tests, `tfdoc`, inventory regeneration) autonomous. Gates below are **blocking** — if running non-interactively and you cannot get an answer, stop rather than assuming approval:

| Gate | When | What the human decides |
| :--- | :--- | :--- |
| **Design Sign-off** | Before writing code | Approves target module(s), variable/output interface, provider include/exclude list, and any provider version bump (mandatory for features/interfaces; skippable for trivial fixes). |
| **E2E Opt-in** | After tests & self-review pass | Whether to deploy live (a sandbox project ID authorizes `-auto-approve` deploy and destroy). |
| **Behavioral Verification Opt-in** | After E2E read-back passes | Whether to run live runtime/traffic checks given time and cost. |
| **PR Approval** | Before `gh pr create` | Reviews the final sanitized PR title and body. |
