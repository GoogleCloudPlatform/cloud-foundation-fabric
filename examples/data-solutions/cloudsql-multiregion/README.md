# Cloud SQL instance with multi-region read replicas

TBD
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [prefix](variables.tf#L23) | Unique prefix used for resource names. Not used for project if 'project_create' is null. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L37) | Project id, references existing project if `project_create` is null. | <code>string</code> | ✓ |  |
| [regions](variables.tf#L42) | Map of instance_name => location where instances will be deployed. | <code>map&#40;string&#41;</code> | ✓ |  |
| [cloudsql_psa_range](variables.tf#L17) | Range used for the Private Service Access. | <code>string</code> |  | <code>&#34;10.60.0.0&#47;16&#34;</code> |
| [project_create](variables.tf#L28) | Provide values if project creation is needed, uses existing project if null. Parent is in 'folders/nnn' or 'organizations/nnn' format. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  parent             &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [tier](variables.tf#L51) | The machine type to use for the instances. See See https://cloud.google.com/sql/docs/postgres/create-instance#machine-types. | <code>string</code> |  | <code>&#34;db-g1-small&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [connection_names](outputs.tf#L17) | Connection name of each instance. |  |
| [ips](outputs.tf#L22) | IP address of each instance. |  |
| [project_id](outputs.tf#L27) | ID of the project containing all the instances. |  |

<!-- END TFDOC -->
