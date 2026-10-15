# Phase 2: Impact analysis

> [!IMPORTANT]
> Start every response with the progress block from [SKILL.md](../SKILL.md).
> This phase only reads the repository; releases are fetched into a cache
> outside it (or into `<repo>/.fast-upgrade/`, which the scripts ignore).

## Step 4: Fetch base and target

```bash
uv run scripts/fast_upgrade.py fetch <base tag>
uv run scripts/fast_upgrade.py fetch <target tag>
```

Each command prints `fetched <tag> (<how>); release marker <version>`,
then the tree's path on the last line. Use those two paths as `--base` and
`--target` from now on. Check that the release marker equals the tag. If
it does not, the tag is not a FAST release: stop and tell the user.

- **Cache:** `$FAST_UPGRADE_CACHE`, otherwise `~/.cache/fast-upgrade`.
  Use `--cache-dir <dir>` to pick another place (for example
  `.fast-upgrade/releases` in a sandboxed workspace) and `--refresh` to
  fetch again.
- **Offline or air-gapped:** `--from-repo <local Fabric clone>` archives
  the tag from a clone with `git archive`. The clone needs the tags
  (`git fetch --tags`).
- **Mirror:** `--upstream <url>` clones from an internal mirror.

## Step 5: Upgrade report

```bash
mkdir -p <repo>/.fast-upgrade
uv run scripts/fast_upgrade.py analyze --repo <repo> --base <base tree> \
  --target <target tree> --output <repo>/.fast-upgrade/plan.txt \
  --markdown <repo>/.fast-upgrade/report.md \
  --brief <repo>/.fast-upgrade/report-brief.md \
  --widget <repo>/.fast-upgrade/report-card.html \
  --html <repo>/.fast-upgrade/report.html
uv run scripts/fast_upgrade.py analyze --repo <repo> --base <base tree> \
  --target <target tree> --json --output <repo>/.fast-upgrade/plan.json
```

The text report is for your analysis; the JSON (written, not printed)
holds every list in full, including target paths, for lookups in
Phases 3–4. `report-brief.md` is the **answer you show the user** (see
below). `report.md` is the **customer report**: a summary with the
verdict, a findings tracker with Owner, Status and Due columns for
their team, every finding in detail, a per-stage view, the upgrade plan as
a task list, breaking changes, file actions, what could not be checked,
and appendices. It renders in their Git host or a merge request and
imports into Google Docs. `report.html` has the same content as an
interactive page for walkthroughs; it follows the IDE's light or dark
theme when opened in an agent side pane. `report-card.html` is a compact
interactive card (under 500 px tall: verdict, severity filters, tabs for
Start here, Findings, Stages, Plan, Breaking and Not checked) to embed in
the chat. All of them replace local absolute paths
with `<repo>`, `<base>`, `<target>`, `~` and `<home>`, so they can be
shared with the customer's team as is. They still name their organization,
projects and principals: share them only inside the engagement. Add:

- `--data <dir>` (repeatable) for factory data or tfvars kept outside the
  repository, for example a `fast-config` folder;
- `--map <folder>=<stage>` (repeatable) with the user's answer for each
  stage candidate, or `<folder>=none` for a folder that is theirs (see
  [Stage candidates](#stage-candidates));
- `--fabric-source <regex>` when Fabric modules are sourced from a mirror
  whose URL does not contain `cloud-foundation-fabric`;
- `--limit 0` to print every item instead of the first 25 of each list.

`analyze` exits `1` when PyYAML or jsonschema is missing: use `uv run`, or a
virtualenv with both installed. Only if the user accepts a report without
factory data checks, re-run with `--skip-data-checks`; the report then
lists factory YAML as `not checked`.

### Show the report inline

> [!IMPORTANT]
> The user reads the report **in your answer**, not in a file. Never reply
> with only a path to a report.

Read `<repo>/.fast-upgrade/report-brief.md` with your file tools and build
the answer in this order:

1. The progress block, then the `tools` line exactly as printed.
2. Only if the text report has a WARNING that changes the next step (wrong
   base, mixed releases, stages removed upstream, uncommitted changes):
   one or two sentences on it, before the report.
3. **The inline HTML card, only if your chat can embed HTML.** Write
   `--widget` (and a copy of `--html`) wherever your agent requires embedded
   files to live (often its artifact directory rather than
   `.fast-upgrade/`), then embed it with your agent's own syntax for inline
   HTML. If the card does not show, save the file again with the tool
   your agent uses to register such files. Skip this step when your agent
   cannot embed HTML; never paste the HTML source.
4. **The whole of `report-brief.md`, verbatim**, as Markdown in your
   message (not in a code block). Do not shorten, reorder, reword or
   renumber it; every count and ID in it is quoted from the plan. Keep it
   even when the card renders: it is the text record of the answer and
   the fallback where embeds are not shown.
5. One line linking the full reports, for example:
   `Full report with every finding, file and appendix: [report.md](<absolute path>) · interactive: [report.html](<absolute path>)`.
6. The Step 6 code update questions. The report must be in your message text
   before you ask them, so the user sees it while answering. If the report
   lists STAGE CANDIDATES, ask the [candidate questions](#stage-candidates)
   instead and stop: the code update gate comes after re-running `analyze`.

If the user asks about a finding, answer from its section in `report.md`
(`#### F007 · ...`) or from `plan.json`, and quote its ID.

### Check the report before you present it

Read the text report yourself and look for the following, so you can
explain them when asked and catch a wrong base early. Quote the `tools`
line, the verdict and the counts exactly as printed:

1. **READINESS** and its key points. `BLOCKED` means at least one blocker:
   the upgrade cannot succeed until it is fixed. `NEEDS WORK` means
   high-severity findings. `READY WITH REVIEW` still needs every stage's
   plan reviewed in Phase 4.
2. **FINDINGS.** Every blocker and high finding, with its action. Each has
   an ID (`F001`) that the customer report and later answers can refer to.
   Severity: `blocker` stops the upgrade; `high` likely breaks
   `terraform plan` or changes infrastructure; `medium` needs a decision or
   a manual step; `low` is cleanup; `info` is for awareness.
3. **NOT CHECKED.** Say plainly what the report could not verify
   (unreadable tfvars, YAML without a schema modeline, Terraform state).
   Never present a partial check as a clean one.
4. **WARNINGS.** A wrong-base warning or many unexpected conflicts mean
   you should go back to Step 2 before anything else. A warning that stages
   no longer exist in the target means an unsupported upgrade path: stop
   (see [SKILL.md](../SKILL.md), Limits).
5. **MAPPED FOLDERS.** Check the mapping with the user. `name` and
   `prefix` matches are reliable. `content 0.xx` means a renamed folder
   was matched by its files, so confirm it. `set by user` comes from
   `--map`. `yours (no upstream match)` lists the customer's own stages
   and modules, which the upgrade leaves alone.
6. **FILE ACTIONS.** Explain each category (the report prints what each
   one means). `version-marker only` changes are safe;
   `layout adjusted` means upstream module sources were rewritten to the
   customer's folders.
7. **BREAKING CHANGES** (each with its `impact` here) and **UPGRADING
   NOTES.** These apply to this repository. Say that the other entries were
   filtered out because they concern stages or modules the repository does
   not use.
8. **CONFLICTS** and **MANUAL REVIEW.** Conflicts are merged
   automatically, and only overlapping edits need a human; manual items
   always need one (Phase 3).
9. **VERSION PINS IN YOUR FILES.** Customer-owned files (often a
   `terraform.tf` copied from `default-versions.tf`) that apply keeps.
   `BLOCKS INIT` means their provider constraints exclude the target's:
   `terraform init` fails until they are updated or removed.
10. **STAGE VARIABLES.** `SET IN TFVARS but removed`: Terraform only warns
    about undeclared variables in tfvars files, so the setting silently
    stops working; find where it moved. `new required` needs a value from
    the user. `type changed` may need a value reshaped. `unreadable tfvars`
    shows the broken link target: those keys were not checked.
11. **YOUR MODULE CALLS.** Code the customer owns that calls a module whose
    interface changed: removed arguments, changed types, newly required
    arguments, renamed modules.
12. **FACTORY DATA.** `breaks` means YAML that the target schema rejects:
    editors and CI fail, and at runtime the factories usually ignore the
    key silently. `schema-removed` means its schema is gone upstream.
    `still-invalid` and `unresolved` were already problems before the
    upgrade. `validator-error` means the validator itself failed on the
    file: check it by hand. **SCHEMA CHANGES** give the context. Data is
    found in the stages, anywhere else in the repository when the file has
    a schema modeline (a `data/` folder, a wrapper), behind symlinked
    folders, and in `--data` paths. When the repository has no schema for
    a file, it is checked against the base and target release schemas
    (note `validated against the release schemas`); schema names repeat
    across stages, so data outside a stage should sit in a folder named
    after it (`data/2-networking`). `No factory data found for N stage(s)`
    means those stages were not checked at all: ask where the data lives
    and re-run with `--data`.
13. **UPSTREAM DELETIONS.** Files removed upstream. `renamed to` pairs show
    where their content went.
14. **UNRESOLVED MODULE SOURCES AFTER UPGRADE** and **FILES KEEPING
    UPSTREAM MODULE SOURCES.** A file that still uses upstream-relative
    sources (for example `../../../modules/x`) in a reorganized repository
    is taken as is, so its sources keep pointing at a folder that does not
    exist.
15. **LINKED REPOSITORIES**, **REPOSITORY HYGIENE** (broken or absolute
    symlinks, generated provider and tfvars files committed to git) and
    **ADD-ON COPIES** (files copied from `fast/addons` that apply does not
    update, and whether upstream changed the add-on since). Linked
    repositories include folders inside a stage, typically `datasets/`
    kept in its own repository: a nested clone is written and checked like
    the main repository; a symlink is compared through the link but never
    written through (upstream changes there are listed as blocked).
16. **PROVIDERS** (`terraform init -upgrade` per stage in Phase 4),
    **MOVED BLOCKS** (files of `moved` blocks for the range),
    **MODULE RENAMES** (`(in use)` matters), **GIT REFS TO FABRIC**
    (bumpable refs), and **NOTES** (lock files, new stages, git history,
    the git source template, linked repositories).

The brief already covers items 1–3 and the breaking changes; use the rest
to answer follow-up questions and to decide whether to go back to Step 2.

| Report says | Usually means | Next step |
| --- | --- | --- |
| many `conflict`, few `customer-changed` | the base is too old or wrong | revisit Step 2; compare candidate bases |
| many `customer-changed` in files the user never touched | the base is too new, so upstream changes look like the customer's | revisit Step 2 now: `apply` would skip those files |
| `conflict-deleted` with `renamed to` | the customer edited a file that upstream renamed | `apply` merges the edits into the new path |
| `new dependency` or `renamed from` module mappings | the target needs modules the repository does not have yet | `apply` adds them under the customer's module root |
| unresolved sources after upgrade | new upstream code calls a module that will not exist | vendor the module, or use a git source; raise it at the gate |
| `BLOCKS INIT` under VERSION PINS | a customer-owned `terraform.tf` or `versions.tf` still pins the base release's providers | propose the target constraints (or removing the duplicate file) as a Phase 3 edit |
| `unreadable tfvars: ... (broken symlink to ...)` | tfvars links created by `fast-links.sh` on another machine | ask for the real files (`--data <folder>`) and re-run; until then those keys are unchecked |
| `ERROR: factory data checks need ...` | PyYAML or jsonschema is missing | use `uv run` or a virtualenv; `--skip-data-checks` only if the user accepts the gap |
| `FACTORY DATA: skipped` | the plan ran with `--skip-data-checks` | say that factory YAML was not checked |
| `No factory data found for N stage(s)` | the stage code and its data live apart (a dataset repository, a data folder outside the repository) | ask for the data location; re-run with `--data <path>` |
| `changed upstream in sample datasets you do not keep` | the customer uses their own dataset, not upstream's `classic` or `hardened` samples | not applied; compare the listed sample files with the customer's data for new keys |
| unresolved: `<name>.schema.json differs between ...` | data outside any stage, in a folder whose name does not say which stage it belongs to | re-run with the data under a stage-named folder, or plan it with the stage code (`--data`) |
| stage mapped as `repository name`, `repository prefix` or `repository unnumbered name` | one stage per repository, recognized by the repository folder name and a content check | confirm the stage with the user if the name is ambiguous |
| `STAGE CANDIDATES` | a folder built like a FAST stage that matches none clearly enough to map on its own | ask the user, re-plan with `--map` ([Stage candidates](#stage-candidates)) |
| `set by user: <folder> <- <stage>, only N% of its files match` | the user mapped a folder that has drifted far from the stage | expect many conflicts; review every merge in it, or port the upstream changes by hand |

### Stage candidates

A folder is a candidate when it is built like a stage (it has a
`fast_version.txt`, a stage-style name, a `variables-fast.tf`, or several
FAST stage variables such as `prefix` and `billing_account`), nothing
mapped it, and it is at least 20% similar to an upstream stage by its files
or its declared variables, or its name contains a stage name. Folders that
look like no stage stay under `yours (no upstream match)` without a
question. Until a candidate is mapped, apply leaves it untouched, so no
upstream change reaches it.

For each candidate, ask one multiple-choice question and then STOP:

> `<folder>` looks like a FAST stage but matches none clearly. Which stage
> is it based on?
> 1. (Recommended) `<first guess>` (N% of the files, M% of the variables)
> 2. `<second guess>` (...)
> 3. None, it is our own stage

Offer the guesses in the order printed, the first as recommended, and
always the "own stage" option. Never choose for the user, and do not map a
candidate because one similarity number looks high: variable overlap is
easily high for a stage with few variables.

Then run `analyze` again with one flag per answer, for example
`--map platform/core-org=0-org-setup --map tools/bootstrap=none`, and show
the new report. Keep the same `--map` flags for every later `analyze` and for
`migrate`, so `migrate` writes exactly what was reviewed; record them in your
progress block. A stage mapped by hand that shares less than half its
files with upstream gets a high finding: say that its merges need a
line-by-line review.

## Step 6: Code update decision (gate)

The inline report is already in your answer, and the files are in
`.fast-upgrade/` (`report.md` and `report.html` to share).
Then ask, as separate questions (one call to your question tool is fine):

1. **Proceed?** Update the repository files on a new branch
   `fast-upgrade/<target tag>` (recommended), or stop here with the
   report.
2. **Deletions:** only if UPSTREAM DELETIONS is not empty. Delete those
   files now (`--include-deletes`), or keep them for later review? Deleting
   files the customer never changed is usually right. Files still
   referenced by the customer's code show up in their plan.
3. **Ref bumps:** only if `GIT REFS TO FABRIC` shows bumpable refs. Rewrite
   `?ref=<base>` to the target in the customer's own files
   (`--bump-refs`)?
4. **Moved blocks:** only if MOVED BLOCKS is not empty. Copy those files
   into the stages (`--copy-moved`)? Recommended: without them Terraform
   plans deletes and re-creates for renamed resources.

STOP and wait for the answers. If the user stops here, finish with a short
summary of the report and the decisions that remain.

Next: [Phase 3: Update repository files](phase3-migrate.md).
