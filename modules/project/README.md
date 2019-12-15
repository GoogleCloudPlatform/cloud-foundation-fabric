# Google Cloud Simple Project Creation

This module allows simple Google Cloud Platform project creation, with minimal service and project-level IAM binding management. It's designed to be used for architectural design and rapid prototyping, as part of the [Cloud Foundation Fabric](https://github.com/terraform-google-modules/cloud-foundation-fabric) environments.

The resources/services/activations/deletions that this module will create/trigger are:

- one project
- zero or one project metadata items for OSLogin activation
- zero or more project service activations
- zero or more project-level IAM bindings
- zero or more project-level custom roles
- zero or one project liens

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| name | Project name and id suffix. | string | ✓
| parent | The resource name of the parent Folder or Organization. Must be of the form folders/folder_id or organizations/org_id. | string | ✓
| prefix | Prefix used to generate project id and name. | string | ✓
| *auto_create_network* | Whether to create the default network for the project | bool | 
| *billing_account* | Billing account id. | string | 
| *custom_roles* | Map of role name => list of permissions to create in this project. | map(list(string)) | 
| *iam_members* | Map of member lists used to set authoritative bindings, keyed by role. | map(list(string)) | 
| *iam_nonauth_members* | Map of member lists used to set non authoritative bindings, keyed by role. | map(list(string)) | 
| *iam_nonauth_roles* | List of roles used to set non authoritative bindings. | list(string) | 
| *iam_roles* | List of roles used to set authoritative bindings. | list(string) | 
| *labels* | Resource labels. | map(string) | 
| *lien_reason* | If non-empty, creates a project lien with this description. | string | 
| *oslogin* | Enable OS Login. | bool | 
| *oslogin_admins* | List of IAM-style identities that will be granted roles necessary for OS Login administrators. | list(string) | 
| *oslogin_users* | List of IAM-style identities that will be granted roles necessary for OS Login users. | list(string) | 
| *owners* | IAM-style identities that will be granted non-authoritative viewer role. | list(string) | 
| *services* | Service APIs to enable. | list(string) | 

## Outputs

| name | description |
|---|---|
| cloudsvc_service_account | Cloud services service account (depends on services). |
| custom_roles | Ids of the created custom roles. |
| gce_service_account | Default GCE service account (depends on services). |
| gke_service_account | Default GKE service account (depends on services). |
| name | Name (depends on services). |
| number | Project number (depends on services). |
| project_id | Project id (depends on services). |
<!-- END TFDOC -->
