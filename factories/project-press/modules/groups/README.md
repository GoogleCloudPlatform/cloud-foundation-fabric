# Cloud Identity Group management

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| additional_iam_roles | Additional IAM roles for groups | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> | ✓ |  |
| additional_roles | Additional sets of IAM roles for groups | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> | ✓ |  |
| additional_roles_config | Additional IAM roles config | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| all_groups | All groups in CI | <code title="">any</code> | ✓ |  |
| customer_id | Cloud Identity customer ID | <code title="">string</code> | ✓ |  |
| domain | Domain to use | <code title="">string</code> | ✓ |  |
| environments | Environments | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| folder | Folder | <code title="">string</code> | ✓ |  |
| groups | Groups to provision | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> | ✓ |  |
| groups_permissions | Group permissions | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| main_group | Group that will contain all groups | <code title="">string</code> | ✓ |  |
| owner | Owner | <code title="">string</code> | ✓ |  |
| owner_group | Group that will contain the owner | <code title="">string</code> | ✓ |  |
| owners | Owners | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| project_id | Project ID | <code title="">string</code> | ✓ |  |
| project_ids_full | Project IDs (full) | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| service_accounts | Service accounts | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| shared_vpc_groups | Shared VPC groups (one for each environment) | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| *group_format* | Project naming format | <code title="">string</code> |  | <code title="">%project%-%group%-%env%</code> |
| *only_add_permissions* | Don't create groups, just add permissions (groups have to exist) | <code title="">bool</code> |  | <code title="">false</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| project_group_ids | Project group IDs |  |
| project_group_keys | Project group keys |  |
<!-- END TFDOC -->
