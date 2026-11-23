---
name: fabric-builder
description: Generates idiomatic Cloud Foundation Fabric (CFF) Terraform configurations and YAML factory datasets (module composition, project-factory, net-vpc-factory, vpc-sc, in-module factories_config, and FAST stage YAML datasets). Use when creating GCP resources with Fabric modules, composing root configurations, authoring or validating Fabric YAML factory files against JSON schemas, or wiring $context interpolation and data_defaults/data_overrides/data_merges. For full FAST 2-networking topology design, use fast-networking instead.
---

# Fabric Builder

Compose idiomatic Terraform root modules using Cloud Foundation Fabric (CFF) modules and author schema-validated YAML datasets for Fabric module factories and FAST stages. For full end-to-end FAST `2-networking` topology design, use `fast-networking`.

## Reference Routing (Read Only What Applies)

Keep context lean by opening only the guide(s) matching the files you are authoring:

- **Authoring Terraform HCL root modules** -> read [references/conventions.md](references/conventions.md) for module composition, sources, providers, variables, and dependency conventions.
- **Authoring or validating YAML factory datasets** (either alongside a root module or in an existing FAST stage) -> read [references/factories.md](references/factories.md) for modelines, `$context:` interpolation, precedence, multi-pass DAG order, and schema gotchas. When authoring both HCL and YAML together, follow both guides.

## Core Workflow

1. **Understand the request:** Identify the GCP resources, whether a standard module or YAML factory (`project-factory`, `net-vpc-factory`, `vpc-sc`, in-module `factories_config`) fits best, and the target Fabric release tag.
2. **Inspect exact module and factory contracts:** Do not invent module variables, outputs, or YAML keys from memory. Query the live Fabric repository with `scripts/fabric.py`:
   - List modules: `python3 scripts/fabric.py modules`
   - Latest release tag: `python3 scripts/fabric.py release`
   - Fetch module interface: `python3 scripts/fabric.py fetch readme|variables|outputs <module>` (accepts `--ref <tag>`)
   - List factory-enabled modules and FAST stages, or inspect one target's keys and schemas: `python3 scripts/fabric.py factories [target]`
   - Fetch JSON schemas (stdout or saved to a folder): `python3 scripts/fabric.py fetch schemas <module_or_stage> [--stage] [--ref <tag>] [--out schemas/]`
   - Validate YAML factory files against `# yaml-language-server: $schema=...` modelines: `uv run --with pyyaml --with jsonschema python3 scripts/fabric.py validate <data_dir_or_file> --require-modeline`
   - If the host uses custom TLS interception, pass `--no-ssl-verify` before the subcommand.
3. **Author HCL and/or YAML:** Prefer CFF modules over raw `google_*` resources, rely on module README examples, and validate every YAML dataset against its JSON schema.
4. **Verify before finishing:** Run `terraform fmt`, `terraform validate`, and `terraform plan` (when Terraform is available and appropriate) plus `fabric.py validate` on any YAML files, then check the rationale-backed points below.

## Pre-Finish Check

- **Alphabetical `variables.tf`:** Keep variable declarations in strict alphabetical order so larger root configs stay easy to scan and match Fabric tooling conventions.
- **Omit root `required_providers` / `required_version`:** Fabric modules already carry uniform, compatible version constraints, so omitting root constraints lets Terraform resolve versions cleanly from the consumed modules without lock-in or duplicate maintenance.
- **Defaults in `variables.tf`, not a stray `terraform.tfvars`:** Put user-provided or sensible defaults directly in `variables.tf` so the root module plans cleanly out of the box without a hidden sidecar file; create `terraform.tfvars` only when the user asks for one.
- **Keep `provider` blocks free of `project`, `region`, and `zone`:** Passing scope explicitly to each module keeps multi-project and multi-region compositions predictable and self-documenting.
- **Uniform module source tags:** Pin every GitHub module source to the same release tag with `?ref=<tag>&depth=1` (matching `fabric.py release` unless the user specifies another tag or local path).
- **Schema-validated YAML datasets:** When authoring YAML factory data, include a `# yaml-language-server: $schema=...` modeline on line 1 and validate with `fabric.py validate` so typos and invalid keys fail before `terraform plan`.
