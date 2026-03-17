---
trigger: always_on
---

# Always make sure edited code passes linting checks

- run `tools/tfdoc.py` if variable or output definitions changed
- run `terraform fmt` on any edited Terraform file, and hcl examples in README files
- a schema change should be reflected in all the other places that use the same schema, those are documented in `tools/duplicate-diff.py`
- always make sure both example and module (or stage) level tests run for all the modules/stages where code was edited