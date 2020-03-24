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
| destinations | Map of destinations by sink name. | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| parent | Resource where the sink will be created, eg 'organizations/nnnnnnnn'. | <code title="">string</code> | ✓ |  |
| sinks | Map of sink name / sink filter. | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| *default_options* | Default options used for sinks where no specific options are set. | <code title="object&#40;&#123;&#10;bigquery_partitioned_tables &#61; bool&#10;include_children            &#61; bool&#10;unique_writer_identity      &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;bigquery_partitioned_tables &#61; true&#10;include_children            &#61; true&#10;unique_writer_identity      &#61; false&#10;&#125;">...</code> |
| *sink_options* | Optional map of sink name / sink options. If no options are specified for a sink defaults will be used. | <code title="map&#40;object&#40;&#123;&#10;bigquery_partitioned_tables &#61; bool&#10;include_children            &#61; bool&#10;unique_writer_identity      &#61; bool&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| names | Log sink names. |  |
| sinks | Log sink resources. |  |
| writer_identities | Log sink writer identities. |  |
<!-- END TFDOC -->

