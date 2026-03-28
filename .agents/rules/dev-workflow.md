---
trigger: always_on
---

# Always make sure edited code passes linting checks

- run `tools/tfdoc.py` if variable or output definitions changed
- run `tools/check_documentation.py` to ensure variables are sorted alphabetically and READMEs are consistent
- run `tools/check_boilerplate.py` to ensure license headers are present
- run `terraform fmt` on any edited Terraform file, and hcl examples in README files
- run `yamllint -c .yamllint --no-warnings <yaml-files>` on any edited YAML files
- a schema change should be reflected in all the other places that use the same schema, those are documented in `tools/duplicate-diff.py`
- always make sure both example and module (or stage) level tests run for all the modules/stages where code was edited