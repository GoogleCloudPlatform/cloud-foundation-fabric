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
# Format Terraform code (check then fix)
terraform fmt -check -recursive modules/<module-name>
terraform fmt -recursive modules/<module-name>

# Check README consistency (variables table must match variables.tf)
python3 tools/check_documentation.py modules/<module-name>

# Regenerate README variables/outputs tables when check fails
python3 tools/tfdoc.py --replace modules/<module-name>

# YAML linting
yamllint -c .yamllint --no-warnings <yaml-files>

# License/boilerplate check
python3 tools/check_boilerplate.py --scan-files <files>
```

**Common gotcha — unsorted variables (`[SV]` error):** `check_documentation.py` requires variables in `variables.tf` to be in strict alphabetical order. When adding a new variable, insert it at the correct alphabetical position, not at the top of the file.

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

## Adding Context Support to a Module

Several modules support symbolic variable interpolation via a `context` variable. This allows callers to pass symbolic references like `"$project_ids:myprj"` instead of raw values, which get resolved at plan time.

### Pattern

**1. Add a `context` variable** in `variables.tf` at its alphabetical position. Use keys relevant to the module — standard keys are `locations`, `networks`, `project_ids`, `subnets`; module-specific keys may be added (e.g., `kms_keys`, `artifact_registries`, `secrets`):

```hcl
variable "context" {
  description = "Context-specific interpolations."
  type = object({
    kms_keys    = optional(map(string), {})
    locations   = optional(map(string), {})
    networks    = optional(map(string), {})
    project_ids = optional(map(string), {})
  })
  default  = {}
  nullable = false
}
```

**2. Build `ctx` and `ctx_p` locals** in `main.tf`. If the module has IAM condition support, exclude `condition_vars` from the flattening (it is passed directly to `templatestring()`):

```hcl
locals {
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } # add: if k != "condition_vars"  — only when condition_vars is a key
  }
  ctx_p      = "$"
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
  region     = lookup(local.ctx.locations, var.region, var.region)
}
```

**3. Apply lookups in resources.** Three patterns:

```hcl
# Simple field
project = local.project_id

# Nullable field (null must stay null, not looked up)
encryption_key_name = (
  var.encryption_key_name == null
  ? null
  : lookup(local.ctx.kms_keys, var.encryption_key_name, var.encryption_key_name)
)

# Deeply optional nested field
private_network = (
  try(var.network_config.psa_config.private_network, null) == null
  ? null
  : lookup(local.ctx.networks, var.network_config.psa_config.private_network,
      var.network_config.psa_config.private_network)
)

# Per-element list
nat_subnets = [for s in var.nat_subnets : lookup(local.ctx.subnets, s, s)]
```

**4. Long ternaries** are wrapped in parentheses with condition and branches on separate lines:

```hcl
ip_address = (
  var.address == null
  ? null
  : lookup(local.ctx.addresses, var.address, var.address)
)
```

### Tests

Add a `context` test alongside existing module tests:

- `tests/modules/<module_name>/tftest.yaml` — declare the module path and list `context:` under `tests:`
- `tests/modules/<module_name>/context.tfvars` — provide all required module variables using symbolic references; include a `context` block with maps that resolve them
- `tests/modules/<module_name>/context.yaml` — assert resolved (concrete) values in the plan output

### README example

Modify one existing README example (do not add a new one) to demonstrate context usage. The resolved values should match the existing inventory YAML so no inventory changes are needed.

## Architecture & Conventions

*   **Variables:** Prefer object variables (e.g., `iam = { ... }`) over many individual scalar variables.
*   **IAM:** Implemented within resources (authoritative `_binding` or additive `_member`) via standard interfaces.
*   **Outputs:** Explicitly depend on internal resources to ensure proper ordering (`depends_on`).
*   **File Structure:**
    *   Move away from `main.tf`, `variables.tf`, `outputs.tf`.
    *   Use descriptive filenames: `iam.tf`, `gcs.tf`, `mounts.tf`.
