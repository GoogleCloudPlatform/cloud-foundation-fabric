# Google Cloud Dataform Repository module

This module allows managing a dataform repository, allows adding IAM permissions. Also enables attaching a remote repository.

## TODO
[] Add validation rules to variable.

## Examples

### Simple dataform repository with access configration

Simple dataform repository and specifying repository access via the IAM variable.

```hcl
module "dataform" {
  source     = "./fabric/modules/dataform-repository"
  project_id = "my-project"
  repository = {
    my-repository = {
      name = "myrepository"
      iam = {
        "roles/dataform.editor" = ["user:user1@example.org"]
      }
    }
  }
}
# tftest modules=1 resources=2
```

### Repository with an attached remote repository

This creates a dataform repository with a remote repository attached to it. In order to enable dataform to communicate with a 3P GIT provider, an access token must be generated and stored as a secret on GCP. For that, we utilize the existing [secret-manager module](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/secret-manager).

```hcl
module "secret" {
  source     = "./fabric/modules/secret-manager"
  project_id = "my-project"
  secrets = {
    my-secret = {
    }
  }
  versions = {
    my-secret = {
      v1 = { enabled = true, data = "MYTOKEN" }
    }
  }
}

module "dataform" {
  source     = "./fabric/modules/dataform-repository"
  project_id = "my-project"
  repository = {
    my-repository = {
      name           = "myrepository"
      remote_url     = "https://myremoteurl"
      secret_version = module.secret.version_ids["my-secret:v1"]
    }
  }
}
# tftest modules=1 resources=3
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L17) | Id of the project where resources will be created. | <code>string</code> | ✓ |  |
| [repository](variables.tf#L22) | Map of repositories to manage, including setting IAM permissions. | <code title="map&#40;object&#40;&#123;&#10;  name            &#61; string&#10;  branch          &#61; optional&#40;string, &#34;main&#34;&#41;&#10;  remote_url      &#61; optional&#40;string&#41;&#10;  secret_name     &#61; optional&#40;string&#41;&#10;  secret_version  &#61; optional&#40;string, &#34;v1&#34;&#41;&#10;  token           &#61; optional&#40;string&#41;&#10;  service_account &#61; optional&#40;string&#41;&#10;  region          &#61; optional&#40;string&#41;&#10;  iam             &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
<!-- END TFDOC -->
