# Linting, E2E, and PR Lifecycle

This guide covers the mechanical end-to-end contribution workflow: provider research and version bumps, branching, full CI lint parity, pre-submission self-review, optional live E2E verification, and sanitized PR submission. For triaging incoming GitHub issues or sweeping the issue backlog, use [cff-issue-triage](../../../../skills/maintainer/cff-issue-triage/SKILL.md) first.

## Human-in-the-Loop Gates

Gates are **blocking**: if running non-interactively and you cannot obtain an answer, stop — never assume approval. When implementing from an existing GitHub issue (`gh issue view <issue-number>`), never comment on, label, or close issues yourself.

| Gate | When | What the human decides |
| :--- | :--- | :--- |
| **Design Sign-off** | Before writing code | Approves target module(s), variable/output interface, provider include/exclude list, and any provider version bump. Mandatory for features/interface changes; skippable for trivial obvious fixes. |
| **E2E Opt-in** | After tests & self-review pass | Whether to deploy live. Providing a sandbox project ID authorizes `terraform apply/destroy -auto-approve` in it. |
| **Behavioral Verification Opt-in** | After E2E read-back passes | Whether to run live runtime/traffic checks given described time and cost. |
| **PR Approval** | Before `gh pr create` | Reviews the final sanitized PR title and body. |

## Pre-Design Research Commands

1. **Index ADRs by title and status** before designing (ignore `Rejected`, treat `Draft`/`Proposed` as directional; on conflict, current golden-path code wins):

```bash
find adrs -name '*.md' ! -name 'README.md' | sort | while read -r f; do
  st=$(awk '/^## Status/ {getline; while ($0 == "") getline; print; exit}' "$f")
  printf '%s | %s | %s\n' "$f" "$(head -1 "$f" | sed 's/^# //')" "$st"
done
```

2. **Read complete released provider documentation:** Start from the Terraform Registry (`hashicorp/google` or `google-beta`), never from provider `main` or partial issue snippets. If the registry fails to render (JS/truncation), fetch the raw markdown for a **released** tag into gitignored `scratch/`:

```bash
curl -s https://raw.githubusercontent.com/hashicorp/terraform-provider-google/v8.12.0/website/docs/r/<resource>.html.markdown -o scratch/<resource>_doc.md
```

3. **Provider minimum version bumps:** Every module pins its constraints in `versions.tf` and `versions.tofu`, kept identical to [default-versions.tf](../../../../default-versions.tf) / [default-versions.tofu](../../../../default-versions.tofu) so consumers can compose modules without version conflicts. If your feature requires a newer released provider version, update the repo-wide defaults and propagate across all modules rather than diverging one module or introducing a new provider:

```bash
uv run tools/versions.py --provider-min-version <x.y.z> --write-defaults
```

## Branching

- Create a direct branch named `<username>/<feature-name>` off updated `master` (`git checkout master && git pull && git checkout -b <username>/<feature-name>`), or use a fork if you do not have direct push access.
- When preparing an existing branch, do not create a new one; rebase or merge with `master` before submitting.

## Docs, Schemas, and Full CI Lint Parity

Regenerate generated artifacts whenever variables, outputs, or schemas change:

```bash
# README variables/outputs/files tables (use -x <file> to exclude local FAST provider files)
uv run tools/tfdoc.py --replace modules/<module-name>

# Schema markdown docs after any *.schema.json edit
uv run tools/schema_docs.py
```

Run `tools/lint.sh`, which mirrors [.github/workflows/linting.yml](../../../../.github/workflows/linting.yml) (boilerplate, `terraform fmt`, `tflint` on modules and FAST, `check_documentation.py`, `check_schema_docs.py`, `check_links.py`, `check_names.py`, `check_yaml_schema.py`, `duplicate-diff.py`, `yamllint`, `yapf`, `versions.tf`/`versions.tofu` diff checks, and `codespell`):

```bash
tools/lint.sh
```

> `tools/lint.sh` skips `tflint` and `codespell` with a notice if those binaries are not in `PATH`; CI always enforces them. If `versions.tf` or `versions.tofu` drift is reported, align all files with `uv run tools/versions.py --quiet`.

## Pre-Submission Self-Review

Inspect your full diff (`git diff HEAD` or `git diff master...HEAD`) before moving to E2E or PR creation. Report findings as a concise plain-text list (or "no issues found") under a `Pre-submission self-review` heading — no emojis, no status tables, and never imitate CI's `Automated PR Review` format:

- [ ] Naming conventions respected (`prefix`, descriptive filenames, provider-aligned family terms).
- [ ] `context` support and `_vars` exclusion present where warranted.
- [ ] IAM, secrets, and `tag_bindings` follow canonical Fabric interfaces verbatim.
- [ ] README `# tftest` examples or `tftest.yaml` cases cover new/changed behavior.
- [ ] **Critical testing rule:** Every modified resource block that changes plan output has corresponding updated inventory YAMLs (`tests/.../*.yaml`), audited line by line.
- [ ] JSON schemas, `.schema.md`, `tools/duplicate-diff.py` copies, and `FACTORIES.md` stay in sync.
- [ ] `tfdoc` tables regenerated, alphabetical variable/output sorting preserved, full CI lint checks pass.
- [ ] Backwards-incompatible changes have a `**Breaking Changes**` / `upgrade-note` block prepared for the PR body.

## Optional Live E2E Sandbox Verification

Run live E2E verification only once unit tests and self-review are clean:

1. **Gate — E2E Opt-in:** Ask for a sandbox GCP project ID (and parent folder / billing account if needed), stating explicitly that providing it authorizes `apply` and `destroy` with `-auto-approve`. Skip entirely if none is provided.
2. **Verify credentials:** Check `gcloud auth list` and Application Default Credentials before deploying.
3. **Create local sandbox:** Build a temporary root config in gitignored `scratch/e2e_sandbox/` pointing `source` to the **local** repo path (for example, `source = "../../modules/<module-name>"`), never to GitHub.
4. **Deploy:** Run `terraform init && terraform apply -auto-approve`. Confirm a clean apply (and an empty follow-up `terraform plan`).
5. **Read-back verification (required):** Query the live service read API (`gcloud ... describe` / equivalent `GET`), not just Terraform state, and verify every touched field and nested block matches intent.
6. **Behavioral verification (optional — Gate):** After read-back passes, ask explicitly whether to run runtime checks, describing the resources, propagation delays, and extra cost. Examples: SSH/serial on Compute, `curl`/DNS/peering checks on Networking, invoking Cloud Run/Functions/GKE, read/write on GCS/BigQuery/Pub/Sub. For **IAM conditional bindings**, run Policy Troubleshooter with the **numeric Project Number** in `--resource-name` (GCP evaluates `resource.name` using numeric project numbers):

```bash
gcloud policy-troubleshoot iam //logging.googleapis.com/projects/<PROJECT_NUMBER>/locations/global/buckets/<BUCKET> \
  --permission=logging.buckets.write \
  --principal-email=<TEST_PRINCIPAL_EMAIL> \
  --resource-name=projects/<PROJECT_NUMBER>/locations/global/buckets/<BUCKET> \
  --format="json(access,explainedPolicies[].bindingExplanations)"
```

7. **Teardown:** Run `terraform destroy -auto-approve` and delete `scratch/e2e_sandbox/`. If any check failed, fix the code and loop back through tests and linting before re-deploying.

## Sanitized Commit and PR Submission

1. **PII sanitization (strictly mandatory):** Scrub real GCP project IDs, numeric project numbers, personal emails, usernames, and custom sandbox resource names from commits, files, and the PR body; replace with generic placeholders (`my-project`, `123456789012`, `user:tester@example.com`, `test-bucket`). Verify `git status` has no stray `scratch/` files.
2. **Commit and push:** Stage only the files you changed, commit with a short imperative message, and push your branch.
3. **PR title:** Short, capitalized, imperative, no trailing dot, **no** Conventional Commits prefixes (`feat:`, `fix:`): for example, `Add native tag bindings support to modules/net-firewall-policy`.
4. **PR body:** State problem, rationale, change summary, unit tests, and E2E apply/read-back/behavioral results (noting explicitly if E2E or behavioral verification was skipped). Never edit `CHANGELOG.md` — maintainers generate it from PR labels and `upgrade-note` blocks. For any backwards-incompatible variable or YAML schema change, append at the bottom:

````markdown
**Breaking Changes**

```upgrade-note
`modules/organization`: `custom_roles` variable type changed from `map(list(string))` to `map(object({...}))`. Existing callers passing permission lists directly must pass `{ permissions = [...] }`.
```
````

5. **Gate — PR Approval:** Present the final sanitized PR title and body for explicit human approval.
6. **Create the PR:** Write the body to `/tmp/pr-body.md` with your file-writing tool (never inline backticks on the CLI and never use shell redirection/heredocs), then run:

```bash
gh pr create --title "Your PR Title" --body-file /tmp/pr-body.md
```
