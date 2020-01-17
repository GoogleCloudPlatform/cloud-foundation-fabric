# Terraform Logging Sinks Module

This module allows easy creation of one or more logging sinks.

## Example

```hcl
module "sinks" {
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| *sinks* | Logging sinks that will be created, options default to true except for unique_writer_identity. | <code title="list&#40;object&#40;&#123;&#10;name        &#61; string&#10;resource    &#61; string&#10;filter      &#61; string&#10;destination &#61; string&#10;options &#61; object&#40;&#123;&#10;bigquery_partitioned_tables &#61; bool&#10;include_children            &#61; bool&#10;unique_writer_identity      &#61; bool&#10;&#125;&#41;&#10;&#125;&#41;&#41;">list(object({...}))</code> |  | <code title="">[]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| names | Log sink names. |  |
| sinks | Log sink resources. |  |
| writer_identities | Log sink writer identities. |  |
<!-- END TFDOC -->

