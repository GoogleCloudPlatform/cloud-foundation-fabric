# Project Service Account management

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| environments | List of environments | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| project_groups | Map of project groups env per group | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| project_ids_full | Project IDs | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| sa_groups | Map of service account groups env per group | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| service_account_roles | Service accounts to provision | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| service_accounts | Service accounts to provision | <code title="list&#40;any&#41;">list(any)</code> | ✓ |  |
| *only_add_permissions* | Don't create groups, just add permissions (groups have to exist) | <code title="">bool</code> |  | <code title="">false</code> |

## Outputs

<!-- END TFDOC -->
