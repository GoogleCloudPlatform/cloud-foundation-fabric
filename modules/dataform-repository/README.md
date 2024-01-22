# Google Cloud Dataform Repository module

This module allows managing a single dataform repository including attaching a remote repository if available.

## TODO

- [ ] Add repository specific IAM set possibilities

## Examples

### Simple repository

This creates a simple dataform repository in the project defined. Access is managed on a project level. Service account used is the default dataform service account.

```hcl
module "dataform" {
  source                           = "./fabric/modules/dataform-repository"
  project_id                       = "marcs-testproject"
  dataform_repository_name         = "test-repository"
}
# tftest modules=1 resources=1
```

### Repository with an attached remote repository

This creates a dataform repository in the project defined, with a remote repository already attached to it.

```hcl
module "dataform" {
  source                           = "./fabric/modules/dataform-repository"
  project_id                       = "marcs-testproject"
  dataform_repository_name         = "test-repository"
  dataform_secret_name             = "my-dataform-secret"
  dataform_secret_region           = "us-east1"
  dataform_remote_repository_url   = "https://github.com/username/dataform-repository"
  dataform_remote_repository_token = "kjnsdaf67asdc---MYTOKEN---ADSDAS"
  dataform_service_account         =
}
# tftest modules=1 resources=3
```

<!-- BEGIN TFDOC -->

## Variables

| name                                                  | description                                                                                         |        type         | required |             default             |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------- | :-----------------: | :------: | :-----------------------------: |
| [dataform_repository_name](variables.tf#L33)          | The dataform repositories name.                                                                     | <code>string</code> |    ✓     |                                 |
| [project_id](variables.tf#L47)                        | Id of the project where repository will be created.                                                 | <code>string</code> |    ✓     |                                 |
| [dataform_remote_repository_branch](variables.tf#L17) | Default branch, default is \"main\".                                                                | <code>string</code> |          |   <code>&#34;main&#34;</code>   |
| [dataform_remote_repository_token](variables.tf#L22)  | the token value to be stored in a secret. Attention: this should not be stored on e.g. Github.      | <code>string</code> |          |     <code>&#34;&#34;</code>     |
| [dataform_remote_repository_url](variables.tf#L28)    | URL of the remote repository.                                                                       | <code>string</code> |          |     <code>&#34;&#34;</code>     |
| [dataform_secret_name](variables.tf#L37)              | Name of the secret the token to the remote repository is stored.                                    | <code>string</code> |          |     <code>&#34;&#34;</code>     |
| [dataform_service_account](variables.tf#L42)          | Service account to be used to run workflow executions, if not the default dataform service account. | <code>string</code> |          |     <code>&#34;&#34;</code>     |
| [region](variables.tf#L51)                            | Repository region.                                                                                  | <code>string</code> |          | <code>&#34;us-east1&#34;</code> |

## Outputs

| name                                       | description               | sensitive |
| ------------------------------------------ | ------------------------- | :-------: |
| [dataform_repository_name](outputs.tf#L17) | Dataform repository name. |           |
| [dataform_service_account](outputs.tf#L22) | Dataform service account. |           |

<!-- END TFDOC -->
