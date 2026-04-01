---
trigger: always_on
---

# Strictly Adhere to the Fabric Style Guide

When modifying or generating Terraform code, you MUST follow these specific style conventions:

- **Line Length:** Enforce a 79-character line length limit for legibility. This rule is relaxed *only* for long resource attribute names and descriptions.
- **Ternary Operators:** Wrap complex ternary operators in parentheses and break lines to align the `?` and `:` tokens clearly. Example:
  ```hcl
  locals {
    parent_id = (
      var.parent == null || startswith(coalesce(var.parent, "-"), "$")
      ? var.parent
      : split("/", var.parent)[1]
    )
  }
  ```
- **Function Calls:** Split function calls with many arguments across multiple lines, typically breaking after the opening parenthesis and before the closing one.
- **Alphabetical Ordering:** You MUST ensure variables and outputs are strictly sorted alphabetically. Run `tools/check_documentation.py` to verify this. 
- **Locals Separation:**
  - Use module-level locals for values referenced directly by resources or outputs (e.g., `svpc_host_config`).
  - Use block-level "private" locals prefixed with an underscore (`_`) for intermediate transformations only referenced within the same block (e.g., `_svpc_service_iam`).
- **Complex Transformations:** Move complex data transformations in `for` or `for_each` loops to `locals` to keep resource blocks clean.
- **Variable Spaces:** Leverage `optional()` defaults extensively within object variables to reduce verbosity.
- **Naming:** NEVER use random strings for resource naming. Instead, implement and use an optional `prefix` variable in all modules.
