# Google Cloud Bigquery Module

This module allows managing a single BigQuery dataset, including access configuration, tables and views.

## Examples

### Simple dataset with access configuration

Access configuration defaults to using incremental accesses, which add to the default ones set at dataset creation. You can use the `access_authoritative` variable to switch to authoritative mode and have full control over dataset-level access. Be sure to always have at least one `OWNER` access and to avoid duplicating accesses, or `terraform apply` will fail.

```hcl
module "bigquery-dataset" {
  source     = "./modules/bigquery-dataset"
  project_id = "my-project
  id         = "my-dataset"
  access = [
    {
      role          = "OWNER"
      identity_type = "group_by_email"
      identity      = "dataset-owners@example.com"
    }
  ]
}
```

### Dataset options

Dataset options are set via the `options` variable. all options must be specified, but a `null` value can be set to options that need to use defaults.

```hcl
module "bigquery-dataset" {
  source     = "./modules/bigquery-dataset"
  project_id = "my-project
  id         = "my-dataset"
  options = {
    default_table_expiration_ms     = 3600000
    default_partition_expiration_ms = null
    delete_contents_on_destroy      = false
  }
}
```

### Tables and views

Tables are created via the `tables` variable, or the `view` variable for views. Support for external tables will be added in a future release.

```hcl
module "bigquery-dataset" {
  source     = "./modules/bigquery-dataset"
  project_id = "my-project
  id         = "my-dataset"
  tables = {
    table_a = {
      friendly_name = "Table a"
      labels        = {}
      options       = null
      partitioning  = null
      schema = file("table-a.json")
    }
  }
}
```

If partitioning is needed, populate the `partitioning` variable using either the `time` or `range` attribute.

```hcl
module "bigquery-dataset" {
  source     = "./modules/bigquery-dataset"
  project_id = "my-project
  id         = "my-dataset"
  tables = {
    table_a = {
      friendly_name = "Table a"
      labels        = {}
      options       = null
      partitioning = {
        field = null
        range = null # use start/end/interval for range
        time  = { type = "DAY", expiration_ms = null }
      }
      schema = file("table-a.json")
    }
  }
}
```

To create views use the `view` variable. If you're querying a table created by the same module `terraform apply` will initially fail and eventually succeed once the underlying table has been created. You can probably also use the module's output in the view's query to create a dependency on the table.

```hcl
module "bigquery-dataset" {
  source     = "./modules/bigquery-dataset"
  project_id = "my-project
  id         = "my-dataset"
  tables = {
    table_a = {
      friendly_name = "Table a"
      labels        = {}
      options       = null
      partitioning = {
        field = null
        range = null # use start/end/interval for range
        time  = { type = "DAY", expiration_ms = null }
      }
      schema = file("table-a.json")
    }
  }
  views = {
    view_a = {
      friendly_name  = "View a"
      labels         = {}
      query          = "SELECT * from `my-project.my-dataset.table_a`"
      use_legacy_sql = false
    }
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| id | Dataset id. | <code title="">string</code> | ✓ |  |
| project_id | Id of the project where datasets will be created. | <code title="">string</code> | ✓ |  |
| *access* | Dataset access rules keyed by role, valid identity types are `domain`, `group_by_email`, `special_group` and `user_by_email`. Mode can be controlled via the `access_authoritative` variable. | <code title="map&#40;object&#40;&#123;&#10;identity_type &#61; string&#10;identity      &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *access_authoritative* | Use authoritative access instead of additive. | <code title="">bool</code> |  | <code title="">false</code> |
| *access_views* | Dataset access rules for views. Mode can be controlled via the `access_authoritative` variable. | <code title="list&#40;object&#40;&#123;&#10;project_id &#61; string&#10;dataset_id &#61; string&#10;table_id   &#61; string&#10;&#125;&#41;&#41;">list(object({...}))</code> |  | <code title="">[]</code> |
| *encryption_key* | Self link of the KMS key that will be used to protect destination table. | <code title="">string</code> |  | <code title="">null</code> |
| *friendly_name* | Dataset friendly name. | <code title="">string</code> |  | <code title="">null</code> |
| *labels* | Dataset labels. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *location* | Dataset location. | <code title="">string</code> |  | <code title="">EU</code> |
| *options* | Dataset options. | <code title="object&#40;&#123;&#10;default_table_expiration_ms     &#61; number&#10;default_partition_expiration_ms &#61; number&#10;delete_contents_on_destroy      &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;default_table_expiration_ms     &#61; null&#10;default_partition_expiration_ms &#61; null&#10;delete_contents_on_destroy      &#61; false&#10;&#125;">...</code> |
| *tables* | Table definitions. Not needed attributes can be set to null. | <code title="map&#40;object&#40;&#123;&#10;clustering      &#61; list&#40;string&#41;&#10;encryption_key  &#61; string&#10;expiration_time &#61; number&#10;friendly_name   &#61; string&#10;labels          &#61; map&#40;string&#41;&#10;range_partitioning &#61; object&#40;&#123;&#10;end      &#61; number&#10;interval &#61; number&#10;start    &#61; number&#10;&#125;&#41;&#10;time_partitioning &#61; object&#40;&#123;&#10;expiration_ms &#61; number&#10;field         &#61; string&#10;type &#61; string&#10;&#125;&#41;&#10;schema &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *views* | View definitions. | <code title="map&#40;object&#40;&#123;&#10;friendly_name  &#61; string&#10;labels         &#61; map&#40;string&#41;&#10;query          &#61; string&#10;use_legacy_sql &#61; bool&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| dataset | Dataset resource. |  |
| id | Dataset id. |  |
| self_link | Dataset self link. |  |
| tables | Table resources. |  |
| views | View resources. |  |
<!-- END TFDOC -->

## TODO

- [ ] add support for tables
