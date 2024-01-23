# Google Cloud Dataform Repository module

This module allows managing a single dataform repository including attaching a remote repository if available.

## Examples


### Simple dataform repository with access configration
Simple dataform repository, with the possibility of specifying repository access via the IAM variable.

```hcl
module "dataform-repository" {
  source                   = "./fabric/modules/dataform-repository"
  project_id               = "my-project"
  dataform_repository_name = "my-repository"
  iam = {
    "roles/dataform.editor" = ["user:user1@example.org"]
  }
}
# tftest modules=1 resources=2
```

### Repository with an attached remote repository
This creates a dataform repository with a remote repository attached to it.

```hcl
module "dataform" {
  source                           = "./fabric/modules/dataform-repository"
  project_id                       = "my-project"
  dataform_repository_name         = "my-repository"
  dataform_remote_repository_url   = "https://github.com/username/dataform-repository"
  dataform_remote_repository_token = "kjnsdaf67asdc---MYTOKEN---ADSDAS"
}
# tftest modules=1 resources=3
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [dataform_repository_name](variables.tf#L33) | The dataform repositories name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L52) | Id of the project where repository will be created. | <code>string</code> | ✓ |  |
| [dataform_remote_repository_branch](variables.tf#L17) | Default branch, default is \"main\". | <code>string</code> |  | <code>&#34;main&#34;</code> |
| [dataform_remote_repository_token](variables.tf#L22) | the token value to be stored in a secret. Attention: this should not be stored on e.g. Github. | <code>string</code> |  | <code>&#34;&#34;</code> |
| [dataform_remote_repository_url](variables.tf#L28) | URL of the remote repository. | <code>string</code> |  | <code>&#34;&#34;</code> |
| [dataform_secret_name](variables.tf#L37) | Name of the secret the token to the remote repository is stored. | <code>string</code> |  | <code>&#34;&#34;</code> |
| [dataform_service_account](variables.tf#L42) | Service account to be used to run workflow executions, if not the default dataform service account. | <code>string</code> |  | <code>&#34;&#34;</code> |
| [iam](variables.tf#L47) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [region](variables.tf#L56) | Repository region. | <code>string</code> |  | <code>&#34;europe-west3&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [dataform_repository_name](outputs.tf#L17) | Dataform repository name. |  |
| [dataform_service_account](outputs.tf#L22) | Dataform service account. |  |
<!-- END TFDOC -->
