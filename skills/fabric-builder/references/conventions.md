# Cloud Foundation Fabric (CFF) Conventions

When generating Terraform code for CFF, you MUST adhere to the following conventions:

## 1. Module Usage
- Always prefer CFF modules over raw `google_*` resources.
- **Boundary:** Unrelated resources (like a dataset for a project) should never be part of the same module, except in the two "aggregation modules" (`project-factory` and `net-vpc-factory`). Never break this boundary as a first approach.
- Use explicit `prefix` variables. Do NOT use random suffixes for resource naming.
- Rely on data-driven "factory" patterns where applicable, using YAML data files.

## 2. Context Variables
- Several modules support symbolic variable interpolation via a `context` variable. This allows callers to pass symbolic references like `"$project_ids:myprj"` instead of raw values, which get resolved at plan time.
- Standard keys include `locations`, `networks`, `project_ids`, `subnets`.

## 3. Style & Formatting
- **Line Length:** Enforce a 79-character line length limit for legibility (relaxed for long resource attributes and descriptions).
- **Ternary Operators & Functions:** Wrap complex ternary operators in parentheses and break lines to align `?` and `:`. Split function calls with many arguments across multiple lines.
- **Locals Separation:** Use module-level locals for values referenced directly by resources/outputs. Use block-level "private" locals prefixed with an underscore (`_`) for intermediate transformations.
- **Variables & Interfaces:** Prefer object variables (e.g., `iam = { ... }`) over many individual scalar variables. Use maps instead of lists for multiple items to ensure stable keys in state.

## 4. Variables & Defaults
- If there are any values that can potentially become variables, **ask the user to provide default values**.
- Put these values as `default` attributes directly in the variable definition block in `variables.tf`.
- **Do not** create a `terraform.tfvars` file for defaults.


