# Project management

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| activate_apis | APIs to activate | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| auto_create_network | Auto create default network | <code title="map&#40;bool&#41;">map(bool)</code> | ✓ |  |
| billing_account | Billing account ID | <code title="">string</code> | ✓ |  |
| boolean_org_policies | Boolean org policies | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| budget_alert_pubsub_topics | Pub/Sub billing alert topics per environment | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| budget_alert_spent_percents | Percentages of budget spent when alert is triggered | <code title="list&#40;number&#41;">list(number)</code> | ✓ |  |
| default_labels | Default labels to add to a project | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| display_name | Display name for project | <code title="">string</code> | ✓ |  |
| domain | Domain | <code title="">string</code> | ✓ |  |
| environments | Project environments | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| essential_contact_categories | Categories of essential contacts | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| folder | Folder name | <code title="">string</code> | ✓ |  |
| folder_ids | Folder IDs | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| is_public_project | Project hosts public services | <code title="">bool</code> | ✓ |  |
| labels | Labels to add to a project | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| list_org_policies | List org policies | <code title="map&#40;any&#41;">map(any)</code> | ✓ |  |
| organization_id | Organization ID | <code title="">number</code> | ✓ |  |
| owner | Owner of the project | <code title="">string</code> | ✓ |  |
| owners | Owners of the project | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| project_id | Project ID | <code title="">string</code> | ✓ |  |
| shared_vpc_projects | Shared VPC projects per environment | <code title="map&#40;string&#41;">map(string)</code> | ✓ |  |
| *budget* | Budget for the project | <code title="map&#40;number&#41;">map(number)</code> |  | <code title="">null</code> |
| *custom_project_id* | Custom project ID | <code title="">string</code> |  | <code title=""></code> |
| *default_sa_privileges* | Default Compute SA privileges (delete, deprivilege, disable, or keep) | <code title="">string</code> |  | <code title="">deprivilege</code> |
| *environment_label* | Label for environment | <code title="">string</code> |  | <code title="">env</code> |
| *metadata* | Default project metadata (OS Login, etc) | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *project_id_format* | Project ID format | <code title="">string</code> |  | <code title="">%id%-%env%</code> |
| *project_sa_name* | Default project service account to create | <code title="">string</code> |  | <code title="">project-service-account</code> |
| *vpcsc_perimeters* | Attach project to a VPC-SC perimeter | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| domain | Cloud Identity domain |  |
| project_ids | Project IDs |  |
| project_ids_per_environment | Project IDs mapped per environment |  |
| project_numbers | Project numbers |  |
| service_accounts | Project service accounts |  |
<!-- END TFDOC -->
