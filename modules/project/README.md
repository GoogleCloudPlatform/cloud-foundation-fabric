# Project Module

## Examples

### Minimal example with IAM

```hcl
module "project" {
  source          = "./modules/project"
  billing_account = "123456-123456-123456"
  name            = "project-example"
  parent          = "folders/1234567890"
  prefix          = "foo"
  services        = [
    "container.googleapis.com",
    "stackdriver.googleapis.com"
  ]
  iam_roles = ["roles/container.hostServiceAgentUser"]
  iam_members = {
    "roles/container.hostServiceAgentUser" = [
      "serviceAccount:${var.gke_service_account}"
    ]
  }
}
```

### Minimal example with IAM additive roles

```hcl
module "project" {
  source          = "./modules/project"
  name            = "project-example"
  project_create  = false

  iam_additive_bindings = {
    "group:usergroup_watermlon_experimentation@lemonadeinc.io" = [
	    "roles/viewer",
	    "roles/storage.objectAdmin"
    ],
    "group:usergroup_gcp_admin@lemonadeinc.io" = [
	    "roles/owner",
    ],
    "group:usergroup_gcp_privilege_access@lemonadeinc.io" = [
	    "roles/editor"
    ],
    "group:engineering@lemonadeinc.io" = [
	    "roles/pubsub.subscriber",
	    "roles/storage.objectViewer"
    ],
  }
}
```

### Organization policies

```hcl
module "project" {
  source          = "./modules/project"
  billing_account = "123456-123456-123456"
  name            = "project-example"
  parent          = "folders/1234567890"
  prefix          = "foo"
  services        = [
    "container.googleapis.com",
    "stackdriver.googleapis.com"
  ]
  policy_boolean = {
    "constraints/compute.disableGuestAttributesAccess" = true
    "constraints/compute.skipDefaultNetworkCreation" = true
  }
  policy_list = {
    "constraints/compute.trustedImageProjects" = {
      inherit_from_parent = null
      suggested_value = null
      status = true
      values = ["projects/my-project"]
    }
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| name | Project name and id suffix. | <code title="">string</code> | ✓ |  |
| *auto_create_network* | Whether to create the default network for the project | <code title="">bool</code> |  | <code title="">false</code> |
| *billing_account* | Billing account id. | <code title="">string</code> |  | <code title="">null</code> |
| *custom_roles* | Map of role name => list of permissions to create in this project. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_additive_bindings* | Map of roles list used to set non authoritative bindings, keyed by member. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *iam_members* | Map of member lists used to set authoritative bindings, keyed by role. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_roles* | List of roles used to set authoritative bindings. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *labels* | Resource labels. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *lien_reason* | If non-empty, creates a project lien with this description. | <code title="">string</code> |  | <code title=""></code> |
| *oslogin* | Enable OS Login. | <code title="">bool</code> |  | <code title="">false</code> |
| *oslogin_admins* | List of IAM-style identities that will be granted roles necessary for OS Login administrators. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *oslogin_users* | List of IAM-style identities that will be granted roles necessary for OS Login users. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *parent* | Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format. | <code title="">string</code> |  | <code title="">null</code> |
| *policy_boolean* | Map of boolean org policies and enforcement value, set value to null for policy restore. | <code title="map&#40;bool&#41;">map(bool)</code> |  | <code title="">{}</code> |
| *policy_list* | Map of list org policies, status is true for allow, false for deny, null for restore. Values can only be used for allow or deny. | <code title="map&#40;object&#40;&#123;&#10;inherit_from_parent &#61; bool&#10;suggested_value     &#61; string&#10;status              &#61; bool&#10;values              &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *prefix* | Prefix used to generate project id and name. | <code title="">string</code> |  | <code title="">null</code> |
| *project_create* | Create project. When set to false, uses a data source to reference existing project. | <code title="">bool</code> |  | <code title="">true</code> |
| *service_config* | Configure service API activation. | <code title="object&#40;&#123;&#10;disable_on_destroy         &#61; bool&#10;disable_dependent_services &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;disable_on_destroy         &#61; true&#10;disable_dependent_services &#61; true&#10;&#125;">...</code> |
| *services* | Service APIs to enable. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| custom_roles | Ids of the created custom roles. |  |
| name | Project name. |  |
| number | Project number. |  |
| project_id | Project id. |  |
| service_accounts | Product robot service accounts in project. |  |
<!-- END TFDOC -->
