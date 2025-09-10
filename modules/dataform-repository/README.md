# Google Cloud Dataform Repository module

This module allows managing a dataform repository, allows adding IAM permissions. Also enables attaching a remote repository.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Simple dataform repository with access configuration](#simple-dataform-repository-with-access-configuration)
  - [Repository with an attached remote repository](#repository-with-an-attached-remote-repository)
- [Variables](#variables)
<!-- END TOC -->

## Examples

### Simple dataform repository with access configuration

Simple dataform repository and specifying repository access via the IAM variable.

```hcl
module "dataform" {
  source     = "./fabric/modules/dataform-repository"
  project_id = "my-project"
  name       = "my-repository"
  region     = "europe-west1"
  iam = {
    "roles/dataform.editor" = ["user:user1@example.org"]
  }
}
# tftest modules=1 resources=2
```

### Repository with an attached remote repository

This creates a dataform repository with a remote repository attached to it. In order to enable dataform to communicate with a 3P GIT provider, an access token must be generated and stored as a secret on GCP. For that, we utilize the existing [secret-manager module](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/secret-manager).

```hcl
module "secret" {
  source     = "./fabric/modules/secret-manager"
  project_id = "fast-bi-fabric"
  secrets = {
    my-secret = {
      versions = {
        v1 = { data = "MYTOKEN" }
      }
    }
  }
}

module "dataform" {
  source     = "./fabric/modules/dataform-repository"
  project_id = "fast-bi-fabric"
  name       = "my-repository"
  region     = "europe-west1"
  remote_repository_settings = {
    url         = "my-url"
    secret_name = "my-secret"
    token       = module.secret.version_ids["my-secret/v1"]
  }
}
# tftest modules=2 resources=3 skip-tofu
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L54) | Name of the dataform repository. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L59) | Id of the project where resources will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L64) | The repository's region. | <code>string</code> | ✓ |  |
| [iam](variables.tf#L17) | IAM bindings in {ROLE => [MEMBERS]} format. Mutually exclusive with the access_* variables used for basic roles. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables.tf#L24) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables.tf#L39) | Keyring individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [remote_repository_settings](variables.tf#L69) | Remote settings required to attach the repository to a remote repository. | <code title="object&#40;&#123;&#10;  url            &#61; optional&#40;string&#41;&#10;  branch         &#61; optional&#40;string, &#34;main&#34;&#41;&#10;  secret_name    &#61; optional&#40;string&#41;&#10;  secret_version &#61; optional&#40;string, &#34;v1&#34;&#41;&#10;  token          &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [service_account](variables.tf#L81) | Service account used to execute the dataform workflow. | <code>string</code> |  | <code>&#34;&#34;</code> |
<!-- END TFDOC -->
