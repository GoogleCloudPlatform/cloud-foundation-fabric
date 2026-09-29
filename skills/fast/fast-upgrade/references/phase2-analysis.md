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
uv run scripts/fast_upgrade.py plan --repo <repo> --base <base tree> \
  --target <target tree> --output <repo>/.fast-upgrade/plan.txt
uv run scripts/fast_upgrade.py plan --repo <repo> --base <base tree> \
  --target <target tree> --json --output <repo>/.fast-upgrade/plan.json
```

The text report is for the conversation; the JSON (written, not printed)
holds every list in full, including target paths, for lookups in
Phases 3–4. Add:

- `--data <dir>` (repeatable) for factory data or tfvars kept outside the
  repository, for example a `fast-config` folder;
- `--fabric-source <regex>` when Fabric modules are sourced from a mirror
  whose URL does not contain `cloud-foundation-fabric`;
- `--limit 0` to print every item instead of the first 25 of each list.

### Present the report

Lead with what needs a decision, then the context. Quote the `tools` line
and the counts exactly as printed:

1. **WARNINGS.** Deal with these first. A wrong-base warning or many
   unexpected conflicts mean you should go back to Step 2 before anything
   else. A warning that stages no longer exist in the target means an
   unsupported upgrade path: stop (see [SKILL.md](../SKILL.md), Limits).
2. **MAPPED FOLDERS.** Check the mapping with the user. `name` and
   `prefix` matches are reliable. `content 0.xx` means a renamed folder
   was matched by its files, so confirm it. `yours (no upstream match)`
   lists the customer's own stages and modules, which the upgrade leaves
   alone.
3. **FILE ACTIONS.** Explain each category (the report prints what each
   one means). `version-marker only` changes are safe;
   `layout adjusted` means upstream module sources were rewritten to the
   customer's folders.
4. **BREAKING CHANGES** and **UPGRADING NOTES.** These apply to this
   repository. Say that the other entries were filtered out because they
   concern stages or modules the repository does not use.
5. **CONFLICTS** and **MANUAL REVIEW.** Conflicts are merged
   automatically, and only overlapping edits need a human; manual items
   always need one (Phase 3).
6. **STAGE VARIABLES.** `SET IN TFVARS but removed` breaks
   `terraform plan` until the key is removed or renamed. `new required`
   needs a value from the user. `type changed` may need a value reshaped.
7. **YOUR MODULE CALLS.** Code the customer owns that calls a module whose
   interface changed: removed arguments, changed types, newly required
   arguments, renamed modules.
8. **FACTORY DATA.** `breaks` means YAML that is valid today but not after
   the upgrade: the key is ignored or rejected. `schema-removed` means its
   schema is gone upstream. `still-invalid` and `unresolved` were already
   problems before the upgrade. **SCHEMA CHANGES** give the context.
9. **UPSTREAM DELETIONS.** Files removed upstream. `renamed to` pairs show
   where their content went.
10. **PROVIDERS** (`terraform init -upgrade` per stage in Phase 4),
    **MOVED BLOCKS** (files of `moved` blocks for the range),
    **MODULE RENAMES** (`(in use)` matters), **GIT REFS TO FABRIC**
    (bumpable refs), **UNRESOLVED MODULE SOURCES AFTER UPGRADE**, and
    **NOTES** (lock files, new stages, git history, the git source
    template).

| Report says | Usually means | Next step |
| --- | --- | --- |
| many `conflict`, few `customer-changed` | the base is too old or wrong | revisit Step 2; compare candidate bases |
| many `customer-changed` in files the user never touched | the base is too new, so upstream changes look like the customer's | revisit Step 2 now: `apply` would skip those files |
| `conflict-deleted` with `renamed to` | the customer edited a file that upstream renamed | `apply` merges the edits into the new path |
| `new dependency` or `renamed from` module mappings | the target needs modules the repository does not have yet | `apply` adds them under the customer's module root |
| unresolved sources after upgrade | new upstream code calls a module that will not exist | vendor the module, or use a git source; raise it at the gate |
| `FACTORY DATA: skipped` | PyYAML or jsonschema is missing | install them or use `uv run`, then re-run |

## Step 6: Apply decision (gate)

Offer to save the report (it is already in `.fast-upgrade/plan.txt`).
Then ask, as separate questions (one `ask_question` call is fine):

1. **Proceed?** Apply the upstream changes on a new branch
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

Next: [Phase 3: Apply](phase3-apply.md).
