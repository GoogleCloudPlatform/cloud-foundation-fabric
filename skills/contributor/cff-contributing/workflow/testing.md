# Testing, Inventories, and Debugging

Fabric tests primarily at plan time using `pytest` and `tftest` to ensure configurations plan cleanly and do not regress when modules or providers change.

## Choosing the Right Test Format

- **README `# tftest` examples (preferred for modules):** Every HCL fenced block in `README.md` is automatically tested unless marked `# tftest skip`. Update an existing example or add a new one whenever you introduce or change module behavior.
- **`tftest.yaml` suites (`tests/modules/<module_name>/` or `tests/fast/...`):** Use for FAST stages (which rarely have README examples), `context` interpolation tests, and complex IAM or factory variants.
- **Python tests (`test_*.py`):** Legacy approach; use only when custom Python assertions are genuinely required.

> **Directory naming gotcha:** Module directories use hyphens (`modules/net-vpn-ha`), while test directories generally use underscores (`tests/modules/net_vpn_ha`). Verify the exact directory name before running `pytest` — a mistyped path silently collects zero tests.

## README `# tftest` Examples

Append a `# tftest` directive as the last line of the HCL block. Preset fixture variables (`var.project_id`, `var.vpc`, `var.subnet`, etc.) are declared in [tests/examples/variables.tf](../../../../tests/examples/variables.tf). For factory examples, declare external YAML fixtures with `# tftest-file` and reference their IDs via `files=`:

```hcl
module "private-dns" {
  source          = "./modules/dns"
  project_id      = "myproject"
  type            = "private"
  name            = "test-example"
  domain          = "test.example."
  client_networks = [var.vpc.self_link]
  recordsets      = yamldecode(file("records/example.yaml"))
}
# tftest modules=1 resources=3 files=records inventory=recordsets.yaml
```

```yaml
# tftest-file id=records path=records/example.yaml
A localhost:
  ttl: 300
  records: ["127.0.0.1"]
```

Inventories for README examples live at `tests/modules/<module_name>/examples/<inventory>.yaml` and support three optional sections: `values` (resource address → attributes to assert), `counts` (resource type → count), and `outputs` (output name → value, using `__missing__` for values unknown at plan time). Keep inventory assertions focused on the behavior under test.

## `tftest.yaml` Suites and `context` Tests

Declare `tfvars` and inventory pairs in `tests/modules/<module_name>/tftest.yaml`:

```yaml
module: modules/net-lb-app-ext
common_tfvars:
  - defaults.tfvars
tests:
  context:
  custom-case:
    tfvars:
      - custom-case-extra.tfvars
    inventory:
      - custom-case.yaml
```

**When adding `context` support to a module:**

1. Add a `context:` test to `tests/modules/<module_name>/tftest.yaml` with `context.tfvars` (passing symbolic `"$key:name"` references plus a `context` map) and `context.yaml` (asserting the concrete resolved values).
2. Update one existing `README.md` example to demonstrate `context` resolving to the exact same values so existing inventories stay unchanged (do not add a redundant example solely for `context`).

## Running `pytest`

```bash
# Module tftest.yaml suite (or a single test case)
pytest tests/modules/<module_name>
pytest 'tests/modules/<module_name>/tftest.yaml::<test_name>' --tb=short -s

# README example tests (trailing ':' avoids matching prefix siblings like net-vpc-firewall)
pytest -k 'modules and <module-name>:' tests/examples
pytest -k 'modules and <module-name>:' tests/examples --collect-only

# Parallel runs or FAST stage tests (copy to temp dir so local *.tfvars do not interfere)
TFTEST_COPY=1 pytest -n auto tests/fast/stages/s0_org_setup
```

- **Provider caching:** Setting `TF_PLUGIN_CACHE_DIR=/tmp/tfcache` speeds up tests on direct downloads, **unless** the host already uses a local provider filesystem mirror in `~/.terraformrc` (overriding a mirror with `TF_PLUGIN_CACHE_DIR` triggers lockfile checksum mismatches). Do not override a working local Terraform config.
- **OpenTofu parity and exclusions:** CI runs tests under both Terraform and OpenTofu (`TERRAFORM=tofu`). Only exclude a test from OpenTofu when a specific Terraform or provider feature lacks OpenTofu compatibility (for example, as was historically needed for write-only secret attributes prior to OpenTofu 1.11):
  - **README `# tftest` examples:** Append `skip-tofu` to the directive (`# tftest modules=1 resources=2 skip-tofu`).
  - **`tftest.yaml` test specs:** Add `skip_tofu: true` under the individual test entry.

## Generating and Auditing Test Inventories

Do not hand-code inventory YAMLs from scratch. Generate or update them with `tools/generate_plan_summary.py`:

```bash
# For tftest.yaml scenarios
uv run tools/generate_plan_summary.py tests/modules/<module_name>/tftest.yaml <test-name> --save

# For README.md examples
uv run tools/generate_plan_summary.py modules/<module-name>/README.md "<Example Heading>" --save
```

> **Mandatory inventory audit:** `--save` overwrites the assertion baseline, making the test pass by construction. Always run `git diff tests/` afterwards, confirm that **every** changed line maps directly to your intended feature or fix, and summarize the inventory diff for the reviewer. Treat any unexplained line change as a bug in your HCL, not a baseline to accept.

## Debugging Context and Locals

When troubleshooting how variables, `context`, or factory locals evaluate during a `plan`, do not guess from `pytest` failures. Inject a temporary fast-failing `terraform_data` precondition into the module and run the single `pytest` target:

```hcl
resource "terraform_data" "debug_dump" {
  lifecycle {
    precondition {
      condition     = local.target_variable == null
      error_message = yamlencode(local.target_variable)
    }
  }
}
```

The failed plan prints the exact evaluated YAML structure of `local.target_variable`. Remove the resource before committing.
