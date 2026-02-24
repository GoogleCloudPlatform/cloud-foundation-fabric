# Cloud Foundation Fabric (CFF)

## Project Overview

Cloud Foundation Fabric is a comprehensive suite of Terraform modules and end-to-end blueprints designed for Google Cloud Platform (GCP). It serves two primary purposes:

1.  **Modules:** A library of composable, production-ready Terraform modules (e.g., `project`, `net-vpc`, `gke-cluster`).
2.  **FAST (Fabric FAST):** An opinionated, stage-based landing zone toolkit for bootstrapping enterprise-grade GCP organizations.

## Key Components

### 1. Modules (`/modules`)

*   **Philosophy:** Lean, composable, and close to the underlying provider resources.
*   **Structure:**
    *   Standardized interfaces: IAM, logging, organization policies, etc.
    *   Self-contained: Dependency injection via context variables is preferred over complex remote state lookups within modules.
    *   Flat: avoid using sub-modules to reduce complexity and minimize layer traversals.
    *   **Naming:** Avoid random suffixes; use explicit `prefix` variables.
*   **Usage:** Modules are designed to be forked/owned or referenced via Git tags (e.g., `source = "github.com/...//modules/project?ref=v30.0.0"`).

### 2. FAST (`/fast`)

*   **Purpose:** Rapidly set up a secure, scalable GCP organization.
*   **Architecture:** Divided into sequential "stages" (0-org-setup, 1-vpcsc, 2-security, 2-networking, etc.).
*   **Factories:** Uses YAML-based "factories" (e.g., Project Factory) to drive configuration at scale.

### 3. Tools (`/tools`)

*   Python-based utility scripts for documentation, linting, and CI/CD tasks.
*   **Key Scripts:**
    *   `tfdoc.py`: Auto-generates input/output tables in `README.md` files.
    *   `check_boilerplate.py`: Enforces license headers.
    *   `check_documentation.py`: Verifies README consistency.
    *   `changelog.py`: Generates CHANGELOG.md sections based on version diffs.

## Development Workflow

### Prerequisites

*   **Terraform** (or OpenTofu)
*   **Python 3.10+**
*   **Dependencies:**
    ```bash
    pip install -r tests/requirements.txt
    pip install -r tools/requirements.txt
    ```

### Common Tasks

#### 1. Formatting & Linting

Always format code and update documentation before committing.

```bash
# Format Terraform code
terraform fmt -recursive

# Update module documentation (variables/outputs tables)
./tools/tfdoc.py modules/<module-name>

# Run all lint checks (wraps pre-commit hooks)
./tools/lint.sh
```

#### 2. Testing

Tests are written in Python using `pytest` and the [`tftest`](https://pypi.org/project/tftest/) library.

```bash
# Run all tests
pytest tests

# Run specific module examples
pytest -k 'modules and <module-name>:' tests/examples

# Run tests from a specific file
pytest tests/examples/test_plan.py
```

**Note:** `TF_PLUGIN_CACHE_DIR` is recommended to speed up tests.

#### 3. Contributing

*   **Branching:** Use `username/feature-name`.
*   **Commits:** Atomic commits with clear messages.
*   **Docs:** Do not manually edit the variables/outputs tables in READMEs; use `tfdoc.py`.

## Architecture & Conventions

*   **Variables:** Prefer object variables (e.g., `iam = { ... }`) over many individual scalar variables.
*   **IAM:** Implemented within resources (authoritative `_binding` or additive `_member`) via standard interfaces.
*   **Outputs:** Explicitly depend on internal resources to ensure proper ordering (`depends_on`).
*   **File Structure:**
    *   Move away from `main.tf`, `variables.tf`, `outputs.tf`.
    *   Use descriptive filenames: `iam.tf`, `gcs.tf`, `mounts.tf`.
*   **Lexical Order:** Preserve lexical order when adding attributes to schemas, variable types, and maps.
*   **IAM References:** Always validate new principal references against the interpolation tables in `modules/project-factory/README.md`. Use correct namespaces (e.g. `$iam_principals:service_accounts/_self_/...` for local SAs).
