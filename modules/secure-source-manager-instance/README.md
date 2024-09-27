# Secure Source Manager

This module allows to create a Secure Source Manager instance and repositories in it. Additionally it allows creating instance IAM bindings and repository IAM bindings.

## Examples

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Public instance](#public-instance)
  - [Public instance with CMEK](#public-instance-with-cmek)
  - [Private instance](#private-instance)
  - [IAM](#iam)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

### Public instance

```hcl
module "ssm_instance" {
  source      = "./fabric/modules/secure-source-manager-instance"
  project_id  = var.project_id
  instance_id = "my-instance"
  location    = var.region
  repositories = {
    my-repository = {
      location = var.region
    }
  }
}
# tftest modules=1 resources=2 inventory=public-instance.yaml
```

### Public instance with CMEK 

```hcl
module "ssm_instance" {
  source      = "./fabric/modules/secure-source-manager-instance"
  project_id  = var.project_id
  instance_id = "my-instance"
  location    = var.region
  kms_key     = "projects/another-project-id/locations/${var.region}/keyRings/my-key-ring/cryptoKeys/my-key"
  repositories = {
    my-repository = {}
  }
}
# tftest modules=1 resources=2 inventory=public-instance-with-cmek.yaml
```

### Private instance

```hcl
module "ssm_instance" {
  source      = "./fabric/modules/secure-source-manager-instance"
  project_id  = var.project_id
  instance_id = "my-instance"
  location    = var.region
  ca_pool     = "projects/another-project/locations/${var.region}/caPools/my-ca-pool"
  repositories = {
    my-repository = {}
  }
}
# tftest modules=1 resources=2 inventory=private-instance.yaml
```

### IAM

```hcl
module "ssm_instance" {
  source      = "./fabric/modules/secure-source-manager-instance"
  project_id  = var.project_id
  instance_id = "my-instance"
  location    = var.region
  iam = {
    "roles/securesourcemanager.instanceOwner" = [
      "group:my-instance-admins@myorg.com"
    ]
  }
  repositories = {
    my-repository = {
      iam = {
        "roles/securesourcemanager.repoAdmin" = [
          "group:my-repo-admins@myorg.com"
        ]
      }
    }
  }
}
# tftest modules=1 resources=4 inventory=iam.yaml
```

```hcl

module "ssm_instance" {
  source      = "./fabric/modules/secure-source-manager-instance"
  project_id  = var.project_id
  instance_id = "my-instance"
  location    = var.region
  iam_bindings_additive = {
    my-instance-admin = {
      role   = "roles/securesourcemanager.instanceOwner"
      member = "group:my-instance-admins@myorg.com"
    }
  }
  repositories = {
    my-repository = {
      iam_bindings_additive = {
        my-repository-admin = {
          role   = "roles/securesourcemanager.repoAdmin"
          member = "group:my-repo-admins@myorg.com"
        }
      }
    }
  }
}
# tftest modules=1 resources=4 inventory=iam-bindings.yaml
```

```hcl
module "ssm_instance" {
  source      = "./fabric/modules/secure-source-manager-instance"
  project_id  = var.project_id
  instance_id = "my-instance"
  location    = var.region
  iam_bindings = {
    my-instance-admin = {
      role = "roles/securesourcemanager.instanceOwner"
      members = [
        "group:my-instance-admins@myorg.com"
      ]
    }
  }
  repositories = {
    my-repository = {
      iam_bindings = {
        my-repository-admin = {
          role = "roles/securesourcemanager.repoAdmin"
          members = [
            "group:my-repo-admins@myorg.com"
          ]
        }
      }
    }
  }
}
# tftest modules=1 resources=4 inventory=iam-bindings-additive.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [instance_id](variables.tf#L29) | Instance ID. | <code>string</code> | ✓ |  |
| [location](variables.tf#L46) | Location. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L51) | Project ID. | <code>string</code> | ✓ |  |
| [repositories](variables.tf#L56) | Repositories. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string&#41;&#10;  iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    role    &#61; string&#10;    members &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    role   &#61; string&#10;    member &#61; string&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  initial_config &#61; optional&#40;object&#40;&#123;&#10;    default_branch &#61; optional&#40;string&#41;&#10;    gitignores     &#61; optional&#40;string&#41;&#10;    license        &#61; optional&#40;string&#41;&#10;    readme         &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [ca_pool](variables.tf#L17) | CA pool. | <code>string</code> |  | <code>null</code> |
| [iam](variables-iam.tf#L17) | IAM bindings. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L23) | IAM bindings. | <code title="map&#40;object&#40;&#123;&#10;  role    &#61; string&#10;  members &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L32) | IAM bindings. | <code title="map&#40;object&#40;&#123;&#10;  role   &#61; string&#10;  member &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [instance_create](variables.tf#L23) | Create SSM Instance. When set to false, uses instance_id to reference existing SSM instance. | <code>bool</code> |  | <code>true</code> |
| [kms_key](variables.tf#L34) | KMS key. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L40) | Instance labels. | <code>map&#40;string&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [instance](outputs.tf#L17) | Instance. |  |
| [instance_id](outputs.tf#L22) | Instance id. |  |
| [repositories](outputs.tf#L27) | Repositories. |  |
| [repository_ids](outputs.tf#L32) | Repository ids. |  |
<!-- END TFDOC -->
