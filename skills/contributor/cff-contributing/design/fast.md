# Module-to-FAST Boundary

This guide covers the contract between Fabric modules and FAST stages, plus the cross-cutting checks required when a module change affects FAST. Deep FAST stage internals (`0-org-setup`, `1-vpcsc`, `2-networking`, `2-security`) are not yet documented here — inspect the target stage directly when changing stage-internal logic.

## Where Factories Live

Factories belong in `modules/` by default. A FAST stage implements its own YAML factory loader (`factory-*.tf`) only when it needs to iterate over standard modules or raw Terraform resources across a stage-level topology (for example, `dns` zones, `net-firewall-policy`, `ncc_hubs`, `net-cloud-armor`). See the `Implementation Type` taxonomy in [FACTORIES.md](../../../../FACTORIES.md#fast-stages) before introducing a new stage-level factory.

## FAST Stage Contracts Module Contributors Must Preserve

- **`dataset` + `paths` layout:** Stages configure external YAML via `factories_config = { dataset = optional(string, ...), paths = optional(object({ ... }), {}) }` and a stage `defaults.yaml` ([dataset-base-path ADR](../../../../adrs/20260210-dataset-base-path.md)). Do not break relative path handling (paths starting with `/` or `.` bypass the dataset base path).
- **Standalone usage:** Every FAST stage must remain usable in isolation driven only by its variables, without hard coupling to another stage's remote state.
- **Compact map-based stage interfaces and output files:** Stages exchange contracts via a small number of broad map variables (`folder_ids`, `service_accounts`, `tag_names`, etc.) mirrored into generated GCS/local `tfvars` and provider output files. Reuse existing contract maps rather than adding narrow per-resource variables, and keep generated output files in sync when a stage contract changes.
- **Resource name length budget:** FAST enforces maximum resource name lengths under a 10-character prefix via `python3 tools/check_names.py --prefix-length=10 --failed-only fast/stages`.

## Cross-Cutting PR Checklist for FAST-Consumed Modules

Changing variables, outputs, or schemas in any module consumed by `fast/` (`fast/stages/`, `fast/addons/`, or `fast/project-templates/`) can affect FAST even when the module itself has no `factories_config` or `schemas/`:

- **Find FAST consumers first:** Check callers under `fast/` and the `## FAST Stages` / `## FAST Addons & Project Templates` tables in [FACTORIES.md](../../../../FACTORIES.md#fast-stages) rather than relying on a fixed module list.
- **Check duplicated files:** Inspect [tools/duplicate-diff.py](../../../../tools/duplicate-diff.py) — mirrored schemas such as `project.schema.json`, `folder.schema.json`, `subnet.schema.json`, `firewall-rules.schema.json`, `org-policies.schema.json`, `tags.schema.json`, `budget.schema.json`, `access-level.schema.json`, and `perimeter.schema.json` are copied across modules and multiple FAST stages and must stay byte-identical.
- **Check stage-owned factories and single-copy schemas:** Stage-implemented module factories (such as `dns`, `certificate-authority-service`, `net-address`, `net-firewall-policy`, `net-cloudnat`, `net-vlan-attachment`, `kms`, `billing-account`, and `net-vpn-ha`) load YAML in `fast/stages/<stage>/factory-*.tf` and validate against single-copy `fast/stages/<stage>/schemas/*.schema.json` files outside `tools/duplicate-diff.py`. Update the stage factory loader (when it reconstructs module inputs rather than passing them straight through), the single-copy `*.schema.json` and regenerated `*.schema.md`, and stage tests under `tests/fast/stages/s<num>_<name>/`. Narrow role-specific consumers (such as `compute-vm` or `net-lb-int` in `factory-nva.tf`) only expose a subset of module inputs and do not require 1:1 parity for unrelated module features.
- **Check secret shapes in FAST schemas:** FAST schemas carrying secrets must declare the canonical `{ value, path, wo_version }` object with `additionalProperties: false` and document `path` as relative to the stage directory ([write-only-secrets ADR](../../../../adrs/modules/20261029-write-only-secrets.md)).
- **Verify FAST before opening a PR:**
  - Run `python3 tools/duplicate-diff.py` and `uv run tools/schema_docs.py`.
  - Run `python3 tools/check_yaml_schema.py modules fast` and `python3 tools/check_schema_docs.py --no-show-summary modules fast blueprints`.
  - Run `python3 tools/tflint-fast.py` and `python3 tools/check_names.py --prefix-length=10 --failed-only fast/stages`.
  - Run impacted FAST plan tests using a temporary copy so local `*.tfvars` do not interfere: `TFTEST_COPY=1 pytest tests/fast/stages/s<num>_<name>`.
