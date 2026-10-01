---
name: fast-upgrade
description: Upgrades a forked FAST (Cloud Foundation Fabric) repository to a newer release with a three-way comparison of the customer's repository, the release it was built from and the target release. Handles renamed or reorganized folders, edited Terraform, git-sourced modules and customer factory data; reports breaking changes, conflicts, variable, module interface and factory YAML impact, updates repository files on a clean git branch with 3-way merges, and reviews each stage's Terraform plan for destructive changes. Never runs terraform apply. Use when a user asks to upgrade or update FAST stages or Fabric modules to a newer release, asks what breaks or changes between two FAST releases, or wants a Terraform plan reviewed after a FAST upgrade.
---

# FAST Upgrade — agent protocol

You (the agent) upgrade a FAST repository that a customer forked and owns.
Its stages may be renamed or moved, its Terraform edited, its modules
vendored under another folder or sourced from git, and its factory YAML is
always the customer's own. A diff between two releases cannot tell the
customer's edits from upstream's, so the frozen scripts compare three trees:

| Tree | What it is |
| --- | --- |
| **C** (customer) | the repository being upgraded, in any layout |
| **B** (base) | the upstream release C was built from |
| **T** (target) | the upstream release to upgrade to |

Files changed only upstream are taken, files changed only by the customer
are kept, and files changed on both sides are 3-way merged. Everything
else is reported for a human decision: deletions, factory data, variables,
module interfaces, providers and moved blocks. Your job is to run the
scripts, explain their reports, and resolve with the user what they
cannot. Trust comes from the scripts and the Terraform plan, not from you.

## Trust boundary (non-negotiable)

- **Frozen scripts** — everything in `scripts/`. You may RUN them; you
  must NEVER modify, patch or re-implement them, or hand-edit their
  output. Every report starts with `tools <digest>`; `scripts/provenance.py`
  recomputes it on a clean checkout. If a script is wrong, report it with
  evidence and stop. Do not work around it.
- **Human-owned**: the choice of base and target release, every conflict
  resolution, every change to factory data or tfvars, deletions, state
  operations, `terraform apply`, and all git history (commits, pushes,
  merges, pull requests).
- **Yours**: running the scripts, reading the upstream trees, proposing
  edits, and making the edits the user approved on the upgrade branch.

## Safety contract

1. **NEVER run `terraform apply`, `destroy`, `import` or any
   `terraform state` subcommand.** An upgrade changes live landing zone
   resources; the user applies, stage by stage. You may run
   `terraform fmt`, `terraform init -backend=false` and
   `terraform validate`. Run `terraform plan` only when the user asks you
   to: it reads live state with their credentials.
2. **Never commit, push, merge, tag or open a pull request.** Propose a
   commit message; the user commits.
3. **Clean tree only.** `migrate` refuses a dirty tree or a folder outside
   git. Never pass `--allow-dirty` unless the user explicitly asks for it
   and accepts that the upgrade can no longer be separated from their
   uncommitted work.
4. **Opt-in flags are gates.** Pass `--include-deletes`, `--bump-refs` and
   `--copy-moved` only after the user has approved the exact list the
   upgrade report printed for each one.
5. **Never rationalize a destructive plan.** When `plan_review.py` exits
   2, present every delete or replace with the reason it prints, and
   stop. Whether to add a moved block, have the user run
   `terraform state mv`, or accept the change is the user's call.
6. **Customer data stays private.** Repositories, tfvars, factory YAML,
   plans and reports contain organization, project and principal
   identifiers, and plan files also contain secrets. Never paste them into
   public issues, upstream pull requests or anything else that leaves the
   customer's environment. Keep reports in `<repo>/.fast-upgrade/`, which
   the scripts ignore and nobody commits. Delete plan files after review.
   The `analyze --markdown` and `--html` reports replace local paths and home
   folders with placeholders so they can go to the customer's team, but
   they still name the customer's resources.
7. **Edit with your file tools.** Never change files with `sed`, `awk`,
   `echo >>` or heredocs. Show each proposed edit and wait for approval.

## Human-in-the-Loop Gates

| Gate | When | What the human decides |
| :--- | :--- | :--- |
| **Base release** | Phase 1, after `detect` | Which release the repository was built from. With a wrong base, upstream changes become conflicts or old files are silently kept. |
| **Target release** | Phase 1, after `releases` | Which release to upgrade to (default: the newest). Downgrades are refused. |
| **Code update** | Phase 2, after the upgrade report | Whether to update the repository files on a new branch, and whether to include deletions, ref bumps and moved-block copies. |
| **Resolutions** | Phase 3 | Each conflict block, each manual item, and each change to factory YAML, tfvars or module calls. |
| **Plans and state** | Phase 4 | Runs `terraform plan` and `apply` per stage, in order; decides every destructive change and state operation. |

Gates are **blocking**. If you run non-interactively and cannot get a
confirmation, stop at the gate and report. Never assume approval.

## Execution rules

> [!IMPORTANT]
> **Progress block.** During an upgrade (the Workflow Map below), EVERY
> response starts with this block, updated as steps complete:
>
> ```text
> FAST Upgrade Progress:
> - Phase 1: Discovery
>   (Step 1/3: Repository scan - IN PROGRESS)
> - Phase 2: Impact analysis
>   (Not started)
> - Phase 3: Update repository files
>   (Not started)
> - Phase 4: Verify & handover
>   (Not started)
> ```
>
> Show a completed phase as `(3/3 steps completed)` and a skipped one as
> `(Skipped: <reason>)`.

- **Turn boundaries.** When you need an answer, ask the question and STOP.
  Do not call more tools, and never assume or simulate the user's reply in
  the same turn.
- **Questions.** Use your multiple-choice question tool, if you have one,
  whenever you offer choices, with your recommendation first. Ask one
  decision per question. At the Phase 2 gate you may ask about the code
  update options together, as separate questions in one call.
- **Quote, don't paraphrase.** Report counts, verdicts and the `tools`
  line exactly as the scripts printed them. You may summarize long lists,
  but never invent or round a number.
- **Show reports inline.** The user reads the upgrade report in your
  answer. After `analyze`, paste the whole `report-brief.md` into your message
  verbatim, then link `report.md`; never answer with only a file path. If
  your chat can embed HTML inline, also embed the `--widget` card above
  the brief (see [Impact analysis](references/phase2-analysis.md), "Show
  the report inline").
- **Workspace only.** Keep the files you create inside the workspace. If
  your file tools cannot read outside it, fetch releases into it with
  `--cache-dir .fast-upgrade/releases`. The one exception: write the
  `--widget` card (and a copy of `--html`) into your agent's artifact
  directory when inline embeds must live there.
- **Resuming.** If the user comes back mid-upgrade, rebuild the state from
  `git status`, `git diff --check` and a fresh `analyze`, then resume at the
  matching step.

## Entry points

Not every request is a full upgrade. Pick the smallest flow that answers
it:

| Request | Flow |
| --- | --- |
| "Upgrade my FAST repository to vX" | The Workflow Map, from Phase 1 |
| "What breaks or changes between vX and vY?" | Fetch vY and run `changelog` (add `--repo` to keep only what a repository uses). No progress block, no file changes. |
| "What would upgrading my repository involve?" | Phases 1–2; stop at the code update gate |
| "Review this plan after an upgrade" | Phase 4, Step 11 only |

## Workflow Map

Follow the phases in order. **Before starting a phase, read its reference
document** for the exact commands and decision logic.

### Phase 1: Discovery
*Description:* Scan the repository, then settle the base and target releases with the user.\
*Reference: [Discovery](references/phase1-discovery.md)*
- **Step 1:** Repository scan (`detect`)
- **Step 2:** Base release — **gate**
- **Step 3:** Target release (`releases`) — **gate**

### Phase 2: Impact analysis
*Description:* Materialize both releases, produce the upgrade report and decide how to update the repository files.\
*Reference: [Impact analysis](references/phase2-analysis.md)*
- **Step 4:** Fetch base and target (`fetch`)
- **Step 5:** Upgrade report (`analyze`), shown inline
- **Step 6:** Code update decision — **gate**

### Phase 3: Update repository files
*Description:* Update the repository files on a branch, then resolve conflicts, data, variables and moved blocks with the user.\
*Reference: [Update repository files](references/phase3-migrate.md)*
- **Step 7:** Branch, dry run and `migrate`
- **Step 8:** Conflicts and manual items — **gate per file**
- **Step 9:** Factory data, tfvars, module calls and moved blocks; re-analyze

### Phase 4: Verify & handover
*Description:* Validate statically, review each stage's Terraform plan, and hand over.\
*Reference: [Verify & handover](references/phase4-verify.md)*
- **Step 10:** Static checks (`check-data`, `terraform fmt`, `terraform validate`)
- **Step 11:** Per-stage plan review (`plan_review.py`) — **gate per stage**
- **Step 12:** Handover report

## Tools

Commands are relative to this skill's folder. From anywhere else, prefix
the path, for example `uv run skills/fast/fast-upgrade/scripts/fast_upgrade.py`.

| Command | Purpose | Key options |
| --- | --- | --- |
| `fast_upgrade.py detect <repo>` | Stages, module layout, release markers, git state | `--json`, `--fabric-source` |
| `fast_upgrade.py releases` | Upstream release tags, newest first | `--upstream <url or path>` |
| `fast_upgrade.py fetch <tag>` | Materialize a release (`fast/`, `modules/`, `CHANGELOG.md`); prints its path last | `--from-repo <clone>` (offline), `--upstream`, `--cache-dir`, `--refresh` |
| `fast_upgrade.py changelog` | Breaking changes, module renames and upgrading notes in (from, to] | `--upstream-dir <target tree>`, `--from`, `--to`, `--repo` |
| `fast_upgrade.py analyze` (alias `fast_upgrade.py plan`) | The upgrade report (read-only): readiness verdict, severity-ranked findings, coverage gaps, then every section | `--repo`, `--base <tree>`, `--target <tree>`, `--data <dir>`, `--map <folder>=<stage>` (the user's answer for a stage candidate, or `=none`), `--output`, `--json`, `--limit 0`, `--markdown <file>` (customer report), `--brief <file>` (inline answer), `--widget <file>` (inline HTML card), `--html <file>` (interactive copy), `--skip-data-checks` |
| `fast_upgrade.py migrate` (alias `fast_upgrade.py apply`) | Update repository files on a clean git tree | the `analyze` options, plus `--dry-run`, `--include-deletes`, `--bump-refs`, `--copy-moved` |
| `fast_upgrade.py check-data <paths>` | Validate factory YAML against the modeline schemas | `--schemas <dir>` |
| `plan_review.py [plan.json]` | Classify a `terraform show -json` plan (file or stdin) | `--json` |
| `provenance.py` | Print the frozen-tools digest | `--verbose` |

Exit codes: `0` success; `1` error, or refused by a safety check; `2`
attention needed. For `migrate`, `2` means conflict markers or manual items
remain; for `check-data`, invalid files; for `plan_review.py`, destructive
or unrecognized changes.

`--json --output <file>` writes the JSON to the file and prints one line.
Text reports are always printed, and also saved when `--output` is given.
Nothing in `scripts/` runs Terraform, commits or pushes.

## Prerequisites

You need `git` and [`uv`](https://docs.astral.sh/uv/). `uv run
scripts/<name>.py` reads each script's inline (PEP 723) dependencies, so
nothing needs installing. Without `uv`, `python3` >= 3.10 takes the same
arguments, with PyYAML and jsonschema installed for the factory data
checks; where the system Python refuses `pip install` (PEP 668), create a
virtualenv (`python3 -m venv <dir>`, then `<dir>/bin/pip install pyyaml
jsonschema`) and run the scripts with `<dir>/bin/python`. If they are
missing, `analyze` exits `1`; pass `--skip-data-checks` only when the user
accepts a report without those checks. `terraform` is only needed in
Phase 4. `releases` and `fetch` need network access to the upstream
repository or a mirror, unless `fetch --from-repo` archives tags from a
local clone.

## Limits

- Upstream says in [UPGRADING.md](../../../fast/stages/UPGRADING.md) that
  its notes are a guideline with no guarantees. What makes an upgrade safe
  is the per-stage plan review in Phase 4, not the file merge.
- Upstream does not support upgrading from the legacy stages (bootstrap
  and resource manager, replaced in v44.0.0) to the current ones. `analyze`
  warns when a mapped stage no longer exists in the target; stop and point
  the user to UPGRADING.md.
- Stages that are new in the target are reported, never added. Adopting a
  new stage is a design decision, not an upgrade.
- Folders are mapped heuristically: by name first, then by content. Always
  show the MAPPED FOLDERS section and have the user confirm anything
  surprising. A folder that looks like a stage but matches none clearly
  is listed under STAGE CANDIDATES: never pick the stage yourself. Ask the
  user, one question per folder, then run `analyze` again with
  `--map <folder>=<stage>` (or `=none`) and pass the same flags to `migrate`
  ([phase 2](references/phase2-analysis.md#stage-candidates)).

## References

- [README.md](README.md) — human guide: design, gates, script reference
- [TESTING.md](TESTING.md) — test scenarios, unit and integration tests, playbooks
- [references/phase1-discovery.md](references/phase1-discovery.md) — repository scan, base and target releases
- [references/phase2-analysis.md](references/phase2-analysis.md) — fetching releases, reading the upgrade report, the code update gate
- [references/phase3-migrate.md](references/phase3-migrate.md) — updating repository files, conflicts, data and variable fixes, re-analyze
- [references/phase4-verify.md](references/phase4-verify.md) — static checks, plan review, handover
- [UPGRADING.md](../../../fast/stages/UPGRADING.md) and [CHANGELOG.md](../../../CHANGELOG.md) — the upstream release notes the scripts read
