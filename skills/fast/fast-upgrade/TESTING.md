# FAST Upgrade - Testing

The skill is tested in four layers. Each one catches failures the others
cannot:

| Layer | What it proves | Needs |
| --- | --- | --- |
| [Unit tests](#unit-tests) | Every script behaves as documented on small synthetic releases, including the refusals | Python, git |
| [Integration tests](#integration-tests-on-real-releases) | Plan, apply and re-plan work on real Fabric releases in three repository layouts, and a fetched release matches a plain checkout | a Fabric clone with release tags |
| [Plan review with Terraform](#plan-review-with-real-terraform) | `plan_review.py` reads real `terraform show -json` output correctly | Terraform, no cloud access |
| [Agent playbooks](#agent-playbooks) | The agent follows the protocol: progress block, gates, entry points, no file changes before the apply gate | Gemini API key |

## Core variables and decision points

1. **Repository layout:** unmodified fork; edits on both sides; renamed or
   moved stage folders; modules vendored under another root; modules
   sourced from git (upstream or a mirror); customer-only stages and
   modules; symlinked folders.
2. **Base evidence:** markers agree (`high`), disagree (`mixed`) or are
   missing (`none`); a base that is wrong in either direction.
3. **Release range:** one release or several; base equal to target; a
   downgrade; a stage removed in the target (the unsupported legacy path).
4. **Working tree:** clean, dirty, or not a git repository.
5. **Apply options:** dry run, `--include-deletes`, `--bump-refs`,
   `--copy-moved`.
6. **Factory data:** valid before and after; valid before and invalid
   after (`breaks`); already invalid; schema not resolvable; data kept
   outside the repository (`--data`).
7. **Plan verdicts:** no changes; updates only; deletes and replacements,
   with and without critical resource types; unrecognized actions; input
   that is not a plan.
8. **Release source:** a clone from GitHub or a mirror, or an archive of a
   local clone; a Python with or without tar extraction filters; an archive
   with unsafe members.

## Unit tests

From the repository root:

```bash
uv run --with pyyaml --with jsonschema --with pytest -m pytest \
  skills/fast/fast-upgrade/tests -q
```

Without `uv`, use Python 3.10+ with PyYAML, jsonschema and pytest:
`python3 -m pytest skills/fast/fast-upgrade/tests -q`. The suite runs in
about 15 seconds.

Fixtures are generated in temporary folders and never committed: two small
synthetic upstream releases (`v1.0.0` and `v2.0.0`) with stages, grouped
modules, schemas, moved blocks, a CHANGELOG and UPGRADING notes, and
customer repositories built from them in several layouts.

| Test class | What it covers |
| --- | --- |
| `TestHclLite` | Masking of comments, strings, heredocs and nested templates; module sources, variables and tfvars keys; git source parsing |
| `TestReleaseNotes` | CHANGELOG parsing, the (base, target] release range, relevance filtering, module renames, UPGRADING notes, moved-block files |
| `TestFactoryData` | Modeline resolution (by path, then by name), schema loading, validation, schema flattening with `$ref` cycles, schema diffs |
| `TestProvenance` | The frozen-tools digest (every script, line-ending independent) and the release tree digest (location independent, symlinks by normalized target) |
| `TestClassify` | The three-way truth table, and that every category is documented |
| `TestVersions` | Release consensus from markers, release detection, type deltas, file kinds |
| `TestScanAndCatalog` | Stage and module discovery, source rewriting between layouts, git source templates |
| `TestPlanVanillaFork` | An unmodified fork with customer data and tfvars, section by section |
| `TestPlanScenarios` | Edits on both sides, reorganized layouts, git sources and mirrors, renamed modules in use, CRLF, symlinks and link target spelling, wrong and mixed bases, dirty trees, removed stages, external data, refusals |
| `TestApply` | Clean-tree refusals, dry runs, taking upstream changes, opt-in deletions and moved blocks, merges and conflicts, ref bumps, and a re-plan after apply |
| `TestReleasesFetchDetect` | Release listing, fetching by archive and by clone (same digest), unsafe or missing refs, `detect` |
| `TestExtract` | Release archives with and without tar extraction filters: in-tree symlinks kept; escaping names and links, symlink chains and special files refused, with nothing written outside the destination; corrupt archives |
| `TestChangelogAndCheckData` | The `changelog` and `check-data` commands |
| `TestPlanReview` | Plan classification, `action_reason` hints, critical types, non-plan input, verdicts and exit codes |
| `TestCli` | Text, JSON and `--output` modes, and the exit codes of every command |
| `TestFactoryDataView` | The Terraform view of factory YAML: string keys and dates, validation like Terraform's, validator failures |
| `TestVersionConstraints` | Whether a provider or Terraform constraint allows a release, and its lower bound |
| `TestDeepChecks` | Version pins that block `terraform init`, files keeping upstream sources, linked module repositories, broken and absolute links, generated files, add-on copies, missing module folders, findings |
| `TestStageMapping` | Stage candidates (stage-like folders below the match threshold, guesses ranked by files and variables), `--map` from the API and the CLI for `plan` and `apply`, `=none`, overriding an automatic match, low-similarity hand mappings, unrelated folders not asked about, `parse_stage_map` validation, refused maps |
| `TestGenericLayouts` | Release files next to `fast/` (upgraded when still upstream's, kept when rewritten), module-root files, pins checked only in files Terraform loads, upstream-shipped files that look generated, new upstream datasets, nested module groups, one-stage repositories, external data masking, unpinned git sources, checklist apply order, per-stage counts |
| `TestReportHelpers` | Apply order, file counts that skip sample datasets and blocked files, stage attribution, home folder masking, table-cell escaping, single-pass template filling, the CSV formula guard |
| `TestHtmlReport` | The self-contained HTML report, scrubbing, and the `--html` flag |
| `TestMarkdownReport` | Report sections, tracker, escaping, the brief, and the `--markdown` and `--brief` flags |
| `TestInlineWidget` | The inline HTML card and the `--widget` flag |
| `TestSkillDocuments` | SKILL.md frontmatter, links that resolve, documented commands and flags that exist, no local paths; in this file, cited tests and playbooks that exist and a playbook command that works from the repository root |

## Integration tests on real releases

These run the full plan, apply and re-plan cycle on real releases. They
are skipped unless `FAST_UPGRADE_FABRIC_REPO` points to a Fabric clone with
the release tags (`git fetch --tags`). From the root of such a clone:

```bash
FAST_UPGRADE_FABRIC_REPO=$PWD uv run --with pyyaml --with jsonschema \
  --with pytest -m pytest skills/fast/fast-upgrade/tests -q -k TestIntegration
```

`FAST_UPGRADE_BASE` and `FAST_UPGRADE_TARGET` choose the releases (default
`v57.0.0` and `v59.0.0`). The six tests:

- **Fork round trip:** a complete copy of the base with one customer edit
  and one customer data file. After `apply`, no conflict markers remain
  unless the report said so, a re-plan finds nothing left to take, and a
  plan with the target as base shows only the customer's own changes.
- **Reorganized layout:** `0-org-setup` renamed to `stages/org-bootstrap`,
  `2-project-factory` renamed with a suffix, and `modules/` moved to
  `tf/modules/`. Folders are matched by content and prefix, nothing is
  reported as a customer change, and no module source is left unresolved.
- **Git-sourced stage:** a stage whose modules come from upstream git at the
  base tag. The ref bump rewrites every `?ref=`, and a re-plan finds
  nothing left to take or bump.
- **Plain checkout of the base:** an untouched copy of the base with link
  targets exactly as git writes them. The plan shows upstream changes only:
  the `2-networking` dataset symlink is not reported as a customer change,
  even when the fetched release normalized its target.
- **Archive without tar filters:** fetching the target the way Pythons
  without tar extraction filters do gives the same tree digest as the
  filtered path.
- **Full release copy:** everything the base release ships, including
  `CHANGELOG.md`, `default-versions.tf` and `modules/README.md`, plus one
  customer data file. The plan has no blocker, no stale pin and no
  generated-file finding; after `apply --include-deletes` the tree equals
  the target plus the customer file, and `detect` reports the target with
  high confidence.

## Plan review with real Terraform

The unit tests use hand-written plan JSON. To check `plan_review.py`
against the JSON your Terraform version produces, use `terraform_data`
resources, which need no provider credentials and create nothing in the
cloud:

1. In an empty folder, write a configuration with a few `terraform_data`
   resources (one with `for_each`, one with `triggers_replace`), then run
   `terraform init` and `terraform apply` to create a local state.
2. Change it: rename one resource with a `moved` block, delete one, change
   a `for_each` key, change a `triggers_replace` value, change an `input`,
   and add a resource.
3. Plan and review:

   ```bash
   terraform plan -out=test.tfplan
   terraform show -json test.tfplan | uv run <skill>/scripts/plan_review.py
   ```

Expected: exit `2`, with DESTRUCTIVE entries for the deleted resource
(`delete_because_no_resource_config`), the old `for_each` key
(`delete_because_each_key`) and the triggered replacement
(`replace_because_cannot_update`, with `replace paths: triggers_replace`),
and the rename under MOVED. `terraform show -json` without a plan file
(state, not a plan) must exit `1`. A plan with no changes, or with updates
only, must exit `0` with the matching verdict.

## Agent playbooks

The playbooks in
[`tools/skill-turn-harness/playbooks/fast/fast-upgrade/`](../../../tools/skill-turn-harness/playbooks/fast/fast-upgrade/)
run the skill through the
[skill-turn-harness](../../../tools/skill-turn-harness/README.md). They need
a Gemini API key, in `GEMINI_API_KEY` or in `~/.gemini/key.env`, and every
run uses model quota.

Run them from the repository root. The harness copies the paths listed in
the playbook's `link_paths` from the folder it is started in to a temporary
workspace, and `--skill-src` is a path inside that workspace:

```bash
uv run tools/skill-turn-harness/harness.py \
  tools/skill-turn-harness/playbooks/fast/fast-upgrade/changelog-offline.yaml \
  --skill-src skills/fast/fast-upgrade
```

Without `uv`, install `tools/skill-turn-harness/requirements.txt` in a
virtual environment and run the same command with `python3`. Add
`--keep-workspace` to inspect the workspace after the run. Logs are written
to `./logs`, and a failed step saves the full trace there.

| Playbook | Mode | Network | What it checks |
| --- | --- | --- | --- |
| `changelog-offline.yaml` | scripted | no | The "what breaks between two releases" entry point: the `changelog` command on the workspace, the v58 and v59 breaking changes, no progress block, no file changes |
| `refuse-downgrade.yaml` | scripted | no | The progress block, `detect`, the blocking base gate, and the refusal of a target older than the base |
| `impact-analysis-autonomous.yaml` | autonomous | yes | A stand-in v57.0.0 repository, both release gates, the upgrade report, and a stop at the apply gate without changes |

## Comprehensive test scenarios

Each scenario lists the automated tests that cover it.

### Scenario 1: Unmodified fork with customer data

* **Layout:** a copy of the base release plus factory YAML and tfvars
* **Expected:** upstream changes are taken, customer data is kept, the
  upstream deletions wait for `--include-deletes`, a tfvars key for a
  removed variable is flagged, and a data file that breaks under the new
  schema is reported. An untouched checkout shows no customer changes,
  whatever spelling its symlink targets use
* **Tests:** `TestPlanVanillaFork`, `TestApply`, `test_fork_round_trip`,
  `test_link_spelling_is_not_a_customer_change`,
  `test_checkout_of_base_is_vanilla`

### Scenario 2: Edits on both sides

* **Layout:** the customer edited files that upstream also changed or
  deleted, and removed a file that upstream changed
* **Expected:** overlapping edits keep diff3 conflict markers,
  non-overlapping ones merge cleanly, and deletions against edits become
  manual items with a hint
* **Tests:** `test_edits_on_both_sides`, `test_conflicts_merges_and_manual_items`

### Scenario 3: Reorganized repository

* **Layout:** stages renamed or moved, modules under another root, relative
  sources fixed by the customer
* **Expected:** folders are matched by name, prefix or content; no false
  conflicts; files written by `apply` point at the customer's folders
* **Tests:** `test_reorganized_layout_has_no_false_conflicts`,
  `test_reorganized_apply_writes_customer_layout`, `test_reorganized_layout`

### Scenario 4: Git-sourced modules

* **Layout:** stages call Fabric modules from git at `?ref=<base>`, from
  GitHub or from a mirror
* **Expected:** refs at the base are bumpable, `--bump-refs` touches only
  Fabric sources at the base, and a mirror needs `--fabric-source`
* **Tests:** `test_git_sourced_modules`, `test_fabric_source_regex_for_mirrors`,
  `test_bump_refs_only_touches_fabric_sources_at_the_base`, `test_git_sourced_stage`

### Scenario 5: Uncertain base

* **Evidence:** markers that disagree, no markers, or a base that does not
  match the markers
* **Expected:** `mixed` confidence with the oldest version proposed, and a
  warning that explains the silent keeps a too-new base causes
* **Tests:** `test_version_consensus`, `test_mixed_markers_warning`,
  `test_wrong_base_is_warned_and_explains_silent_keeps`

### Scenario 6: Unsafe or unsupported situations

* **Situations:** a dirty tree, a folder outside git, a symlinked folder, a
  downgrade, a stage that no longer exists in the target, unsafe refs, a
  release archive with members that point outside it
* **Expected:** `apply` refuses with exit `1` and a `REFUSED:` line; `plan`
  warns; `fetch` fails with exit `1`; nothing is written through a symlink
  or outside the destination
* **Tests:** `test_refuses_outside_git_and_dirty_trees`,
  `test_symlinked_folder_is_blocked`, `test_refusals`,
  `test_removed_stage_warns_about_unsupported_path`,
  `test_fetch_refuses_unsafe_or_missing_refs`, `TestExtract`,
  `refuse-downgrade.yaml`

### Scenario 7: Plan review

* **Plans:** no changes; updates only; deletes and replacements, some of
  critical types; unrecognized actions; state instead of a plan
* **Expected:** exit `0`, `0`, `2`, `2` and `1`, with the matching verdict
* **Tests:** `TestPlanReview`, [Plan review with real Terraform](#plan-review-with-real-terraform)

## Changing the skill

- Run the unit tests, and the integration tests when you change `fetch`,
  `plan` or `apply`.
- Format the scripts with `yapf` (the repository's `.style.yapf`) and keep
  the license headers (`tools/check_boilerplate.py`).
- Keep test module names unique across `skills/`: CI collects tests from
  the repository root, and two `test_scripts.py` files collide.
- Any change to a script changes the `tools` digest printed in every
  report. That is expected: it is how a captured report is tied to the code
  that produced it.
- When you add a command or a flag, document it in SKILL.md and README.md:
  `TestSkillDocuments` fails when a documented command or flag does not
  exist, or when a subcommand is missing from SKILL.md.
