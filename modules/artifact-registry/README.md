# Google Cloud Artifact Registry Module

This module simplifies the creation of repositories using Google Cloud Artifact Registry.

Note: Artifact Registry is still in beta, hence this module currently uses the beta provider.

## Standard Repository

```hcl
module "docker_artifact_registry" {
  source     = "./fabric/modules/artifact-registry"
  project_id = "myproject"
  location   = "europe-west1"
  format     = "DOCKER"
  id         = "myregistry"
  iam = {
    "roles/artifactregistry.admin" = ["group:cicd@example.com"]
  }
}
# tftest modules=1 resources=2
```


## Remote and Virtual Repositories

```hcl

module "registry-local" {
  source     = "../modules/artifact-registry"
  project_id = var.project_id
  location   = "europe-west1"
  id         = "local"
  format     = { python = {} }
}

module "registry-remote" {
  source     = "../modules/artifact-registry"
  project_id = var.project_id
  location   = "europe-west1"
  id         = "remote"
  format     = { python = {} }
  mode       = { remote = true }
}

module "registry-virtual" {
  source     = "../modules/artifact-registry"
  project_id = var.project_id
  location   = "europe-west1"
  id         = "virtual"
  format     = { python = {} }
  mode = {
    virtual = {
      remote = {
        repository = module.registry-remote.id
        priority   = 1
      }
      local = {
        repository = module.registry-local.id
        priority   = 10
      }
    }
  }
}

# tftest modules=1 resources=2
```



<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [id](variables.tf#L41) | Repository id. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L58) | Registry project id. | <code>string</code> | ✓ |  |
| [description](variables.tf#L17) | An optional description for the repository. | <code>string</code> |  | <code>&#34;Terraform-managed registry&#34;</code> |
| [encryption_key](variables.tf#L23) | The KMS key name to use for encryption at rest. | <code>string</code> |  | <code>null</code> |
| [format](variables.tf#L29) | Repository format. One of DOCKER or UNSPECIFIED. | <code>string</code> |  | <code>&#34;DOCKER&#34;</code> |
| [iam](variables.tf#L35) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L46) | Labels to be attached to the registry. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [location](variables.tf#L52) | Registry location. Use `gcloud beta artifacts locations list' to get valid values. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified repository id. |  |
| [name](outputs.tf#L22) | Repository name. |  |

<!-- END TFDOC -->
