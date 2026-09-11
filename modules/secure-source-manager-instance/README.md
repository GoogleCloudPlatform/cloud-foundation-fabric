# Secure Source Manager

This module allows to create a Secure Source Manager instance and repositories in it. Additionally it allows creating instance IAM bindings and repository IAM bindings.

## Examples

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Public instance](#public-instance)
  - [Public instance with CMEK](#public-instance-with-cmek)
  - [Private instance](#private-instance)
  - [IAM](#iam)
  - [Branch Protection Rules](#branch-protection-rules)
  - [Initial Configuration](#initial-configuration)
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
  private_configs = {
    is_private = true
  }
  repositories = {
    my-repository = {}
  }
}
# tftest modules=1 resources=2 inventory=private-instance.yaml
```

You can optionally specify a Certificate Authority (CAS) pool and use your own certificate, and list additional projects allowed to set up Private Service Connect connections to the instance.

Repositories can be assigned their own service account, which Secure Source Manager uses as the triggering identity when it starts a build for that repository. Without it a repository falls back to the shared Secure Source Manager service agent, so set it whenever repositories need to be isolated from one another.

```hcl
module "ssm_instance" {
  source      = "./fabric/modules/secure-source-manager-instance"
  project_id  = var.project_id
  instance_id = "my-instance"
  location    = var.region
  private_configs = {
    is_private           = true
    ca_pool_id           = "projects/another-project/locations/${var.region}/caPools/my-ca-pool"
    psc_allowed_projects = ["another-project"]
  }
  repositories = {
    my-repository = {
      service_account = "my-repository-sa@${var.project_id}.iam.gserviceaccount.com"
    }
  }
}
# tftest modules=1 resources=2 inventory=private-instance-ca-pool.yaml
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

### Branch Protection Rules

```hcl
module "ssm_instance" {
  source      = "./fabric/modules/secure-source-manager-instance"
  project_id  = var.project_id
  instance_id = "my-instance"
  location    = var.region
  repositories = {
    my-repository = {
      branch_rules = {
        rule1 = {
          disabled                  = false
          include_pattern           = "main"
          require_pull_request      = true
          minimum_approvals_count   = 1
          minimum_reviews_count     = 1
          require_comments_resolved = true
          allow_stale_reviews       = false
          require_linear_history    = true
        }
      }
    }
  }
}
# tftest modules=1 resources=3 inventory=branch-protection-rules.yaml
```

### Initial Configuration

```hcl
module "ssm_instance" {
  source      = "./fabric/modules/secure-source-manager-instance"
  project_id  = var.project_id
  instance_id = "my-instance"
  location    = var.region
  repositories = {
    my-repository = {
      initial_config = {
        default_branch = "main"
        gitignores     = ["terraform.tfstate"]
      }
    }
  }
}
# tftest inventory=initial-config.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [instance_id](variables.tf#L36) | Instance ID. | <code>string</code> | ✓ |  |
| [location](variables.tf#L53) | Location. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L69) | Project ID. | <code>string</code> | ✓ |  |
| [repositories](variables.tf#L74) | Repositories. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [deletion_policy](variables.tf#L17) | Instance deletion policy, one of PREVENT, ABANDON, DELETE. | <code>string</code> |  | <code>null</code> |
| [iam](variables-iam.tf#L17) | IAM bindings. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L23) | IAM bindings. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L32) | IAM bindings. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [instance_create](variables.tf#L30) | Create SSM Instance. When set to false, uses instance_id to reference existing SSM instance. | <code>bool</code> |  | <code>true</code> |
| [kms_key](variables.tf#L41) | KMS key. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L47) | Instance labels. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [private_configs](variables.tf#L58) | The configurations for SSM private instances. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [http_service_attachment](outputs.tf#L17) | PSC service attachment for the instance HTTP endpoint. |  |
| [instance](outputs.tf#L25) | Instance. |  |
| [instance_id](outputs.tf#L30) | Instance id. |  |
| [repositories](outputs.tf#L35) | Repositories. |  |
| [repository_ids](outputs.tf#L40) | Repository ids. |  |
| [ssh_service_attachment](outputs.tf#L45) | PSC service attachment for the instance SSH endpoint. |  |
<!-- END TFDOC -->
