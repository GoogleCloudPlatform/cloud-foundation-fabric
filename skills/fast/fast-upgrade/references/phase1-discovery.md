# Phase 1: Discovery

> [!IMPORTANT]
> Start every response with the progress block from [SKILL.md](../SKILL.md).
> This phase only reads: nothing in the repository changes.

## Step 1: Repository scan

1. **Find the repository.** If the user named a path, use it. Otherwise
   ask for it and STOP. When the workspace itself contains stage folders
   (`fast/stages/...`, or folders such as `0-org-setup` or
   `2-networking`), offer it as the default.
2. **Scan it:**

   ```bash
   uv run scripts/fast_upgrade.py detect <repo>
   ```

3. **Present the report**, quoting it:
   - `release`: the detected release and its confidence;
   - `STAGES`: every stage folder and how it was found (`marker` means a
     `fast_version.txt` file, `name` a folder named like `2-networking`);
   - `MODULES`: where local modules live and how the stages call them
     (local paths, git refs to Fabric, the registry);
   - `FACTORY`: the number of YAML files, schemas, tfvars and lock files;
   - the git state (branch, clean or dirty) and every `WARNINGS` line.

Read the report with this table:

| Signal | Meaning | What to do |
| --- | --- | --- |
| confidence `high` | all markers agree | propose that release as the base |
| confidence `mixed` | markers disagree: an earlier partial upgrade, or stages copied from different releases | show the breakdown and propose the **oldest** version listed (the tool's tie-break); explain why (Step 2) |
| confidence `none` | no marker found | ask the user; see [Unknown base](#unknown-base) |
| `git refs to Fabric` | modules come from upstream git at a `?ref=` | the ref is strong evidence of the base; `apply --bump-refs` can update it later |
| `SOURCE PROBLEMS` | module sources that do not resolve (missing folder, outside the repository) | fix or explain them before planning: the plan cannot map what it cannot resolve |
| warning `module sources point to the missing folder <root>` | many sources share one missing root; `(git-ignored ...)` means it is meant to be a separate checkout | ask the user to check out or link the modules repository at the printed path, then run `detect` again. Never create the link without their approval |
| module folder is a symlink or a nested git repository | the modules live in another repository | fine: `plan` lists it under LINKED REPOSITORIES and `apply` checks that repository is clean too. The upgrade then needs a commit in each repository |
| `datasets/` is a symlink, or the factory YAML lives in another repository | the data is owned separately from the stage code | a symlink is fine: `plan` compares the data through it and `apply` never writes it. For a separate data repository, ask for its path and pass it with `--data` so the YAML is validated; otherwise the report says no factory data was found |
| one stage at the repository root | a repository per stage | fine: `plan` matches the root by the repository folder name and content. Plan each repository on its own |
| `HISTORY` line | the repository's git history contains the upstream tag | a real git fork: mention `git merge <target tag>` as an alternative; this skill still works |
| dirty tree | uncommitted changes to tracked files | fine for Phases 1–2; `apply` refuses until the user commits or stashes them |
| no stages | no stage found by marker or name | confirm the path with the user; `plan` still tries to match folders by content. A stage consumed as a remote module or through Terragrunt is not supported |

## Step 2: Base release (gate)

The base is the upstream release the repository was built from, before
the customer's changes. It decides how every file is classified:

- **Base too new** (newer than the real one): upstream changes between the
  real base and the chosen one look like customer edits and are **silently
  kept**, so the upgrade quietly skips them. This is the dangerous
  direction.
- **Base too old**: those changes show up as conflicts instead, and most
  merge cleanly because both sides made the same edit. Noisy, but never
  silent.

So when the evidence is split, prefer the older candidate. Ask the user to
confirm the base as a multiple-choice question (the detected release
first, marked as recommended) and STOP.

### Unknown base

If there are no markers and the user does not know the base:

1. Look for evidence: `git log --oneline -- <stage folder>` messages,
   tags, a copy of `CHANGELOG.md` in the repository, `versions.tf` files
   in the modules.
2. If you are still unsure, fetch two or three candidate releases (Phase 2,
   Step 4) and run `plan --json --output <file>` with each one as the
   base. The real base gives the most `unchanged` files and the fewest
   conflicts. Present the counts and let the user choose.

## Step 3: Target release (gate)

```bash
uv run scripts/fast_upgrade.py releases
```

When GitHub is not reachable, add `--upstream <url>` for a mirror or
`--upstream <path>` for a local clone with tags.

- Recommend the newest release.
- **Target older than the base**: refuse. Downgrades are not supported,
  and the scripts refuse them too. **Target equal to the base**: there is
  nothing to upgrade; say so and stop.
- **Several releases at once** is fine: the comparison goes straight from
  base to target, and the report collects the breaking changes, upgrading
  notes and moved blocks of every release in between.
- **Base older than v44.0.0** with the legacy stages (bootstrap and
  resource manager): stop. Upstream does not support upgrading legacy
  stages to the current ones; point the user to `fast/stages/UPGRADING.md`
  in the target release.

Ask the user to confirm the target (newest first, marked as recommended)
and STOP.

Next: [Phase 2: Impact analysis](phase2-analysis.md).
