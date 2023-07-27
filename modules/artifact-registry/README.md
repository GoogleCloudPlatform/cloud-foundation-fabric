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
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = "europe-west1"
  id         = "local"
  format     = { python = {} }
}

module "registry-remote" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = "europe-west1"
  id         = "remote"
  format     = { python = {} }
  mode       = { remote = true }
}

module "registry-virtual" {
  source     = "./fabric/modules/artifact-registry"
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

## Additional Docker and Maven Options

```hcl

module "registry-docker" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = "europe-west1"
  id         = "docker"
  format = {
    docker = {
      immutable_tags = true
    }
  }
}

module "registry-maven" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = "europe-west1"
  id         = "maven"
  format = {
    maven = {
      allow_snapshot_overwrites = true
      version_policy            = "RELEASE"
    }
  }
}

# tftest modules=1 resources=2
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [id](variables.tf#L56) | Repository id. | <code>string</code> | ✓ |  |
| [location](variables.tf#L67) | Registry location. Use `gcloud beta artifacts locations list' to get valid values. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L88) | Registry project id. | <code>string</code> | ✓ |  |
| [description](variables.tf#L17) | An optional description for the repository. | <code>string</code> |  | <code>&#34;Terraform-managed registry&#34;</code> |
| [encryption_key](variables.tf#L44) | The KMS key name to use for encryption at rest. | <code>string</code> |  | <code>null</code> |
| [iam](variables.tf#L50) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L61) | Labels to be attached to the registry. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [mode](variables.tf#L72) | Repository mode. | <code title="object&#40;&#123;&#10;  standard &#61; optional&#40;bool, false&#41;&#10;  remote   &#61; optional&#40;bool, false&#41;&#10;  virtual &#61; optional&#40;map&#40;object&#40;&#123;&#10;    repository &#61; string&#10;    priority   &#61; number&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123; standard &#61; true &#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified repository id. |  |
| [name](outputs.tf#L22) | Repository name. |  |

<!-- END TFDOC -->
