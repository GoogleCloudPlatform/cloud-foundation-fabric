---
trigger: always_on
---

# Always make sure edited code passes linting checks

- run `tools/tfdoc.py` if variable or output definitions changed
- run `terraform fmt` on any edited Terraform file, and hcl examples in README files
