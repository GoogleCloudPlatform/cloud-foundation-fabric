---
trigger: always_on
---

# Use Example-Based Testing in README.md

When testing modules, you MUST prefer example-based testing over writing legacy Python `pytest` functions. 

Example-based tests are triggered from HCL Markdown fenced code blocks inside a module's `README.md` file using a special `# tftest` comment at the bottom.

## How to structure a test
1. Write a clear HCL code block demonstrating the functionality.
2. Add the `tftest` directive, declaring expected counts.
3. If validating values, point to a YAML inventory file.

```hcl
module "my-module" {
  source = "./modules/my-module"
  name   = "test-example"
}
# tftest modules=1 resources=2 inventory=my-inventory.yaml
```

## Inventory Files
Inventory files are YAML datasets used to assert that the generated plan matches expectations.
- Place them in the `tests/modules/<module_name>/examples/` directory.
- You can generate an inventory automatically by running a successful plan using `pytest -s` (refer to `CONTRIBUTING.md` for the exact command format). 
- **DO NOT hand-code inventory files from scratch.** Extract only the necessary bits relevant to the test scenario from the generated output.

## tftest-based tests (Advanced)
If a module lacks an example in its `README.md` or you are testing a FAST stage without examples, use `tftest`-based tests using `tfvars` and `yaml` files. Refer to the "Testing via `tfvars` and `yaml`" section in `CONTRIBUTING.md`.