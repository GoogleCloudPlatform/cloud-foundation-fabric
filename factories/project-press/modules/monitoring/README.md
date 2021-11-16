# Cloud Ops Monitoring management

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| all_groups | All groups in CI | <code title="">any</code> | ✓ |  |
| customer_id | Cloud Identity customer ID | <code title="">string</code> | ✓ |  |
| domain | Domain to use | <code title="">string</code> | ✓ |  |
| environments | List of environments | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| monitoring_groups | Map of monitoring groups per environment | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| monitoring_projects | Map of monitoring host projects per environment | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| project_groups | Map of project groups env per group | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| project_ids_full | Project IDs | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| quota_project | Quota project for Stackdriver Accounts API | <code title="">string</code> | ✓ |  |
| *only_add_project* | If this is set, don't make groups | <code title="">bool</code> |  | <code title="">false</code> |

## Outputs

<!-- END TFDOC -->
