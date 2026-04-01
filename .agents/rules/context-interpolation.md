---
trigger: always_on
---

# Context-Based Interpolation 

When designing factory patterns or datasets, you MUST leverage the **context-based interpolation** system.

A `context` object variable is used to hold maps of known, existing resource IDs (such as `project_ids`, `folder_ids`, `networks`, `iam_principals`).

## Usage Pattern

1. **Variables:** Add a `context` variable in `variables.tf`.
   ```hcl
   variable "context" {
     description = "Context-specific interpolations."
     type = object({
       project_ids = optional(map(string), {})
       folder_ids  = optional(map(string), {})
     })
     default = {}
   }
   ```

2. **Locals:** Build `ctx` and `ctx_p` local variables in `main.tf` by flattening the `var.context` object.
   ```hcl
   locals {
     ctx = {
       for k, v in var.context : k => {
         for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
       }
     }
     ctx_p = "$"
   }
   ```

3. **Lookups:** Apply lookups inside resources.
   ```hcl
   project = lookup(local.ctx.project_ids, var.project_id, var.project_id)
   ```

4. **YAML Interpolation:** In factory YAML files, use the `$` prefix convention to reference the lookup map keys.
   ```yaml
   # Instead of hardcoding the folder ID: parent: folders/1234567890
   parent: $folder_ids:teams/team-a
   ```

This pattern makes YAML configuration files highly portable across installations and environments by substituting mnemonic keys for hardcoded values.