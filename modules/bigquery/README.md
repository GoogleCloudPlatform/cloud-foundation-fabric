# Google Cloud Bigquery Module

Simple Bigquery module offering support for multiple dataset creation and access configuration.

The module interface is designed to allow setting default values for dataset access configurations and options (eg table or partition expiration), and optionally override them for individual datasets. Common labels applied to all datasets can also be specified with a single variable, and overridden individually.

Access configuration supports specifying different [identity types](https://www.terraform.io/docs/providers/google/r/bigquery_dataset.html#access) via the `identity_type` attribute in access variables. The supported identity types are: `domain`, `group_by_email`, `special_group` (eg `projectOwners`), `user_by_email`.

## Example

```hcl
module "bigquery-datasets" {
  source     = "./modules/bigquery"
  project_id = "my-project
  datasets = {
    dataset_1 = {
      name        = "Dataset 1."
      description = "Terraform managed."
      location    = "EU"
      labels      = null
    },
    dataset_2 = {
      name        = "Dataset 2."
      description = "Terraform managed."
      location    = "EU"
      labels      = null
    },
  }
  default_access = [
    {
      role = "OWNER"
      identity_type = "special_group"
      identity = "projectOwners"
    }
  ]
  default_labels = {
    eggs = "spam",
    bar = "baz
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| datasets | Map of datasets to create keyed by id. Labels and options can be null. | <code title="map&#40;object&#40;&#123;&#10;description &#61; string&#10;location    &#61; string&#10;name        &#61; string&#10;labels      &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> | ✓ |  |
| project_id | Id of the project where datasets will be created. | <code title="">string</code> | ✓ |  |
| *dataset_access* | Optional map of dataset access rules by dataset id. | <code title="map&#40;list&#40;object&#40;&#123;&#10;role          &#61; string&#10;identity_type &#61; string&#10;identity      &#61; any&#10;&#125;&#41;&#41;&#41;">map(list(object({...})))</code> |  | <code title="">{}</code> |
| *dataset_options* | Optional map of dataset option by dataset id. | <code title="map&#40;object&#40;&#123;&#10;default_table_expiration_ms     &#61; number&#10;default_partition_expiration_ms &#61; number&#10;delete_contents_on_destroy      &#61; bool&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *default_access* | Access rules applied to all dataset if no specific ones are defined. | <code title="list&#40;object&#40;&#123;&#10;role          &#61; string&#10;identity_type &#61; string&#10;identity      &#61; any&#10;&#125;&#41;&#41;">list(object({...}))</code> |  | <code title="">[]</code> |
| *default_labels* | Labels set on all datasets. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *default_options* | Options used for all dataset if no specific ones are defined. | <code title="object&#40;&#123;&#10;default_table_expiration_ms     &#61; number&#10;default_partition_expiration_ms &#61; number&#10;delete_contents_on_destroy      &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;default_table_expiration_ms     &#61; null&#10;default_partition_expiration_ms &#61; null&#10;delete_contents_on_destroy      &#61; false&#10;&#125;">...</code> |
| *kms_key* | Self link of the KMS key that will be used to protect destination table. | <code title="">string</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| datasets | Dataset resources. |  |
| ids | Dataset ids. |  |
| names | Dataset names. |  |
| self_links | Dataset self links. |  |
<!-- END TFDOC -->

## TODO

- [ ] add support for tables
