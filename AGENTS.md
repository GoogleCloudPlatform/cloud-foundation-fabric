# Cloud Foundation Fabric (CFF) — Agent Instructions

Cloud Foundation Fabric is a monorepo of composable Terraform/OpenTofu modules (`modules/`) and an opinionated, stage-based GCP landing zone (`fast/`). Start here for the repository map, non-negotiable guardrails, and exact pointers to the repository skills.

## Repository Map

- `modules/` — Composable GCP modules, including in-module YAML factories (`factories_config`) and pure aggregation factories (`project-factory`, `net-vpc-factory`).
- `fast/` — Sequential landing-zone stages (`0-org-setup`, `1-vpcsc`, `2-networking`, `2-project-factory`, `2-security`, `3-secops-dev`), addons, and `project-templates/` reference designs.
- `skills/` — Audience-scoped agent skills (`fabric/`, `fast/`, `contributor/`, `maintainer/`). See [skills/README.md](skills/README.md).
- `tests/` — Plan-based `pytest` + `tftest` suites (`tests/examples/`, `tests/modules/`, `tests/fast/`, `tests/schemas/`, `tests/skills/`).
- `tools/` — Linting, documentation (`tfdoc.py`), schema docs (`schema_docs.py`), version sync (`versions.py`), duplicate-file sync (`duplicate-diff.py`), and inventory generation (`generate_plan_summary.py`).
- `adrs/` — Architecture Decision Records (ignore `Rejected`; treat `Draft`/`Proposed` as directional; on conflict, current golden-path code wins).
- `default-versions.tf` / `default-versions.tofu` — Single source of truth for repo-wide Terraform, OpenTofu, and provider constraints.
- [FACTORIES.md](FACTORIES.md) — Canonical catalog of all module and FAST YAML factories and their JSON schemas.
- [CURSED_KNOWLEDGE.md](CURSED_KNOWLEDGE.md) — Known Terraform, OpenTofu, and GCP provider traps.
- [CONTRIBUTING.md](CONTRIBUTING.md) — Human contributor handbook.

## Skills and Canonical Guides

If your harness does not auto-load skills, read the relevant plain-Markdown file directly before designing, coding, reviewing, or triaging:

| Task | Entry guide | Canonical references |
| :--- | :--- | :--- |
| Implement a feature, module, factory, test, or PR | [cff-contributing](skills/contributor/cff-contributing/SKILL.md) | [design/modules.md](skills/contributor/cff-contributing/design/modules.md), [design/interfaces.md](skills/contributor/cff-contributing/design/interfaces.md), [design/factories.md](skills/contributor/cff-contributing/design/factories.md), [design/fast.md](skills/contributor/cff-contributing/design/fast.md), [conventions/hcl.md](skills/contributor/cff-contributing/conventions/hcl.md), [workflow/testing.md](skills/contributor/cff-contributing/workflow/testing.md), [workflow/pr-lifecycle.md](skills/contributor/cff-contributing/workflow/pr-lifecycle.md) |
| Review a PR or local branch diff | [cff-pr-review](skills/maintainer/cff-pr-review/SKILL.md) | Delegates design, HCL, and testing criteria to `cff-contributing` above |
| Triage GitHub issues or sweep the backlog | [cff-issue-triage](skills/maintainer/cff-issue-triage/SKILL.md) | Delegates fit and design criteria to `cff-contributing`; hands off at Design Sign-off |
| Cut a new Fabric release | [cff-release](skills/maintainer/cff-release/SKILL.md) | Release tagging, changelog generation, and version updates |

## Architectural Compass

- **Logical-entity encapsulation and single-resource-context boundary:** Each module encapsulates one complete functional unit (resource + IAM + sub-resources + org policies/sinks where applicable). Unrelated resources never share a module except in the two aggregation factories (`project-factory` and `net-vpc-factory`). Reject thin single-resource pass-through wrappers, standalone feature modules (such as central IAM), and companion project-level IAM inside service modules (expose wiring outputs instead).
- **Canonical interfaces and unison:** Reuse Fabric's established shapes verbatim (`iam*`, `context` with `_vars` exclusion, `tag_bindings`, `prefix`, secrets `{value, path, wo_version}`). The resource-management trio (`organization`, `folder`, `project`) always moves in unison for every shared feature.
- **Compact, composable HCL:** Design compact variable spaces with `object()` and `optional()` (omit explicit defaults unless module logic or ergonomics need them); prefer maps over lists for `for_each` stability; avoid `any`, random suffixes, `data` sources, `local-exec`, and external tools; tie primary outputs to internal setup with `depends_on` where appropriate.
- **Research before designing:** Verify arguments and provider availability (`google` vs `google-beta`) against **released** provider docs matching [default-versions.tf](default-versions.tf), inspect golden-path siblings (`project`, `compute-vm`, `net-vpc`, `project-factory`, `net-vpc-factory`, `vpc-sc`), check [adrs/](adrs/), and check [CURSED_KNOWLEDGE.md](CURSED_KNOWLEDGE.md).
- **Repo-wide version pins only:** Never hand-edit per-module `versions.tf` or `versions.tofu`; update `default-versions.*` and propagate with `tools/versions.py`.
- **Two-tier factory DAG:** In `modules/project-factory`, Pass 1 must never depend on Pass 2 outputs.

## Mechanical Gotchas and Verification

- **Alphabetical order (`[SV]` error):** Keep `variables*.tf` and `outputs*.tf` in strict alphabetical order; `check_documentation.py` fails otherwise.
- **Generated docs and schemas:** Never hand-edit `<!-- BEGIN TFDOC -->` sections — run `python3 tools/tfdoc.py --replace <dir>`. Whenever a `.schema.json` changes, regenerate `.schema.md` (`python3 tools/schema_docs.py`), sync copies (`python3 tools/duplicate-diff.py`), and keep [FACTORIES.md](FACTORIES.md) aligned.
- **Formatting and hygiene:** Keep HCL lines within 79 characters; format Terraform with `terraform fmt -recursive`, Python with `yapf -i` (`.style.yapf`), and YAML with `yamllint -c .yamllint --no-warnings`; include the Apache 2.0 header checked by `tools/check_boilerplate.py`.
- **OpenTofu and permadiff traps:** Avoid `provider::` functions, guard nullable collections, use `!= null` (not `== true`) on dynamic blocks, and use `== null` instead of `try()` on partially-known `for_each` maps. See [conventions/hcl.md](skills/contributor/cff-contributing/conventions/hcl.md) for details and [workflow/testing.md](skills/contributor/cff-contributing/workflow/testing.md) for the `terraform_data` local-dump debugging pattern.
- **PR conventions:** Use capitalized imperative PR titles (no Conventional Commits prefixes), never edit `CHANGELOG.md`, scrub all real project IDs/numbers/emails, and include `**Breaking Changes**` + an `upgrade-note` block for breaking changes.

### Common Commands

```bash
# Full CI lint parity
tools/lint.sh

# Targeted module README example tests
pytest -n auto -k 'modules and <module-name>:' tests/examples

# Targeted module or FAST tftest.yaml tests (note underscores in tests/modules/)
pytest 'tests/modules/<module_name>/tftest.yaml::<test_name>' --tb=short -s
pytest 'tests/fast/stages/s<stage_num>_<stage_name>/tftest.yaml::<test_name>' --tb=short -s

# Skill contract tests
pytest tests/skills

# Regenerate test inventory (never hand-code inventories; always audit git diff tests/)
python3 tools/generate_plan_summary.py <tftest.yaml-or-example> <test_name> --save
```
