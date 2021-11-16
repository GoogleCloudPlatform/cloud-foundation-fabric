# Gitlab helper

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| environments | Environments | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| gcp_service_account_format | GCP service account format | <code title="">string</code> | ✓ |  |
| gitlab_gke_cluster | GKE cluster name where Gitlab is installed in | <code title="">string</code> | ✓ |  |
| gitlab_gke_cluster_location | Region for gitlab_gke_cluster | <code title="">string</code> | ✓ |  |
| gitlab_gke_project | Google Cloud project where Gitlab cluster resides in | <code title="">string</code> | ✓ |  |
| gitlab_owners | Gitlab owner | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| gitlab_project_group | Gitlab project group ID | <code title="">string</code> | ✓ |  |
| gitlab_project_id | Gitlab project ID | <code title="">string</code> | ✓ |  |
| gitlab_project_runner | Whether to provision a Gitlab runner | <code title="">bool</code> | ✓ |  |
| gitlab_runner_version | None | <code title="">string</code> | ✓ |  |
| gitlab_server | Gitlab server URL | <code title="">string</code> | ✓ |  |
| gitlab_team | Gitlab team | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| gitlab_team_permissions | Gitlab team permissions | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| gke_deployment_format | GKE runner deployment format | <code title="">string</code> | ✓ |  |
| gke_namespace_format | GKE namespace format | <code title="">string</code> | ✓ |  |
| gke_secret_format | GKE secret format | <code title="">string</code> | ✓ |  |
| gke_service_account_format | GKE service account format | <code title="">string</code> | ✓ |  |
| gke_service_account_role_binding_format | GKE service account role binding format | <code title="">string</code> | ✓ |  |
| gke_service_account_role_format | GKE service account role format | <code title="">string</code> | ✓ |  |
| iam_permissions | Roles to grant the Gitlab runner GCP service account in the project | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> | ✓ |  |
| project_id | Project ID | <code title="">string</code> | ✓ |  |
| project_ids_full | Project IDs (full) | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |

## Outputs

<!-- END TFDOC -->
