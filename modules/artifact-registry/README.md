# Google Cloud Artifact Registry Module

This module simplifies the creation of repositories using Google Cloud Artifact Registry.

<!-- BEGIN TOC -->
- [Standard Repository](#standard-repository)
- [Remote and Virtual Repositories](#remote-and-virtual-repositories)
- [Additional Docker and Maven Options](#additional-docker-and-maven-options)
- [Cleanup Policies](#cleanup-policies)
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

## Cleanup Policies

```hcl

module "registry-docker" {
  source                 = "./fabric/modules/artifact-registry"
  project_id             = var.project_id
  location               = "europe-west1"
  name                   = "docker-cleanup-policies"
  format                 = { docker = {} }
  cleanup_policy_dry_run = false
  cleanup_policies = {
    keep-5-versions = {
      action = "KEEP"
      most_recent_versions = {
        package_name_prefixes = ["test"]
        keep_count            = 5
      }
    }
    keep-tagged-release = {
      action = "KEEP"
      condition = {
        tag_state             = "TAGGED"
        tag_prefixes          = ["release"]
        package_name_prefixes = ["webapp", "mobile"]
      }
    }
  }
}


# tftest modules=1 resources=1 inventory=cleanup-policies.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cleanup_policies](variables.tf#L17) | Object containing details about the cleanup policies for an Artifact Registry repository. | <code title="map&#40;object&#40;&#123;&#10;  action &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    tag_state             &#61; optional&#40;string&#41;&#10;    tag_prefixes          &#61; optional&#40;list&#40;string&#41;&#41;&#10;    older_than            &#61; optional&#40;string&#41;&#10;    newer_than            &#61; optional&#40;string&#41;&#10;    package_name_prefixes &#61; optional&#40;list&#40;string&#41;&#41;&#10;    version_name_prefixes &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  most_recent_versions &#61; optional&#40;object&#40;&#123;&#10;    package_name_prefixes &#61; optional&#40;list&#40;string&#41;&#41;&#10;    keep_count            &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;&#10;&#10;&#10;default &#61; null">map&#40;object&#40;&#123;&#8230;default &#61; null</code> | ✓ |  |
| [location](variables.tf#L95) | Registry location. Use `gcloud beta artifacts locations list' to get valid values. | <code>string</code> | ✓ |  |
| [name](variables.tf#L120) | Registry name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L125) | Registry project id. | <code>string</code> | ✓ |  |
| [cleanup_policy_dry_run](variables.tf#L38) | If true, the cleanup pipeline is prevented from deleting versions in this repository. | <code>bool</code> |  | <code>null</code> |
| [description](variables.tf#L44) | An optional description for the repository. | <code>string</code> |  | <code>&#34;Terraform-managed registry&#34;</code> |
| [encryption_key](variables.tf#L50) | The KMS key name to use for encryption at rest. | <code>string</code> |  | <code>null</code> |
| [format](variables.tf#L56) | Repository format. | <code title="object&#40;&#123;&#10;  apt &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;  docker &#61; optional&#40;object&#40;&#123;&#10;    immutable_tags &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  kfp &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;  go  &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;  maven &#61; optional&#40;object&#40;&#123;&#10;    allow_snapshot_overwrites &#61; optional&#40;bool&#41;&#10;    version_policy            &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  npm    &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;  python &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;  yum    &#61; optional&#40;object&#40;&#123;&#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123; docker &#61; &#123;&#125; &#125;</code> |
| [iam](variables.tf#L83) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L89) | Labels to be attached to the registry. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [mode](variables.tf#L100) | Repository mode. | <code title="object&#40;&#123;&#10;  standard &#61; optional&#40;bool&#41;&#10;  remote   &#61; optional&#40;bool&#41;&#10;  virtual &#61; optional&#40;map&#40;object&#40;&#123;&#10;    repository &#61; string&#10;    priority   &#61; number&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123; standard &#61; true &#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified repository id. |  |
| [image_path](outputs.tf#L22) | Repository path for images. |  |
| [name](outputs.tf#L32) | Repository name. |  |
<!-- END TFDOC -->
