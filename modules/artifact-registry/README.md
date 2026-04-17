# Google Cloud Artifact Registry Module

This module simplifies the creation of repositories using Google Cloud Artifact Registry.

<!-- BEGIN TOC -->
- [Simple Docker Repository](#simple-docker-repository)
- [Remote and Virtual Repositories](#remote-and-virtual-repositories)
- [Additional Docker and Maven Options](#additional-docker-and-maven-options)
- [Other Formats](#other-formats)
- [Cleanup Policies](#cleanup-policies)
- [IAM](#iam)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Simple Docker Repository

```hcl
module "docker_artifact_registry" {
  source     = "./fabric/modules/artifact-registry"
  project_id = "myproject"
  location   = "europe-west1"
  name       = "myregistry"
  format     = { docker = { standard = {} } }
  iam = {
    "roles/artifactregistry.admin" = ["group:cicd@example.com"]
  }
}

module "docker_artifact_registry_remote" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = "us-west1"
  name       = "remote"
  format = {
    docker = {
      remote = {
        common_repository = module.docker_artifact_registry.id
      }
    }
  }
}
# tftest modules=2 resources=3
```

## Remote and Virtual Repositories

```hcl

module "registry-local" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = "europe-west1"
  name       = "local"
  format = {
    python = {
      standard = true
    }
  }
}

module "registry-remote" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = "europe-west1"
  name       = "remote"
  format = {
    python = {
      remote = {
        public_repository = "PYPI"
      }
    }
  }
}

module "registry-virtual" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = "europe-west1"
  name       = "virtual"
  format = {
    python = {
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
      standard = {
        immutable_tags = true
      }
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
      standard = {
        allow_snapshot_overwrites = true
        version_policy            = "RELEASE"
      }
    }
  }
}

# tftest modules=2 resources=2
```

## Other Formats

```hcl
module "apt-registry" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = var.region
  name       = "apt-registry"
  format     = { apt = { standard = true } }
}

module "generic-registry" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = var.region
  name       = "generic-registry"
  format     = { generic = { standard = true } }
}

module "go-registry" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = var.region
  name       = "go-registry"
  format     = { go = { standard = true } }
}

module "googet-registry" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = var.region
  name       = "googet-registry"
  format     = { googet = { standard = true } }
}

module "kfp-registry" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = var.region
  name       = "kfp-registry"
  format     = { kfp = { standard = true } }
}

module "npm-registry" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = var.region
  name       = "npm-registry"
  format     = { npm = { standard = true } }
}

module "yum-registry" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  location   = var.region
  name       = "yum-registry"
  format     = { yum = { standard = true } }
}

# tftest modules=7 resources=7 inventory=other-formats.yaml
```

## Cleanup Policies

```hcl
module "registry-docker" {
  source                 = "./fabric/modules/artifact-registry"
  project_id             = var.project_id
  location               = "europe-west1"
  name                   = "docker-cleanup-policies"
  format                 = { docker = { standard = {} } }
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

## IAM

This module implements the same IAM interface than the other modules.
You can choose one (and only one) of the three options below:

```hcl
# Authoritative IAM bindings with context interpolation for project, location,
# and IAM principals
module "authoritative_iam" {
  source     = "./fabric/modules/artifact-registry"
  project_id = "$project_ids:myproject"
  location   = "$locations:ew1"
  name       = "myregistry"
  format     = { docker = { standard = {} } }
  context = {
    locations = {
      ew1 = "europe-west1"
    }
    iam_principals = {
      cicd-team = "group:cicd@example.com"
    }
    project_ids = {
      myproject = "myproject"
    }
  }
  iam = {
    "roles/artifactregistry.admin" = ["$iam_principals:cicd-team"]
  }
}

# Authoritative IAM bindings (with conditions)
module "authoritative_iam_conditions" {
  source     = "./fabric/modules/artifact-registry"
  project_id = "myproject"
  location   = "europe-west1"
  name       = "myregistry"
  format     = { docker = { standard = {} } }
  iam_bindings = {
    "ci-admin" = {
      members = ["group:cicd@example.com"]
      role    = "roles/artifactregistry.admin"
      // condition = {
      //   expression  = string
      //   title       = string
      //   description = optional(string)
      // }
    }
  }
}

# Additive IAM bindings
module "additive_iam" {
  source     = "./fabric/modules/artifact-registry"
  project_id = "myproject"
  location   = "europe-west1"
  name       = "myregistry"
  format     = { docker = { standard = {} } }
  iam_bindings_additive = {
    "ci-admin" = {
      member = "group:cicd@example.com"
      role   = "roles/artifactregistry.admin"
      // condition = {
      //   expression  = string
      //   title       = string
      //   description = optional(string)
      // }
    }
    "ci-read" = {
      member = "group:cicd-read@example.com"
      role   = "roles/artifactregistry.reader"
      // condition = {
      //   expression  = string
      //   title       = string
      //   description = optional(string)
      // }
    }
  }
}
# tftest modules=3 resources=7
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [cleanup_policies](variables.tf#L17) | Object containing details about the cleanup policies for an Artifact Registry repository. | <code>map&#40;object&#40;&#123;&#8230;default &#61; null</code> | ✓ |  |
| [format](variables.tf#L79) | Repository format. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [location](variables.tf#L229) | Registry location. Use `gcloud beta artifacts locations list' to get valid values. | <code>string</code> | ✓ |  |
| [name](variables.tf#L234) | Registry name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L239) | Registry project id. | <code>string</code> | ✓ |  |
| [cleanup_policy_dry_run](variables.tf#L38) | If true, the cleanup pipeline is prevented from deleting versions in this repository. | <code>bool</code> |  | <code>null</code> |
| [context](variables.tf#L44) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L61) | An optional description for the repository. | <code>string</code> |  | <code>&#34;Terraform-managed registry&#34;</code> |
| [enable_vulnerability_scanning](variables.tf#L67) | Whether vulnerability scanning should be enabled in the repository. | <code>bool</code> |  | <code>null</code> |
| [encryption_key](variables.tf#L73) | The KMS key name to use for encryption at rest. | <code>string</code> |  | <code>null</code> |
| [iam](variables-iam.tf#L36) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L43) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L58) | Individual additive IAM bindings. Keys are arbitrary. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L73) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L223) | Labels to be attached to the registry. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [tag_bindings](variables.tf#L244) | Tag bindings for this repository, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [universe](variables.tf#L251) | GCP universe where to deploy the project. The prefix will be prepended to the project id. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L34) | Fully qualified repository id. |  |
| [name](outputs.tf#L44) | Repository name. |  |
| [repository](outputs.tf#L54) | Repository object. |  |
| [url](outputs.tf#L64) | Repository URL. |  |
<!-- END TFDOC -->
