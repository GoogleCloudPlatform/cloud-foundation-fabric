# Cloud Foundation Fabric (CFF)

## Project Overview

Cloud Foundation Fabric is a comprehensive suite of Terraform modules and end-to-end blueprints designed for Google Cloud Platform (GCP). It serves two primary purposes:

1.  **Modules:** A library of composable, production-ready Terraform modules (e.g., `project`, `net-vpc`, `gke-cluster`).
2.  **FAST (Fabric FAST):** An opinionated, stage-based landing zone toolkit for bootstrapping enterprise-grade GCP organizations.

## Key Components

### 1. Modules (`/modules`)

*   **Philosophy:** Lean, composable, and close to the underlying provider resources. Modules are designed to be containers for all aspects related to usage of a resource type (e.g., folder, project, vpc, etc.). This includes IAM, sub-resources (e.g. subnets and routes for a network), and org policies where applicable.
*   **Boundary:** Unrelated resources (like a dataset for a project) should never be part of the same module, except in the two "aggregation modules" (`project-factory` and `net-vpc-factory`). Never break this boundary as a first approach.
*   **Structure:**
    *   Standardized interfaces: IAM, logging, organization policies, etc.
    *   Self-contained: Dependency injection via context variables is preferred over complex remote state lookups within modules.
    *   Flat: avoid using sub-modules to reduce complexity and minimize layer traversals.
    *   **Naming:** Avoid random suffixes; use explicit `prefix` variables.
*   **Factories:** Many modules implement a data-driven "factory" pattern (often via a `factories_config` variable) to manage resources at scale using YAML data files. See `FACTORIES.md` for a comprehensive list.
    *   **Validation:** Factory YAML files must conform to JSON schemas (typically stored in a `schemas/` folder). Use a modeline (e.g., `# yaml-language-server: $schema=../schemas/project.schema.json`) to enable IDE validation.
*   **Usage:** Modules are designed to be forked/owned or referenced via Git tags (e.g., `source = "github.com/...//modules/project?ref=v30.0.0"`).

### 2. FAST (`/fast`)

*   **Purpose:** Rapidly set up a secure, scalable GCP organization.
*   **Architecture:** Divided into sequential "stages" (0-org-setup, 1-vpcsc, 2-security, 2-networking, etc.).
*   **Factories:** Extensively uses YAML-based datasets and module factory patterns to drive configuration at scale, acting as a "translation machine" that expresses different architectural designs without changing the underlying stage code. Factories are generally implemented in the underlying modules, not in FAST stages, *unless* the stage needs to iterate over standard modules or resources (e.g., `dns` zones, `net-firewall-policy`, `ncc_hubs`).

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

# Format Python code
# ALWAYS run yapf with the repository's .style.yapf configuration after editing any Python file.
# You can use the local virtual environment or run it directly:
~/venv/bin/yapf -i <python-files>

# Check README consistency (variables table must match variables.tf)
python3 tools/check_documentation.py modules/<module-name>

# Regenerate README variables/outputs tables when check fails
# Note: tfdoc uses special HTML comments (<!-- BEGIN TFDOC -->) in READMEs. Do not manually edit these sections.
# You can configure tfdoc via HTML comments in the README (e.g., <!-- TFDOC OPTS files:1 show_extra:1 -->).
# To add a file description to the generated table, use a comment in the .tf file: # tfdoc:file:description My description.
python3 tools/tfdoc.py --replace modules/<module-name>

# YAML linting
yamllint -c .yamllint --no-warnings <yaml-files>

# License/boilerplate check
python3 tools/check_boilerplate.py --scan-files <files>

# Schema changes
# A schema change should be reflected in all the other places that use the same schema.
# These are documented in and can be checked via tools/duplicate-diff.py.
```

**Common gotcha — unsorted variables (`[SV]` error):** `check_documentation.py` requires variables in `variables.tf` to be in strict alphabetical order. When adding a new variable, insert it at the correct alphabetical position, not at the top of the file.

#### 2. Testing

Our testing philosophy is simple: test to ensure the code works and does not break due to dependency changes. **Example-based testing via `README.md` is the preferred approach.**

Tests are triggered from HCL Markdown fenced code blocks using a special `# tftest` directive at the end of the block.

```hcl
module "my-module" {
  source = "./modules/my-module"
  # ...
}
# tftest modules=1 resources=2 inventory=my-inventory.yaml
```

*   **Inventory files (`YAML`):** Used to assert specific values, resource counts, or outputs from the terraform plan against an expected dataset. **DO NOT hand-code inventory files from scratch.** Extract only the necessary bits relevant to the test scenario from the generated output.
*   **External Files:** If a README test requires external files (e.g., for factories), mock them using the `# tftest-file id=myid path=path/to/file.yaml` directive in a separate YAML block, and add `files=myid` to the `tftest` directive.
*   **FAST Stages & `tftest.yaml`:** FAST stages often lack README examples. For these, use `tftest`-based tests by creating `tfvars` and `yaml` inventory pairs in `tests/fast/...` and tying them together with a `tftest.yaml` file.
*   **Legacy Tests:** Python-based tests using `pytest` and `tftest` are supported but example-based tests should be used whenever possible.

```bash
# Run all tests
pytest tests

# Run specific module examples
pytest -k 'modules and <module-name>:' tests/examples

# Run a single specific example test (useful for debugging)
pytest -s 'tests/examples/test_plan.py::test_example[terraform:modules/<module-name>:Heading Name:Index]'

# Automatically generate an inventory file from a successful plan
pytest -s 'tests/examples/test_plan.py::test_example[terraform:modules/<module-name>:Heading Name:Index]'
```

**Note:** `TF_PLUGIN_CACHE_DIR` is recommended to speed up tests.

#### 4. Module-level `tftest.yaml` Tests

Modules with their own `tests/modules/<module_name>/tftest.yaml` define test scenarios (e.g., context resolution, IAM variants) using `tfvars` + YAML inventory pairs. Run them individually:

```bash
# Run a specific test from a module's tftest.yaml
pytest 'tests/modules/<module_name>/tftest.yaml::<test_name>' --tb=short -s
```

For example:
```bash
pytest 'tests/modules/organization/tftest.yaml::context' --tb=short -s
pytest 'tests/modules/project/tftest.yaml::context' --tb=short -s
```

#### 3. Contributing

*   **Branching:** Use `username/feature-name`.
*   **Commits:** Atomic commits with clear messages.
*   **PR Titles:** Avoid semantic commit prefixes. Use Title Case for the first word.
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

**5. YAML Interpolation:** In factory YAML files, use the `$` prefix convention to reference the lookup map keys (e.g., `parent: $folder_ids:teams/team-a`).

### Tests

Add a `context` test alongside existing module tests:

- `tests/modules/<module_name>/tftest.yaml` — declare the module path and list `context:` under `tests:`
- `tests/modules/<module_name>/context.tfvars` — provide all required module variables using symbolic references; include a `context` block with maps that resolve them
- `tests/modules/<module_name>/context.yaml` — assert resolved (concrete) values in the plan output

### README example

Modify one existing README example (do not add a new one) to demonstrate context usage. The resolved values should match the existing inventory YAML so no inventory changes are needed.

## Architecture & Conventions

*   **Variables & Interfaces:**
    *   Prefer object variables (e.g., `iam = { ... }`) over many individual scalar variables.
    *   Design compact variable spaces by leveraging Terraform's `optional()` function with defaults extensively.
    *   Use maps instead of lists for multiple items to ensure stable keys in state and avoid `for_each` dynamic value issues.
*   **Naming:** Never use random strings for resource naming. Rely on an optional `prefix` variable implemented consistently across modules.
*   **IAM:** Implemented within resources (authoritative `_binding` or additive `_member`) via standard interfaces.
*   **Outputs:** Explicitly depend on internal resources to ensure proper ordering (`depends_on`).
*   **File Structure:**
    *   Move away from `main.tf`, `variables.tf`, `outputs.tf`.
    *   Use descriptive filenames: `iam.tf`, `gcs.tf`, `mounts.tf`.
*   **Style & Formatting:**
    *   **Line Length:** Enforce a 79-character line length limit for legibility (relaxed for long resource attributes and descriptions).
    *   **Ternary Operators & Functions:** Wrap complex ternary operators in parentheses and break lines to align `?` and `:`. Split function calls with many arguments across multiple lines.
    *   **Locals Separation:** Use module-level locals for values referenced directly by resources/outputs. Use block-level "private" locals prefixed with an underscore (`_`) for intermediate transformations.
    *   **Complex Transformations:** Move complex data transformations in `for` or `for_each` loops to `locals` to keep resource blocks clean.

## Debugging Terraform Context & Locals

When troubleshooting how variables, context, or locals are being evaluated during a `plan` (especially within factories or FAST stages), do not rely solely on `pytest` failure outputs or `grep`.

**ALWAYS** use a fast-failing `terraform_data` precondition to dump the exact runtime state of the data structure. Inject this snippet temporarily into the module being debugged:

```hcl
resource "terraform_data" "debug_dump" {
  lifecycle {
    precondition {
      # The condition is intentionally designed to fail to trigger the error_message
      condition     = local.target_variable == null
      error_message = yamlencode(local.target_variable)
    }
  }
}
```

Run the specific `pytest` plan test. The test will fail, and the captured output will contain the fully evaluated YAML representation of your target variable, making context resolution issues immediately obvious.

## File Modification Rules
- **CRITICAL:** NEVER use shell redirection (`cat << EOF`, `echo "..." >`, `>>`, `tee`) to create, overwrite, or append to files.
- For creating files, ALWAYS use the native `write_file` tool.
- For targeted edits or appending to a single file, ALWAYS use the native `replace` tool. (To append, match the last few lines of the file and replace them with the same lines plus your new content).
- **EXCEPTION (Pattern/Bulk Edits):** You MAY use shell commands (like `sed -i`, `perl -pi`, or `find ... xargs sed`) ONLY for regex-based or pattern-based replacements, particularly across multiple files, where the exact-match `replace` tool is not feasible.
- **Ambiguity & Paths:** When encountering unfamiliar or unexpected repository structures, paths, or tool executions, always pause and offer the user the choice to either explain or authorize further independent investigation, rather than making assumptions or guessing paths.
- **CRITICAL (LINTING & FORMATTING):** You MUST ALWAYS run all formatting and linting checks (`terraform fmt`, `check_documentation.py`, `yamllint`, `check_boilerplate.py` as described in [Formatting & Linting](#1-formatting--linting)) on all modified or new files BEFORE staging, committing, or pushing changes.

To run specific FAST stage tests, use the syntax `pytest tests/fast/stages/s<stage_num>_<stage_name>/tftest.yaml::<test_name>`. For example: `pytest tests/fast/stages/s0_org_setup/tftest.yaml::starter-gcd`.
