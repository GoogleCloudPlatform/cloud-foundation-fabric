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

- **Conventions & Best Practices:** You MUST read [conventions.md](references/conventions.md) before writing any Terraform code. It contains critical rules for CFF such as variable ordering, naming, and module boundaries.
- **Fetching Modules:** Do not invent module inputs or outputs. Use the `fetch_module.py` script to pull exact details (README, variables, examples) for a specific module from GitHub before using it.
  - To list available modules: `python3 scripts/fetch_module.py`
  - To fetch details for a module (README): `python3 scripts/fetch_module.py <module_name>`
  - To fetch variables files: `python3 scripts/fetch_module.py <module_name> --variables`
  - To fetch outputs files: `python3 scripts/fetch_module.py <module_name> --outputs`
  - To fetch the latest release version: `python3 scripts/fetch_module.py --latest-release`

## Guidelines for Output

- **Use Fabric Modules:** Rely on CFF modules instead of raw `google_` resources whenever possible. Unrelated resources should generally not be in the same module unless using a factory.
- **Example-based Learning:** Always refer to the module's README (fetched via script) for correct usage examples.
- **Module Source:** When generating module calls, use a GitHub source. It should look something like this: `source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref={VERSION}&depth=1"`. Update ref using the latest release version fetched using `fetch_module.py --latest-release`
