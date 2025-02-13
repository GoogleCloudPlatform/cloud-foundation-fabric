# Projects Data Source Module 

This module extends functionality of [google_projects](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/projects) data source by retrieving all the projects under a specific `parent` recursively with only one API call against [Cloud Asset Inventory](https://cloud.google.com/asset-inventory) service. 

A good usage pattern would be when we want all the projects under a specific folder (including nested subfolders) to be included into [VPC Service Controls](../vpc-sc/). Instead of manually maintaining the list of project numbers as an input to the `vpc-sc` module we can use that module to retrieve all the project numbers dynamically.

### IAM Permissions required

- `roles/cloudasset.viewer` on the `parent` level or above


## Examples

### All projects in my org

```hcl
module "my-org" {
  source = "./fabric/modules/projects-data-source"
  parent = var.organization_id
}

output "project_numbers" {
  value = module.my-org.project_numbers
}

# tftest skip (uses data sources) e2e
```

### My dev projects based on parent and label

```hcl
module "my-dev" {
  source = "./fabric/modules/projects-data-source"
  parent = var.folder_id
  query  = "labels.env:DEV state:ACTIVE"
}

output "dev-projects" {
  value = module.my-dev.projects
}

# tftest skip (uses data sources) e2e
```

### Projects under org with folder/project exclusions
```hcl
module "my-filtered" {
  source = "./fabric/modules/projects-data-source"
  parent = var.organization_id
  ignore_projects = [
    "sandbox-*",       # wildcard ignore
    "project-full-id", # specific project id
    "0123456789"       # specific project number
  ]

  include_projects = [
    "sandbox-114", # include specific project which was excluded by wildcard
    "415216609246" # include specific project which was excluded by wildcard (by project number)
  ]

  ignore_folders = [ # subfolders are ingoner as well
    "343991594985",
    "437102807785",
    "345245235245"
  ]
  query = "state:ACTIVE"
}

output "filtered-projects" {
  value = module.my-filtered.projects
}

# tftest skip (uses data sources) e2e
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [parent](variables.tf#L55) | Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format. | <code>string</code> | ✓ |  |
| [ignore_folders](variables.tf#L17) | A list of folder IDs or numbers to be excluded from the output, all the subfolders and projects are excluded from the output regardless of the include_projects variable. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [ignore_projects](variables.tf#L28) | A list of project IDs, numbers or prefixes to exclude matching projects from the module output. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [include_projects](variables.tf#L41) | A list of project IDs/numbers to include to the output if some of them are excluded by `ignore_projects` wildcard entries. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [query](variables.tf#L64) | A string query as defined in the [Query Syntax](https://cloud.google.com/asset-inventory/docs/query-syntax). | <code>string</code> |  | <code>&#34;state:ACTIVE&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [project_numbers](outputs.tf#L17) | List of project numbers. |  |
| [projects](outputs.tf#L22) | List of projects in [StandardResourceMetadata](https://cloud.google.com/asset-inventory/docs/reference/rest/v1p1beta1/resources/searchAll#StandardResourceMetadata) format. |  |

<!-- END TFDOC -->
