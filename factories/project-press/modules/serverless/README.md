# Serverless group management

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| all_groups | All groups in CI | <code title="">any</code> | ✓ |  |
| customer_id | Cloud Identity customer ID | <code title="">string</code> | ✓ |  |
| domain | Domain to use | <code title="">string</code> | ✓ |  |
| environments | List of environments | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| project_id | Project ID | <code title="">string</code> | ✓ |  |
| project_ids_full | Project IDs | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| project_numbers | Project numbers | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| sa_groups | Map of Service Account groups env per group | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| serverless_groups | Map of serverless groups per environment | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| serverless_service_accounts | List of serverless service accounts (Cloud Functions, Cloud Run) | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| *only_add_project* | If this is set, don't make groups | <code title="">bool</code> |  | <code title="">false</code> |

## Outputs

<!-- END TFDOC -->
