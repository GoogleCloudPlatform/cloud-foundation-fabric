---
name: cff-pr-review
description: "Maintainer pull request review guide for Cloud Foundation Fabric. Use when reviewing a Fabric GitHub PR or local branch diff for architectural fit, canonical module and factory interfaces, HCL and OpenTofu correctness, test inventory accuracy, FAST blast radius, and repository hygiene."
---

# Reviewing Cloud Foundation Fabric Pull Requests

Maintainer-facing PR review skill for Cloud Foundation Fabric (CFF). This skill focuses strictly on diagnosing an existing pull request or branch diff and delegates all canonical design, convention, and testing criteria to [cff-contributing](../../contributor/cff-contributing/SKILL.md) with zero rule duplication.

## Step 0: Intake and Checkout Safety

1. **Inspect the full PR or diff:** For a GitHub PR, fetch metadata, checks, linked issues, and diff via `gh pr view <n> --json title,body,author,baseRefName,headRefName,labels,files,statusCheckRollup,closingIssuesReferences`, `gh pr checks <n>`, and `gh pr diff <n>`. For a local branch, inspect `git diff master...HEAD` and `git status`.
2. **Stay read-only on remote PRs:** Never run `gh pr checkout`, switch git branches, or modify the maintainer's working tree without asking first. Read remote files with `gh api` or `git show` when full-file context is needed; run local `tools/lint.sh` or `pytest` only when reviewing the currently checked-out branch or when explicitly asked.
3. **Read full files, not just diff hunks:** Inspect the complete modified `.tf`, `.schema.json`, and test files, any linked GitHub issue, and at least one sibling module in the same family before forming judgments.
4. **Check CI signal first:** Inspect `statusCheckRollup` / `gh pr checks` so you do not repeat failures CI already caught. Focus review effort on what automated checks cannot judge — architectural fit, interface ergonomics, subtle runtime bugs, and test inventory intent.

## Step 1: Architectural Triage (Stop Before Nitpicking)

Before reviewing individual lines, decide whether the PR belongs in Fabric at its proposed boundary. Load [design/modules.md](../../contributor/cff-contributing/design/modules.md) and [design/factories.md](../../contributor/cff-contributing/design/factories.md) and verify:

1. **Logical-entity fit:** Reject thin single-resource pass-through wrappers, standalone feature modules (such as central IAM or tag-binding modules), unrelated resource bundles outside `project-factory` / `net-vpc-factory`, and one-off reference architectures that belong in `fast/project-templates/` or `modules/<module>/recipe-*`.
2. **Ownership and resource-management unison:** Reject project-level companion IAM added inside service modules (expose wiring outputs instead), flag target-side vs policy-side binding ownership violations, and verify that shared capabilities across `organization`, `folder`, and `project` move in unison with identical interfaces.
3. **Factory placement and DAG acyclicity:** In `modules/project-factory`, reject any Pass 1 dependency back onto Pass 2 outputs or duplicate creation across passes. In FAST stages, push back on stage-level factories that belong inside a module.
4. **PR cohesion:** Flag unrelated refactors, drive-by formatting churn, or mixed changes that should be split into separate PRs.

If Step 1 fails, lead your review with the architectural objection and stop — do not bury a fundamental redesign or rejection under line-level nits.

## Step 2: Verify Every Claim Before Commenting

Never file a technical objection from memory or from partial snippets in a PR description:

1. **Verify against released provider docs:** Check the pinned minimum provider version in [default-versions.tf](../../../default-versions.tf) and confirm resource arguments, defaults, `ForceNew` behavior, and `google` vs `google-beta` availability against a **released** provider tag (see [workflow/pr-lifecycle.md](../../contributor/cff-contributing/workflow/pr-lifecycle.md#pre-design-research-commands) for the raw-markdown fetch fallback).
2. **Verify against sibling modules and ADRs:** Cross-check naming, variable shapes, and file layout against golden-path modules (`project`, `compute-vm`, `net-vpc`, `project-factory`, `net-vpc-factory`, `vpc-sc`, plus same-family siblings) and accepted ADRs in [adrs/](../../../adrs/) (on conflict with `Draft`/`Proposed` ADRs, current golden-path code wins).
3. **Verify runtime hazards:** Confirm suspected Terraform or OpenTofu edge cases against [conventions/hcl.md](../../contributor/cff-contributing/conventions/hcl.md#terraform-and-opentofu-runtime-traps) and [CURSED_KNOWLEDGE.md](../../../CURSED_KNOWLEDGE.md).

## Step 3: Diff-Triggered Audit Routing

For every surface touched by the diff, open the linked canonical guide and run the reviewer-specific checks below:

| Diff touches... | Canonical criteria | Reviewer-specific checks on the diff |
| :--- | :--- | :--- |
| New module, scope change, bindings, `data` sources, `local-exec`, or `outputs*.tf` | [design/modules.md](../../contributor/cff-contributing/design/modules.md) | Verify primary outputs tie internal setup (IAM, APIs, service identities) with `depends_on` while applying deliberate dependency tiering rather than blind chaining; challenge any `data` source or undocumented `local-exec`; verify `organization`/`folder`/`project` unison. |
| Any `variables*.tf` or caller-facing interface change | [design/interfaces.md](../../contributor/cff-contributing/design/interfaces.md) | Flag 1:1 raw provider mirroring, invalid attributes for a GCP product subtype, redundant booleans/flags or over-engineered locals, explicit `optional()` defaults that risk provider drift, `any` types, missing enum `validation`, missing `context` (or missing `_vars` exclusion) where siblings support it, non-canonical `iam*`/`tag_bindings`/secret (`{value, path, wo_version}`) shapes, and breaking changes missing `moved {}` blocks or `**Breaking Changes**` + `upgrade-note`. |
| `factories_config`, `schemas/`, `project-factory`, or `net-vpc-factory` | [design/factories.md](../../contributor/cff-contributing/design/factories.md) | Verify Pass 1 vs Pass 2 placement and DAG acyclicity; verify `data_defaults` / `data_overrides` / `data_merges` are not plumbed blindly onto high-risk fields; confirm `.schema.json`, `.schema.md`, [tools/duplicate-diff.py](../../../tools/duplicate-diff.py) copies, and [FACTORIES.md](../../../FACTORIES.md) all updated together. |
| Any `fast/` file or high-blast-radius module (`project`, `folder`, `organization`, `net-vpc*`, `vpc-sc`, `net-cloud-armor`, `billing-account`, `iam-service-account`) | [design/fast.md](../../contributor/cff-contributing/design/fast.md) | Check stage contract map stability, byte-identical schema copies in [tools/duplicate-diff.py](../../../tools/duplicate-diff.py), standalone stage usability, and 10-character prefix name budgets (`check_names.py`). |
| Internal `.tf` logic (`locals`, `for_each`, `dynamic`, lifecycle blocks) | [conventions/hcl.md](../../contributor/cff-contributing/conventions/hcl.md) | Catch OpenTofu breaks (`provider::` functions, mismatched ternary branch types, unguarded nullable collections), `try()` collapsing partially-known `for_each` maps, `== true` instead of `!= null` on dynamic blocks (permadiffs), `create_before_destroy` contagion across map outputs, `ignore_changes` colliding with additive child resources, and `.name` instead of `.id` cross-resource references. |
| `tests/` or `README.md` `# tftest` examples | [workflow/testing.md](../../contributor/cff-contributing/workflow/testing.md) | Require tests covering new or changed behavior; inspect **every** changed line in `tests/.../*.yaml` inventories (treat unexplained attribute drops, resource count shifts, or surprise diffs as HCL bugs rather than regenerated baselines); challenge any `skip-tofu` or `# tftest skip` justification; flag stray `terraform_data` debug resources. |
| `versions.*`, `default-versions.*`, `README.md` tables, `CHANGELOG.md`, or PR metadata | [workflow/pr-lifecycle.md](../../contributor/cff-contributing/workflow/pr-lifecycle.md) | Reject per-module hand edits to `versions.tf`/`versions.tofu` (version bumps must be repo-wide via [tools/versions.py](../../../tools/versions.py) and justified by a released provider feature); reject contributor edits to `CHANGELOG.md`; check for stale `tfdoc` tables, leaked PII (real project IDs, project numbers, personal emails, custom org/sandbox names), Conventional Commits prefixes in the PR title, missing `**Breaking Changes**`/`upgrade-note`, and expected `on:*` labels. |

## Step 4: Review Output Discipline and Posting Gate

1. **Lead with a clear verdict:** State `Approve`, `Request changes`, or `Comment (architectural discussion needed)` followed by a 1–2 sentence summary of what the PR does and its main risk or readiness.
2. **Separate blocking defects from nits:** Group findings strictly into **Blocking** (architectural fit, correctness/OpenTofu/permadiff bugs, unguarded breaking changes, missing schema/FAST/unison sync, missing or unexplained test diffs, PII leaks) and **Suggestions / Nits** (ergonomics, naming polish, minor cleanup).
3. **Ground every finding in evidence:** Cite exact `path:line`, state why it matters using verified provider docs, sibling modules, or canonical rules, and offer a concrete idiomatic alternative or direct question. Never fabricate nits to look thorough — if the PR is clean, say so briefly and recommend approval. Never imitate CI's `Automated PR Review` format or add decorative status tables or emojis.
4. **Blocking Gate — Maintainer Approval Before GitHub Writes:** Present the complete drafted review (verdict, summary, and inline comments) to the maintainer first. **Never** run `gh pr review`, `gh pr comment`, `gh pr edit`, or `gh pr merge` without explicit approval; if running non-interactively, output the drafted review and stop.
