# Google Cloud Bigquery Module

TODO(ludoo): add support for tables

## Example

```iam
module "bigquery-datasets" {
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| datasets | Map of datasets to create keyed by id. Labels and options can be null. | <code title="map&#40;object&#40;&#123;&#10;description &#61; string&#10;labels      &#61; map&#40;string&#41;&#10;location    &#61; string&#10;name        &#61; string&#10;options &#61; object&#40;&#123;&#10;default_table_expiration_ms     &#61; number&#10;default_partition_expiration_ms &#61; number&#10;delete_contents_on_destroy      &#61; bool&#10;&#125;&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> | ✓ |  |
| project_id | Id of the project where datasets will be created. | <code title="">string</code> | ✓ |  |
| *default_access* | Access rules applied to all dataset if no specific ones are defined. | <code title="list&#40;object&#40;&#123;&#10;role          &#61; string&#10;identity_type &#61; string&#10;identity      &#61; any&#10;&#125;&#41;&#41;">list(object({...}))</code> |  | <code title="">[]</code> |
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
