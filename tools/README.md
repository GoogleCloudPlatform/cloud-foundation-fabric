# Cloud Foundation Fabric (CFF) Tools

This directory contains utility scripts and tools used to automate linting, formatting, validation, documentation generation, and testing across the Cloud Foundation Fabric repository.

## Categorized Tools

### 1. Documentation Generation
Tools for automatically generating documentation tables or formats from source configurations.

- **[tfdoc.py](./tfdoc.py)**: Automatically generates inputs, outputs, and files documentation tables inside module READMEs.
- **[schema_docs.py](./schema_docs.py)**: Recursively parses and compiles JSON schemas into readable, markdown-based documentation tables.
- **[format_tftest.py](./format_tftest.py)**: Formats Terraform code blocks containing `# tftest` directives inside markdown files.
- **[update_schema_links.py](./update_schema_links.py)**: Updates the schema URLs in YAML modelines across a directory to match a specific CDN or versioned source.
- **[pre-commit-tfdoc.sh](./pre-commit-tfdoc.sh)**: Pre-commit hook script to run `tfdoc.py` updates and verify README alignment.

### 2. Testing, Planning & Emulation
Tools to run testing sandboxes, parse plans, and simulate/evaluate agent behaviors.

- **[skill-turn-harness/](./skill-turn-harness)**: A hybrid Python/SDK-based test harness for developing, running, and grading Antigravity skills.
- **[generate_plan_summary.py](./generate_plan_summary.py)**: Generates structured plan summaries of resources and their changes for README examples or `tftest.yaml` tests.
- **[plan_summary.py](./plan_summary.py)**: An internal helper script to parse, format, and filter Terraform plan structures for automated test assertions.
- **[create_e2e_sandbox.sh](./create_e2e_sandbox.sh)**: Bootstraps an isolated end-to-end sandbox directory to safely provision and test CFF examples.

### 3. Repository Maintenance & Automation
Tools for version management, automated reviews, GCP service definitions, and release automation.

- **[changelog.py](./changelog.py)**: Automates the generation and maintenance of the `CHANGELOG.md` based on Git diffs and version changes.
- **[versions.py](./versions.py)**: Synchronizes required engine and provider version constraints across standard provider configuration files in the repository.
- **[build_service_agents.py](./build_service_agents.py)**: Parses the official Google Cloud documentation to build a structured representation of GCP service agents and their properties.
- **[pr_review.py](./pr_review.py)**: Leverages the Gemini API to perform automated, context-aware code reviews on pull requests.
- **[state_iam.py](./state_iam.py)**: Parses and displays authoritative IAM binding configurations directly from a local Terraform state file.

### 4. Linting, Quality & Compliance
Tools for maintaining style guide compliance, licensing, validation, and content/rule verification.

- **[check_boilerplate.py](./check_boilerplate.py)**: Scans files to verify that correct Google license headers and boilerplates are present.
- **[check_documentation.py](./check_documentation.py)**: Recursively verifies that the variables and outputs tables generated inside module `README.md` files are up-to-date.
- **[check_links.py](./check_links.py)**: Recursively parses Markdown files to validate external links, internal links, and anchor destinations.
- **[check_names.py](./check_names.py)**: Evaluates name length constraints and formatting for specified GCP Terraform resources to ensure compatibility.
- **[check_schema_docs.py](./check_schema_docs.py)**: Recursively checks if the Markdown documentation generated from JSON schemas is fully up-to-date.
- **[check_yaml_schema.py](./check_yaml_schema.py)**: Validates YAML configuration and factory data files against their defined JSON schema modelines.
- **[duplicate-diff.py](./duplicate-diff.py)**: Verifies content alignment for files that must remain identical across different stages or modules (e.g. schemas, policies).
- **[lint.sh](./lint.sh)**: A shell script wrapping boilerplate, YAML, and Terraform style and format checks.
- **[tflint-fast.py](./tflint-fast.py)**: Runs the `tflint` linter against FAST stages by setting them up in temporary isolated environments.
