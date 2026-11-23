---
name: cff-issue-triage
description: "Maintainer GitHub issue triage guide for Cloud Foundation Fabric. Use when triaging incoming Fabric issues or reviewing the issue backlog to classify bugs, feature requests, questions, duplicates, or out-of-scope proposals, verify claims against current code and released provider docs, recommend labels and disposition, draft maintainer replies, and optionally hand off directly into cff-contributing for implementation."
---

# Triaging Cloud Foundation Fabric Issues

Maintainer-facing GitHub issue triage skill for Cloud Foundation Fabric (CFF). This skill focuses on evaluating incoming issues (individually or across a backlog sweep), delegates all canonical design and boundary criteria to [cff-contributing](../../contributor/cff-contributing/SKILL.md) with zero rule duplication, and flows directly into `cff-contributing` when the maintainer decides to implement the issue.

## Step 0: Intake, Duplicates, and Stale-Version Check

1. **Fetch issue context:** For a single issue, run `gh issue view <n> --json number,title,body,author,labels,comments,state,createdAt,updatedAt`. For a backlog sweep, list open issues via `gh issue list --state open --limit <n> --json number,title,labels,createdAt,updatedAt` and summarize candidates before diving deep into individual threads.
2. **Search for duplicates and existing PRs first:** Query open and closed issues and PRs (`gh issue list --state all --search "<keywords>"` and `gh pr list --state all --search "<keywords>"`) before diagnosing from scratch — many reports are already fixed on `master`, addressed by an open PR, or duplicate an earlier discussion.
3. **Compare reported versions against `master`:** Check the reporter's Fabric release/commit and Terraform/OpenTofu/provider versions against current `master` and [default-versions.tf](../../../default-versions.tf). Confirm a bug still reproduces on current code before accepting it.
4. **Stay read-only until approved:** Never mutate GitHub state (`gh issue comment`, `gh issue edit`, `gh issue close`) or switch git branches during triage without explicit maintainer approval.

## Step 1: Classification and Architectural Fit Check

Classify the issue and check whether it belongs in Fabric before proposing any design:

- **Bug (`bug`):** Reproducible defect in a Fabric module, factory, FAST stage, schema, or tool on current `master` (distinguish from upstream provider bugs, GCP API constraints, or consumer misconfiguration).
- **Feature request (`enhancement`):** Evaluate against [design/modules.md](../../contributor/cff-contributing/design/modules.md) and [design/factories.md](../../contributor/cff-contributing/design/factories.md):
  - Reject thin single-resource pass-through wrappers, standalone feature modules (such as central IAM or tag-binding modules), unrelated resource bundles outside `project-factory` / `net-vpc-factory`, and project-level companion IAM inside service modules.
  - Redirect one-off or end-to-end reference architectures to `fast/project-templates/`, `modules/<module>/recipe-*`, or consumer repositories.
  - Identify cross-module parity and FAST blast radius early: shared resource-management capabilities must move in unison across `organization`, `folder`, and `project`, and high-blast-radius module changes must account for [design/fast.md](../../contributor/cff-contributing/design/fast.md).
- **Usage question / support (`question`):** General GCP, Terraform, or architecture questions belong in GitHub Discussions rather than the issue tracker.
- **Duplicate / Already fixed / Invalid / Out of scope (`duplicate`, `invalid`, `wontfix`):** Cite the exact issue, PR, commit, existing variable, or ADR that resolves or precludes the request.

## Step 2: Verify Against Current Code, Provider Docs, and ADRs

Never triage from memory or rely on partial snippets pasted into the issue body:

1. **Inspect current Fabric code:** Read the target module or FAST stage (`variables*.tf`, `.tf`, `schemas/`, `README.md`) and relevant golden-path siblings (`project`, `compute-vm`, `net-vpc`, `project-factory`, `net-vpc-factory`, `vpc-sc`) to confirm whether the capability already exists, is partially covered, or conflicts with an existing interface.
2. **Verify released provider support:** Check [default-versions.tf](../../../default-versions.tf) and read the full **released** `google` or `google-beta` provider documentation (see [workflow/pr-lifecycle.md](../../contributor/cff-contributing/workflow/pr-lifecycle.md#pre-design-research-commands) for the raw-markdown fetch fallback). Confirm whether the requested feature exists in a released provider version, requires `google-beta`, requires a repo-wide minimum version bump via [tools/versions.py](../../../tools/versions.py), or is blocked upstream on the provider or GCP API.
3. **Check ADRs and runtime hazards:** Scan [adrs/](../../../adrs/) by status (ignore `Rejected`; treat `Draft`/`Proposed` as directional; on conflict, current golden-path code wins) and cross-check [CURSED_KNOWLEDGE.md](../../../CURSED_KNOWLEDGE.md).

## Step 3: Triage Disposition, Labels, and GitHub Write Gate

Present a concise triage brief to the maintainer:

1. **Recommended disposition:** One of `Accept (ready for design/implementation)`, `Accept (blocked upstream on provider/GCP)`, `Needs info`, `Redirect to Discussions / docs`, `Duplicate of #<n>`, or `Close (wontfix / already fixed / out of scope)`.
2. **Evidence and blast radius:** Exact Fabric files/symbols checked, released provider version findings, any `organization`/`folder`/`project` unison or FAST/schema blast radius, and whether the change implies a breaking change or a repo-wide provider version bump.
3. **Recommended labels:** Choose from the repository's labels — type/disposition (`bug`, `enhancement`, `question`, `duplicate`, `invalid`, `wontfix`) and area (`on:modules`, `on:FAST`, `on:blueprints`, `on:tools`, `on:documentation`).
4. **Draft reply comment:** Short, constructive, factual maintainer response citing concrete variables, docs, PRs, or requested reproduction details.
5. **Blocking Gate — Maintainer Approval Before GitHub Writes:** Present the disposition, labels, and drafted comment first. **Never** run `gh issue comment`, `gh issue edit`, or `gh issue close` without explicit approval; if running non-interactively, output the triage brief and stop.

## Step 4: Handoff to Implementation (`cff-contributing`)

If the maintainer decides during or after triage to go ahead and implement the fix or feature directly:

1. **Transition into [cff-contributing](../../contributor/cff-contributing/SKILL.md) (Mode B — Proactive Development):** Do not restart Mode A triage from scratch — carry forward the verified issue scope, target module(s), released provider findings, and cross-module/FAST blast radius already established in Steps 1–2.
2. **Enter at Design Sign-off:** Load [design/interfaces.md](../../contributor/cff-contributing/design/interfaces.md) (plus [design/factories.md](../../contributor/cff-contributing/design/factories.md), [design/fast.md](../../contributor/cff-contributing/design/fast.md), or [conventions/hcl.md](../../contributor/cff-contributing/conventions/hcl.md) as triggered) and propose the concrete variable/output interface, provider include/exclude list, and any required provider version bump for **Design Sign-off** before creating a branch or editing `.tf` files.
3. **Link the issue on PR creation:** Carry `Fixes #<n>` (or `Closes #<n>`) into the final sanitized PR body prepared under [workflow/pr-lifecycle.md](../../contributor/cff-contributing/workflow/pr-lifecycle.md#sanitized-commit-and-pr-submission).
