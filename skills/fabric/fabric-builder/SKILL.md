---
name: fabric-builder
description: Generates idiomatic Cloud Foundation Fabric (CFF) Terraform code through module composition using CFF modules. Use when users ask to create GCP resources, compose Fabric modules into a root configuration, or generate Terraform HCL for Google Cloud. For authoring or validating Fabric YAML factory datasets (project-factory, net-vpc-factory, vpc-sc, factories_config, or FAST stage datasets), use fabric-factories instead.
---

# Fabric Builder

This skill generates idiomatic Terraform root modules through Cloud Foundation Fabric (CFF) module composition, following established best practices and conventions. When the task involves authoring or validating YAML factory datasets (for `project-factory`, `net-vpc-factory`, `vpc-sc`, in-module `factories_config` keys, or FAST stages), hand off the YAML data layer to `fabric-factories`.

## Core Workflow

1. **Understand Request:** Identify the GCP resources and relationships requested by the user.
2. **Fetch Module Info:** Identify the relevant CFF module(s) from the `modules/` folder on GitHub (`GoogleCloudPlatform/cloud-foundation-fabric`).
3. **Generate Terraform:** Output an idiomatic Terraform root module that consumes the CFF modules according to [conventions.md](references/conventions.md).
4. **Verify Against Conventions:** Run the pre-finish checklist below before presenting or committing generated code.

## Important Guidance

- **Conventions & Best Practices:** Consult [conventions.md](references/conventions.md) for guidelines on how to consume Fabric modules and write high-quality, idiomatic Terraform code (including module sources, version constraints, and provider configuration).
- **YAML Factory Handoff:** Wire `factories_config` paths in HCL here when composing modules, and hand off authoring and JSON-schema validation of the YAML data files themselves to `fabric-factories`.
- **Fetching Modules:** Do not invent module inputs or outputs. Use the `fabric.py` script to pull exact details (README, variables, examples) for a specific module from GitHub before using it.
  - To list available modules: `python3 scripts/fabric.py modules`
  - To fetch details for a module (README): `python3 scripts/fabric.py fetch readme <module_name>`
  - To fetch variables files: `python3 scripts/fabric.py fetch variables <module_name>`
  - To fetch outputs files: `python3 scripts/fabric.py fetch outputs <module_name>`
  - To fetch schema files (useful for factories): `python3 scripts/fabric.py fetch schemas <module_name>`
  - To fetch the latest release version: `python3 scripts/fabric.py release`
  - **SSL Certification Verification**: If you run into SSL certificate issues on your host machine, use the `--no-ssl-verify` flag (e.g., `python3 scripts/fabric.py --no-ssl-verify fetch readme <module_name>`).

## Guidelines for Output

- **Root Module Output:** Your output must be a complete Terraform root module that calls the appropriate CFF modules to fulfill the user's requirements.
- **Follow Conventions:** Strictly adhere to [conventions.md](references/conventions.md) for module sources, version constraints, provider configuration, and coding style.
- **Use Fabric Modules:** Rely on CFF modules instead of raw `google_` resources whenever possible.
- **Example-based Learning:** Always refer to the module's README (fetched via `scripts/fabric.py`) for correct usage examples.
- **Formatting & Validation:** Ensure the generated code is properly formatted. If possible, run `terraform fmt`, `terraform validate`, and `terraform plan` to check your work.

## Pre-Finish Convention Check

Before returning generated Terraform code, verify every one of these recurring checks:

- `variables.tf` declarations are sorted in strict alphabetical order.
- No root `required_providers` or `required_version` constraints are declared (let Terraform resolve constraints from the consumed CFF modules).
- No stray `terraform.tfvars` file is created unless explicitly requested by the user.
- `provider "google"` / `provider "google-beta"` blocks do not set `project`, `region`, or `zone` (pass those explicitly to modules).
- All GitHub module sources pin the exact same release tag with `?ref=<tag>&depth=1`.
