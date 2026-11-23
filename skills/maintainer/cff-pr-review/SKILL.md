---
name: cff-pr-review
description: "Maintainer pull request review guide for Cloud Foundation Fabric. Use when reviewing a Fabric GitHub PR or local branch diff for architectural fit, canonical module and factory interfaces, HCL and OpenTofu correctness, test inventory accuracy, FAST blast radius, and repository hygiene."
---

# Reviewing Cloud Foundation Fabric Pull Requests

Maintainer-facing PR review skill for Cloud Foundation Fabric (CFF). Focuses strictly on diagnosing an existing pull request or branch diff and delegates canonical criteria to [cff-contributing](../../contributor/cff-contributing/SKILL.md) with zero rule duplication.

## Step 0: Intake and Checkout Safety

1. **Inspect the full PR or diff:** For a GitHub PR, run `gh pr view <n> --json title,body,author,baseRefName,headRefName,labels,files,statusCheckRollup,closingIssuesReferences`, `gh pr checks <n>`, and `gh pr diff <n>`. For a local branch, inspect `git diff master...HEAD` and `git status`.
2. **Stay read-only on remote PRs:** Do not run `gh pr checkout`, switch git branches, or modify the maintainer's working tree without asking first; inspect remote files with `gh api` or `git show`.
3. **Read full files, not just hunks:** Inspect the complete modified `.tf`, `.schema.json`, and test files, any linked issue, and at least one sibling module in the same family before judging.
4. **Check CI first:** Skip repeating failures CI already caught; spend review effort on architectural fit, ergonomics, subtle runtime bugs, and test inventory intent.

## Step 1: Architectural Triage (Stop Before Nitpicking)

Decide whether the PR belongs at its proposed boundary before reviewing lines. Open [design/modules.md](../../contributor/cff-contributing/design/modules.md) only when module scope or binding ownership is in question, and [design/factories.md](../../contributor/cff-contributing/design/factories.md) only when the diff touches factories, schemas, `project-factory`, or `net-vpc-factory`:

1. **Boundary & ownership:** Check logical-entity fit (reject thin single-resource wrappers, standalone feature modules, unrelated resource bundles outside `project-factory`/`net-vpc-factory`, companion project IAM in service modules) and `organization`/`folder`/`project` unison.
2. **Factory DAG acyclicity:** In `modules/project-factory`, verify `module.projects` (Pass 1) -> `module.kms`/`service-accounts` -> `module.projects-iam` (Pass 2: IAM, org policies, CMEK) -> post-Pass 2 encrypted sub-resources (`module.buckets`, `module.log-buckets`, `module.pubsub`) stays acyclic with no duplicate creation across passes.
3. **PR cohesion:** Flag unrelated refactors, drive-by churn, or mixed changes that should be split into separate PRs.

When Step 1 fails (wrong boundary, thin wrapper, or broken DAG), the implementation will be redesigned before its line details matter. Lead with the architectural objection and right destination, and **stop without running Step 3 line-level audits**.

## Step 2: Verify Every Claim Before Commenting

Never file a technical objection from memory or from partial PR snippets:

1. **Released provider docs:** Check [default-versions.tf](../../../default-versions.tf) and verify resource arguments, defaults, `ForceNew`, and `google` vs `google-beta` availability against a **released** provider tag (see [workflow/pr-lifecycle.md](../../contributor/cff-contributing/workflow/pr-lifecycle.md#pre-design-research-commands) for the raw-markdown fallback).
2. **Siblings & ADRs:** Cross-check naming, types, and layout against golden-path siblings (`project`, `compute-vm`, `net-vpc`, `project-factory`, `net-vpc-factory`, `vpc-sc`) and [adrs/](../../../adrs/) (golden-path code wins over `Draft`/`Proposed` ADRs).
3. **HCL & test semantics:** Verify suspected Terraform/OpenTofu edge cases against [conventions/hcl.md](../../contributor/cff-contributing/conventions/hcl.md#terraform-and-opentofu-runtime-traps) and [CURSED_KNOWLEDGE.md](../../../CURSED_KNOWLEDGE.md). Remember `locals {}` is an unordered DAG, `nullable = false` cannot pair with `default = null`, and bare `test_name:` keys in `tftest.yaml` are valid shorthand for convention-named `<test_name>.tfvars` / `<test_name>.yaml` cases.

## Step 3: Selective Diff-Triggered Audit

Each guide covers one layer of the repo; reading guides for untouched surfaces dilutes attention on the diff and invites false positives (like asking a non-factory module for `schemas/` or `FACTORIES.md`). Open **only** the 1–2 guides whose trigger appears in the diff, and never cite a guide or tool you did not inspect:

| Diff touches... | Canonical guide | Reviewer focus |
| :--- | :--- | :--- |
| Module scope, bindings, `data`/`local-exec`, or `outputs*.tf` | [design/modules.md](../../contributor/cff-contributing/design/modules.md) | Primary output `depends_on` on internal IAM/APIs with deliberate tiering; challenge `data`/`local-exec`; verify `organization`/`folder`/`project` unison. |
| `variables*.tf` or caller-facing interface | [design/interfaces.md](../../contributor/cff-contributing/design/interfaces.md) | Flag raw 1:1 provider mirroring, invalid product-subtype attributes, redundant flags or boilerplate locals, explicit `optional()` defaults risking drift, `any`, missing enum `validation`, missing `context`/`_vars` where siblings support it, non-canonical `iam*`/`tag_bindings`/secret shapes, and unguarded breaking changes (`moved {}`, `upgrade-note`). |
| `factories_config`, `schemas/`, `project-factory`, `net-vpc-factory` | [design/factories.md](../../contributor/cff-contributing/design/factories.md) | Multi-pass DAG acyclicity; avoid blind `data_defaults`/`data_overrides`/`data_merges` plumbing on high-risk fields; `.schema.json`, `.schema.md`, [tools/duplicate-diff.py](../../../tools/duplicate-diff.py), and [FACTORIES.md](../../../FACTORIES.md) in sync. Skip for non-factory modules. |
| `fast/` or high-blast-radius module (`project`, `folder`, `organization`, `net-vpc*`, `vpc-sc`, `net-cloud-armor`, `billing-account`, `iam-service-account`) | [design/fast.md](../../contributor/cff-contributing/design/fast.md) | Stage contract stability, byte-identical schema copies in [tools/duplicate-diff.py](../../../tools/duplicate-diff.py), standalone usability, 10-char prefix budget. |
| Internal `.tf` logic (`locals`, `for_each`, `count`, `dynamic`, lifecycle) | [conventions/hcl.md](../../contributor/cff-contributing/conventions/hcl.md) | Explicit-`null` `try(var.x.y, {})` crashes (`try()` returns `null`), silent no-op `count` on nested nullable fields, empty-body `dynamic` permadiffs or `== true` vs `!= null`, OpenTofu breaks (`provider::`, ternary branch types, nullable collections), `try()` on partially-known `for_each`, `create_before_destroy` map contagion, `ignore_changes` vs additive child resources, `.name` vs `.id`. |
| `tests/` or `README.md` `# tftest` examples | [workflow/testing.md](../../contributor/cff-contributing/workflow/testing.md) | Coverage for new/changed behavior; audit every changed line in `tests/.../*.yaml` inventories (surprise diffs indicate HCL bugs); challenge `skip-tofu`/`e2e`/`skip`; flag stray `terraform_data` debug blocks. |
| `versions.*`, `default-versions.*`, `README.md` tables, `CHANGELOG.md`, PR metadata | [workflow/pr-lifecycle.md](../../contributor/cff-contributing/workflow/pr-lifecycle.md) | Every module keeps its own `versions.tf`/`versions.tofu` synced from `default-versions.*` via [tools/versions.py](../../../tools/versions.py) for consumer composability — flag divergent edits or extra providers (never ask to delete per-module `versions.*`); leave `CHANGELOG.md` to release automation; check `tfdoc`, PII leaks, PR title style, `upgrade-note`, and `on:*` labels. |

## Step 4: Output Discipline and Posting Gate

1. **Verdict first:** State `Approve`, `Request changes`, or `Comment (architectural discussion needed)` plus a 1–2 sentence summary.
2. **Blocking vs Nits:** Separate **Blocking** defects (boundary, correctness/OpenTofu/permadiff bugs, unguarded breaking changes, missing schema/FAST/unison sync, unexplained test diffs, PII) from **Suggestions / Nits**.
3. **Verified evidence only:** Cite exact `path:line` from files read, explain why using verified docs/siblings/rules, and suggest an idiomatic fix. Never cite unread files/scripts or invent nits on a clean PR; never imitate CI's `Automated PR Review` format or add status tables/emojis.
4. **Blocking Gate — Maintainer Approval Before GitHub Writes:** Present the full drafted review first. Never run `gh pr review`, `gh pr comment`, `gh pr edit`, or `gh pr merge` without explicit approval; if running non-interactively, output the review and stop.
