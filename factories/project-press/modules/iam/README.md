# Cloud Identity group IAM management

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| additional_iam_roles | Additional IAM roles for groups | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| additional_roles | Additional sets of IAM roles for groups | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| additional_roles_config | Additional IAM roles config | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| compute_sa_permissions | Compute SA permissions | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| domain | Domain | <code title="">string</code> | ✓ |  |
| environments | List of environments | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| extra_permissions | List of extra per-folder per-environment project permissions | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| group | Group to give privileges to | <code title="">string</code> | ✓ |  |
| group_format | Group format | <code title="">string</code> | ✓ |  |
| project_id | Project ID | <code title="">string</code> | ✓ |  |
| project_ids_full | Project IDs | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| project_permissions | List of project permissions | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| project_sa_permissions | Project SA permissions | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| service_accounts | Service accounts | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |

## Outputs

<!-- END TFDOC -->
