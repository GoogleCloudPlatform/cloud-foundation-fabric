---
name: fabric-builder
description: Generates idiomatic Cloud Foundation Fabric (CFF) Terraform code using CFF modules. Use when users ask to create GCP resources, use Fabric modules, or generate Terraform code for Google Cloud.
---

# Fabric Builder

This skill generates idiomatic Terraform code using Cloud Foundation Fabric (CFF) modules, following established best practices and conventions.

## Core Workflow

1. **Understand Request:** Identify the GCP resources and relationships requested by the user.
2. **Fetch Module Info:** Identify the relevant CFF module(s) from the `modules/` folder on GitHub (`GoogleCloudPlatform/cloud-foundation-fabric`).
3. **Generate Terraform:** Output an idiomatic Terraform root module that consumes the CFF modules.

## Important Guidance

- **Conventions & Best Practices:** Consult [conventions.md](references/conventions.md) for guidelines on how to consume Fabric modules and write high-quality, idiomatic Terraform code.
- **Fetching Modules:** Do not invent module inputs or outputs. Use the `fabric.py` script to pull exact details (README, variables, examples) for a specific module from GitHub before using it.
  - To list available modules: `python3 scripts/fabric.py modules`
  - To fetch details for a module (README): `python3 scripts/fabric.py fetch readme <module_name>`
  - To fetch variables files: `python3 scripts/fabric.py fetch variables <module_name>`
  - To fetch outputs files: `python3 scripts/fabric.py fetch outputs <module_name>`
  - To fetch schema files (useful for factories): `python3 scripts/fabric.py fetch schemas <module_name>`
  - To fetch the latest release version: `python3 scripts/fabric.py release`

## Guidelines for Output

- **Root Module Output:** Your output must be a complete Terraform root module that calls the appropriate CFF modules to fulfill the user's requirements.
- **Use Fabric Modules:** Rely on CFF modules instead of raw `google_` resources whenever possible. 
- **Example-based Learning:** Always refer to the module's README (fetched via `scripts/fabric.py`) for correct usage examples.
- **Module Source:** When generating module calls, use a GitHub source. It should look like this: `source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref={VERSION}&depth=1"`.
- **Formatting & Validation:** Ensure the generated code is properly formatted. If possible, run `terraform fmt`, `terraform validate`, and `terraform plan` to check your work.
