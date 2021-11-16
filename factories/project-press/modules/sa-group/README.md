# Service Account group management

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| activated_apis | Activated APIs | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| all_groups | All groups in CI | <code title="">any</code> | ✓ |  |
| api_service_accounts | API service accounts | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| customer_id | Cloud Identity customer ID | <code title="">string</code> | ✓ |  |
| domain | Domain to use | <code title="">string</code> | ✓ |  |
| environments | Environments | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| project_id | Project ID | <code title="">string</code> | ✓ |  |
| project_ids_full | Project IDs (full) | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| project_numbers | Project numbers | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| service_account | Terraform provisioner service account | <code title="">string</code> | ✓ |  |
| service_accounts | Service accounts to add to project SA group | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| shared_vpc_groups | Shared VPC groups (one for each environment) | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| *add_to_shared_vpc_group* | Add project SA group to Shared VPC group | <code title="">bool</code> |  | <code title="">false</code> |
| *group_format* | Project SA group naming format | <code title="">string</code> |  | <code title="">%project%-serviceaccounts-%env%</code> |
| *only_add_permissions* | Don't create groups, just add permissions (groups have to exist) | <code title="">bool</code> |  | <code title="">false</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| sa_group_id | Service Account group IDs |  |
| sa_group_keys | Service Account group keys |  |
<!-- END TFDOC -->
