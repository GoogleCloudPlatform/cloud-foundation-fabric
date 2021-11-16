# Default Service Account IAM management

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| environments | List of environments | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| project_ids_full | Project IDs (full) | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| project_permissions | List of permissions in the project | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| service_accounts | Names of default Compute Engine service account | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |

## Outputs

<!-- END TFDOC -->
