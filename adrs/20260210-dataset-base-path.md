# Adopt a base path for datasets

**authors:** [Julio](https://github.com/juliocc) [Ludo](https://github.com/ludoo)
**date:** Feb 10, 2026

## Status

Draft

## Context

This ADR provides a potential solution to two concurrent issues.

FAST stages still use the old per-factory path approach, which makes it harder to switch datasets.

```hcl
variable "factories_config" {
  description = "Configuration for the resource factories or external data."
  type = object({
    billing_accounts  = optional(string, "datasets/classic/billing-accounts")
    cicd_workflows    = optional(string)
    defaults          = optional(string, "datasets/classic/defaults.yaml")
    folders           = optional(string, "datasets/classic/folders")
    observability     = optional(string, "datasets/classic/observability")
    organization      = optional(string, "datasets/classic/organization")
    project_templates = optional(string, "datasets/classic/templates")
    projects          = optional(string, "datasets/classic/projects")
  })
  nullable = false
  default  = {}
}
```

Project-level factories in the project factory module use relative paths based on the root module in scope, forcing users to embed paths in the YAML files.

```yaml
factories_config:
  observability: datasets/classic/observability/iac-0
```

## Proposed Approach

The proposed approach changes the `factories_config` variable in FAST stages so that a new `dataset` attribute is added, and existing lower-level paths are moved to a `paths` attribute.

```hcl
variable "factories_config" {
  description = "Configuration for the resource factories or external data."
  type = object({
    dataset = optional(string, "datasets/classic")
    paths   = optional(object({
      billing_accounts  = optional(string, "billing-accounts")
      cicd_workflows    = optional(string)
      defaults          = optional(string, "defaults.yaml")
      folders           = optional(string, "folders")
      observability     = optional(string, "observability")
      organization      = optional(string, "organization")
      project_templates = optional(string, "templates")
      projects          = optional(string, "projects")
    }), {})
  })
  nullable = false
  default  = {}
}
```

This allows one-line configuration of the dataset, while still providing a way to cancel out individual factories by omitting the path, or pointing to a non-existing folder. The base path will not be prepended for paths starting with `/` or `.`, to allow for different absolute or relative paths, and to also allow our testing framweork to inject fixtures.

On the project factory side, the `factories_config` variable will also change by adopting a "base path" and grouping existing attributes under a `paths` variable.

```hcl
variable "factories_config" {
  description = "Path to folder with YAML resource description data files."
  type = object({
    base_path = "data"
    paths = optional(object({
      folders           = optional(string)
      project_templates = optional(string)
      projects          = optional(string)
      budgets = optional(object({
        billing_account_id = string
        data               = string
      }))
    }), {})
  })
  nullable = false
}
```

The lower level modules will not change interface, but the base path will be prepended by the project factory to in-project `factories_config` paths, to allow decoupling from the dataset and creating portable files.

```yaml
factories_config:
  observability: observability/iac-0
```
