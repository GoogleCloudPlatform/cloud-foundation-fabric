# Google Cloud Artifact Registry Module

This module simplifies the creation of repositories using Google Cloud Artifact Registry.

<!-- BEGIN TOC -->
- [Standard Repository](#standard-repository)
- [Remote and Virtual Repositories](#remote-and-virtual-repositories)
- [Additional Docker and Maven Options](#additional-docker-and-maven-options)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Standard Repository

```hcl
module "docker_artifact_registry" {
  source     = "./fabric/modules/artifact-registry"
  project_id = "myproject"
  location   = "europe-west1"
  name       = "myregistry"
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
  name       = "local"
  format     = { python = {} }
}

module "registry-remote" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = "europe-west1"
  name       = "remote"
  format     = { python = {} }
  mode       = { remote = true }
}

module "registry-virtual" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = "europe-west1"
  name       = "virtual"
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

# tftest modules=3 resources=3 inventory=remote-virtual.yaml
```

## Additional Docker and Maven Options

```hcl

module "registry-docker" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = "europe-west1"
  name       = "docker"
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
  name       = "maven"
  format = {
    maven = {
      allow_snapshot_overwrites = true
      version_policy            = "RELEASE"
    }
  }
}

# tftest modules=2 resources=2
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [location](variables.tf#L68) | Registry location. Use `gcloud beta artifacts locations list' to get valid values. | <code>string</code> | ✓ |  |
| [name](variables.tf#L93) | Registry name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L98) | Registry project id. | <code>string</code> | ✓ |  |
| [description](variables.tf#L17) | An optional description for the repository. | <code>string</code> |  | <code>&#34;Terraform-managed registry&#34;</code> |
| [encryption_key](variables.tf#L23) | The KMS key name to use for encryption at rest. | <code>string</code> |  | <code>null</code> |
| [format](variables.tf#L29) | Repository format. | <code title="object&#40;&#123;&#10;  apt &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;  docker &#61; optional&#40;object&#40;&#123;&#10;    immutable_tags &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  kfp &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;  go  &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;  maven &#61; optional&#40;object&#40;&#123;&#10;    allow_snapshot_overwrites &#61; optional&#40;bool&#41;&#10;    version_policy            &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  npm    &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;  python &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;  yum    &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123; docker &#61; &#123;&#125; &#125;</code> |
| [iam](variables.tf#L56) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L62) | Labels to be attached to the registry. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [mode](variables.tf#L73) | Repository mode. | <code title="object&#40;&#123;&#10;  standard &#61; optional&#40;bool&#41;&#10;  remote   &#61; optional&#40;bool&#41;&#10;  virtual &#61; optional&#40;map&#40;object&#40;&#123;&#10;    repository &#61; string&#10;    priority   &#61; number&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123; standard &#61; true &#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified repository id. |  |
| [image_path](outputs.tf#L22) | Repository path for images. |  |
| [name](outputs.tf#L32) | Repository name. |  |
<!-- END TFDOC -->
