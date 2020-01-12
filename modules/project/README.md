# Project Module

## Example

```hcl
module "project" {
  source          = "./modules/project"
  parent          = var.folder.id
  billing_account = var.billing_account_id
  prefix          = "foo"
  name            = "project-example"
  oslogin         = true
  oslogin_admins  = var.admins
  services = concat(var.project_services, [
    "cloudkms.googleapis.com", "accesscontextmanager.googleapis.com"
  ])
  iam_roles = ["roles/container.hostServiceAgentUser"]
  iam_members = { "roles/container.hostServiceAgentUser" = [
    "serviceAccount:${var.gke_service_account}"
  ] }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| name | Project name and id suffix. | <code title="">string</code> | ✓ |  |
| parent | The resource name of the parent Folder or Organization. Must be of the form folders/folder_id or organizations/org_id. | <code title="">string</code> | ✓ |  |
| prefix | Prefix used to generate project id and name. | <code title="">string</code> | ✓ |  |
| *auto_create_network* | Whether to create the default network for the project | <code title="">bool</code> |  | <code title="">false</code> |
| *billing_account* | Billing account id. | <code title="">string</code> |  | <code title=""></code> |
| *custom_roles* | Map of role name => list of permissions to create in this project. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_members* | Map of member lists used to set authoritative bindings, keyed by role. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_nonauth_members* | Map of member lists used to set non authoritative bindings, keyed by role. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_nonauth_roles* | List of roles used to set non authoritative bindings. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *iam_roles* | List of roles used to set authoritative bindings. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *labels* | Resource labels. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *lien_reason* | If non-empty, creates a project lien with this description. | <code title="">string</code> |  | <code title=""></code> |
| *oslogin* | Enable OS Login. | <code title="">bool</code> |  | <code title="">false</code> |
| *oslogin_admins* | List of IAM-style identities that will be granted roles necessary for OS Login administrators. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *oslogin_users* | List of IAM-style identities that will be granted roles necessary for OS Login users. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *services* | Service APIs to enable. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| cloudsvc_service_account | Cloud services service account (depends on services). |  |
| custom_roles | Ids of the created custom roles. |  |
| gce_service_account | Default GCE service account (depends on services). |  |
| gcr_service_account | Default GCR service account (depends on services). |  |
| gke_service_account | Default GKE service account (depends on services). |  |
| name | Name (depends on services). |  |
| number | Project number (depends on services). |  |
| project_id | Project id (depends on services). |  |
<!-- END TFDOC -->
