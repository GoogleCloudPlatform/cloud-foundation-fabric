# Phase 3: Apply

> [!IMPORTANT]
> Start every response with the progress block from [SKILL.md](../SKILL.md).
> From here on files change, so only continue after the Phase 2 apply gate.
> Every edit you make is shown to the user first and made with your file
> tools, never with `sed`, `awk`, `echo >>` or heredocs.

## Step 7: Branch, dry run and apply

1. **Clean tree.** This must print nothing:

   ```bash
   git -C <repo> status --porcelain --untracked-files=no
   ```

   If it prints anything, ask the user to commit or stash those changes,
   and STOP. Do not commit or stash for them.
2. **Branch** (approved at the gate):

   ```bash
   git -C <repo> switch -c fast-upgrade/<target tag>
   ```

3. **Dry run** with exactly the flags the user approved:

   ```bash
   uv run scripts/fast_upgrade.py apply --repo <repo> --base <base tree> \
     --target <target tree> --dry-run [--include-deletes] [--bump-refs] [--copy-moved]
   ```

   Present the counts: `written`, `merged`, `conflict`, `manual`,
   `deleted`, `kept`.
4. **Apply**: the same command without `--dry-run`, plus
   `--output <repo>/.fast-upgrade/apply.txt`. Exit code `2` is expected
   whenever CONFLICT MARKERS or MANUAL are not empty; `1` means a safety
   check refused (read the `REFUSED:` line).
5. **Show the result**: `git -C <repo> status --short` and
   `git -C <repo> diff --stat | tail -1`.

The report's sections: CONFLICT MARKERS (files with markers to resolve),
MANUAL (files needing a decision), NOT DELETED (upstream deletions kept),
REFS BUMPED, MOVED BLOCKS COPIED, and MOVED BLOCKS TO COPY.

## Step 8: Conflicts and manual items (gate per file)

### Conflict markers

`apply` runs `git merge-file --diff3`. Only overlapping edits keep markers:

```text
<<<<<<< customer
the customer's version
||||||| base v57.0.0
the base release
=======
the target release
>>>>>>> target v59.0.0
```

For each file listed under CONFLICT MARKERS:

1. Read the whole file with your file tool.
2. For each block, explain what the customer changed (customer against
   base) and what upstream changed (base against target). Propose a
   resolution that keeps the customer's intent and takes upstream's
   change. When the two cannot coexist, say so and ask which wins.
3. Show the resolved text and ask for approval. Then replace the whole
   block, all four marker lines included, with your edit tool.
4. When the file is done, this must report no leftover conflict marker:

   ```bash
   git -C <repo> diff --check -- <file>
   ```

### Manual items

| Category | Situation | Resolution |
| --- | --- | --- |
| `conflict-added` | the customer and upstream both added this path, with different content | compare with the target version (the file's `target_path` in `plan.json`, under the target tree) and merge by hand |
| `conflict-deleted` | upstream removed a file the customer changed | with `renamed to`, `apply` already merged the edits into the new path: review that file, then delete the old one with approval. Otherwise port the customer's change, or drop it |
| `conflict-customer-deleted` | the customer removed a file that upstream changed | confirm it should stay removed; otherwise restore it from the target tree |
| a parent folder is a symlink | the path goes through a symlink in the customer's repository | `apply` never writes through links: resolve by hand |
| binary file or symlink changed on both sides | cannot be merged | pick a side with the user |

List the files under NOT DELETED (upstream deletions kept on purpose) in
the handover.

## Step 9: Data, variables, module calls and moved blocks

Work through the Phase 2 report one file at a time. Show each edit and get
approval first:

1. **FACTORY DATA `breaks`.** Change the YAML for the new schema, using
   the error and the matching BREAKING CHANGES entry: drop a key the schema
   no longer has, or move or reshape a value. Then check the file:
   `uv run scripts/fast_upgrade.py check-data <file>`.
2. **STAGE VARIABLES.** Remove or rename the keys listed under
   `SET IN TFVARS but removed` (the CHANGELOG entry usually names the
   replacement). Ask the user for values of `new required` variables.
   Reshape values whose `type changed`. Tfvars outside the repository (the
   `--data` folders) belong to the user: propose the change, and edit only
   with approval.
3. **YOUR MODULE CALLS.** Update the customer's module calls: drop removed
   arguments, reshape arguments whose type changed (the issue shows the
   type delta; the full types are `base_type` and `target_type` in
   `plan.json`), add newly required ones, and point renamed modules at
   their new folder.
4. **MOVED BLOCKS.** If `apply` did not copy them, copy each file listed
   under MOVED BLOCKS TO COPY once the user agrees:
   `cp <target tree>/<file> <repo>/<copy_to>`. These are verbatim copies of
   upstream files, not edits. Where UPGRADING NOTES say a `moved` block
   is not possible and give `terraform state` commands instead, collect
   those commands for the handover: the user runs them.
5. **UNRESOLVED MODULE SOURCES.** With approval, vendor the missing module
   from the target tree into the customer's module root, or switch the
   call to a git source.

### Re-plan

Verify the result:

1. **Same base and target**:

   ```bash
   uv run scripts/fast_upgrade.py plan --repo <repo> --base <base tree> \
     --target <target tree> --output <repo>/.fast-upgrade/replan.txt
   ```

   Expected:
   - no `upstream-changed` or `upstream-added` left: they now count as
     `already-updated`;
   - `upstream-deleted` only for deletions kept on purpose;
   - merged files still show as `conflict`, and renamed files that carry
     customer edits as `conflict-added`: their content now differs from
     both releases, which is expected;
   - no FACTORY DATA `breaks`, and no `SET IN TFVARS but removed`.
2. **The target as its own base**:

   ```bash
   uv run scripts/fast_upgrade.py plan --repo <repo> --base <target tree> \
     --target <target tree> --output <repo>/.fast-upgrade/delta.txt
   ```

   Every file is now `unchanged` or `customer-*`. The `customer-changed`
   and `customer-added` lists are the fork's remaining delta from the new
   release. Review them with the user: each one should be an intended
   customization. Keep this report; it describes the fork for the next
   upgrade.
3. **No markers left**: `git -C <repo> diff --check` reports nothing.
4. **Release markers**: `detect <repo>` shows the target release with
   `high` confidence. Customer-only stages have no marker and do not count.

Next: [Phase 4: Verify & handover](phase4-verify.md).
