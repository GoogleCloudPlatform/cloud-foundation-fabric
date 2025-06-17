# Cloud Build Connection (V2) Module

This module allows to create a Cloud Build v2 connection with associated repositories and triggers linked to each of them. Additionaly it also familitates the creation of IAM bindings for the connection.

<!-- BEGIN TOC -->
- [Github](#github)
- [Github Enterprise](#github-enterprise)
- [Bitbucket Cloud](#bitbucket-cloud)
- [Bitbucket Data Center](#bitbucket-data-center)
- [Gitlab](#gitlab)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Github

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "my-project"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com"
  ]
  iam = {
    "roles/logging.logWriter" = [
      module.cb_service_account.iam_email
    ]
  }
}

module "cb_service_account" {
  source     = "./fabric/modules/iam-service-account"
  project_id = module.project.id
  name       = "cloudbuild"
}

module "secret_manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = module.project.id
  secrets = {
    authorizer-credential = {
      versions = {
        v1 = {
          data = "ENTER HERE YOUR SECRET VALUE"
          data_config = {
            write_only_version = 1
          }
        }
      }
      iam = {
        "roles/secretmanager.secretAccessor" = [module.project.service_agents.cloudbuild.iam_email]
      }
    }
  }
}

module "cb_connection" {
  source     = "./fabric/modules/cloud-build-v2-connection"
  project_id = module.project.id
  prefix     = var.prefix
  name       = "my-connection"
  location   = var.region
  context = {
    iam_principals = {
      mygroup = "group:${var.group_email}"
    }
  }
  connection_config = {
    github = {
      authorizer_credential_secret_version = module.secret_manager.version_ids["authorizer-credential/v1"]
      app_instalation_id                   = 1234567
    }
  }
  repositories = {
    my-repository = {
      remote_uri = "https://github.com/my-user/my-repo.git"
      triggers = {
        my-trigger = {
          push = {
            branch = "main"
          }
          filename = "cloudbuild.yaml"
        }
      }
    }
  }
  iam = {
    "roles/cloudbuild.connectionViewer" = ["$iam_principals:mygroup"]
  }
}
# tftest modules=4 resources=15 inventory=github.yaml skip-tofu
```

## Github Enterprise

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "my-project"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com"
  ]
  iam = {
    "roles/logging.logWriter" = [
      module.cb_service_account.iam_email
    ]
  }
}

module "cb_service_account" {
  source     = "./fabric/modules/iam-service-account"
  project_id = module.project.id
  name       = "cloudbuild"
}

module "secret_manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = module.project.id
  secrets = {
    webhook-secret = {
      versions = {
        v1 = {
          data = "ENTER HERE YOUR SECRET VALUE"
          data_config = {
            write_only_version = 1
          }
        }
      }
      iam = {
        "roles/secretmanager.secretAccessor" = [module.project.service_agents.cloudbuild.iam_email]
      }
    }
    private-key-secret = {
      versions = {
        v1 = {
          data = "ENTER HERE YOUR SECRET VALUE"
          data_config = {
            write_only_version = 1
          }
        }
      }
      iam = {
        "roles/secretmanager.secretAccessor" = [module.project.service_agents.cloudbuild.iam_email]
      }
    }
  }
}

module "cb_connection" {
  source     = "./fabric/modules/cloud-build-v2-connection"
  project_id = module.project.id
  prefix     = var.prefix
  name       = "my-connection"
  location   = var.region
  context = {
    iam_principals = {
      mygroup = "group:${var.group_email}"
    }
  }
  connection_config = {
    github_enterprise = {
      host_uri                      = "https://mmy-ghe-server.net."
      app_id                        = "1234567"
      app_installation_id           = "123456789"
      app_slug                      = "https://my-ghe-server.net/settings/apps/app-slug"
      private_key_secret_version    = module.secret_manager.version_ids["private-key-secret/v1"]
      webhook_secret_secret_version = module.secret_manager.version_ids["webhook-secret/v1"]
    }
  }
  repositories = {
    my-repository = {
      remote_uri = "https://github.com/my-user/my-repo.git"
      triggers = {
        my-trigger = {
          push = {
            branch = "main"
          }
          filename = "cloudbuild.yaml"
        }
      }
    }
  }
  iam = {
    "roles/cloudbuild.connectionViewer" = ["$iam_principals:mygroup"]
  }
}
# tftest modules=4 resources=18 inventory=github-enterprise.yaml skip-tofu
```

## Bitbucket Cloud

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "my-project"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com"
  ]
  iam = {
    "roles/logging.logWriter" = [
      module.cb_service_account.iam_email
    ]
  }
}

module "cb_service_account" {
  source     = "./fabric/modules/iam-service-account"
  project_id = module.project.id
  name       = "cloudbuild"
}

module "secret_manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = module.project.id
  secrets = {
    webhook-secret = {
      versions = {
        v1 = {
          data = "ENTER HERE YOUR SECRET VALUE"
          data_config = {
            write_only_version = 1
          }
        }
      }
      iam = {
        "roles/secretmanager.secretAccessor" = [module.project.service_agents.cloudbuild.iam_email]
      }
    }
    authorizer-credential = {
      versions = {
        v1 = {
          data = "ENTER HERE YOUR SECRET VALUE"
          data_config = {
            write_only_version = 1
          }
        }
      }
      iam = {
        "roles/secretmanager.secretAccessor" = [module.project.service_agents.cloudbuild.iam_email]
      }
    }
    read-authorizer-credential = {
      versions = {
        v1 = {
          data = "ENTER HERE YOUR SECRET VALUE"
          data_config = {
            write_only_version = 1
          }
        }
      }
      iam = {
        "roles/secretmanager.secretAccessor" = [module.project.service_agents.cloudbuild.iam_email]
      }
    }
  }
}

module "cb_connection" {
  source     = "./fabric/modules/cloud-build-v2-connection"
  project_id = module.project.id
  prefix     = var.prefix
  name       = "my-connection"
  location   = var.region
  context = {
    iam_principals = {
      mygroup = "group:${var.group_email}"
    }
  }
  connection_config = {
    bitbucket_cloud = {
      workspace                                 = "my-workspace"
      webhook_secret_secret_version             = module.secret_manager.version_ids["webhook-secret/v1"]
      authorizer_credential_secret_version      = module.secret_manager.version_ids["authorizer-credential/v1"]
      read_authorizer_credential_secret_version = module.secret_manager.version_ids["read-authorizer-credential/v1"]
      app_instalation_id                        = 1234567
    }
  }
  repositories = {
    my-repository = {
      remote_uri = "https://bitbucket.org/my-workspace/my-repository.git"
      triggers = {
        my-trigger = {
          push = {
            branch = "main"
          }
          filename = "cloudbuild.yaml"
        }
      }
    }
  }
  iam = {
    "roles/cloudbuild.connectionViewer" = ["$iam_principals:mygroup"]
  }
}
# tftest modules=4 resources=21 inventory=bitbucket-cloud.yaml skip-tofu
```

# Bitbucket Data Center

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "my-project"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com"
  ]
  iam = {
    "roles/logging.logWriter" = [
      module.cb_service_account.iam_email
    ]
  }
}

module "cb_service_account" {
  source     = "./fabric/modules/iam-service-account"
  project_id = module.project.id
  name       = "cloudbuild"
}

module "secret_manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = module.project.id
  secrets = {
    webhook-secret = {
      versions = {
        v1 = {
          data = "ENTER HERE YOUR SECRET VALUE"
          data_config = {
            write_only_version = 1
          }
        }
      }
      iam = {
        "roles/secretmanager.secretAccessor" = [module.project.service_agents.cloudbuild.iam_email]
      }
    }
    authorizer-credential = {
      versions = {
        v1 = {
          data = "ENTER HERE YOUR SECRET VALUE"
          data_config = {
            write_only_version = 1
          }
        }
      }
      iam = {
        "roles/secretmanager.secretAccessor" = [module.project.service_agents.cloudbuild.iam_email]
      }
    }
    read-authorizer-credential = {
      versions = {
        v1 = {
          data = "ENTER HERE YOUR SECRET VALUE"
          data_config = {
            write_only_version = 1
          }
        }
      }
      iam = {
        "roles/secretmanager.secretAccessor" = [module.project.service_agents.cloudbuild.iam_email]
      }
    }
  }
}

module "cb_connection" {
  source     = "./fabric/modules/cloud-build-v2-connection"
  project_id = module.project.id
  prefix     = var.prefix
  name       = "my-connection"
  location   = var.region
  context = {
    iam_principals = {
      mygroup = "group:${var.group_email}"
    }
  }
  connection_config = {
    bitbucket_data_center = {
      host_uri                                  = "https://bbdc-host.com"
      webhook_secret_secret_version             = module.secret_manager.version_ids["webhook-secret/v1"]
      authorizer_credential_secret_version      = module.secret_manager.version_ids["authorizer-credential/v1"]
      read_authorizer_credential_secret_version = module.secret_manager.version_ids["read-authorizer-credential/v1"]
      app_instalation_id                        = 1234567
    }
  }
  repositories = {
    my-repository = {
      remote_uri = "https://bbdc-host.com/scm/my-project/my-repository.git."
      triggers = {
        my-trigger = {
          push = {
            branch = "main"
          }
          filename = "cloudbuild.yaml"
        }
      }
    }
  }
  iam = {
    "roles/cloudbuild.connectionViewer" = ["$iam_principals:mygroup"]
  }
}
# tftest modules=4 resources=21 inventory=bitbucket-data-center.yaml skip-tofu
```

## Gitlab

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "my-project"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com"
  ]
  iam = {
    "roles/logging.logWriter" = [
      module.cb_service_account.iam_email
    ]
  }
}

module "cb_service_account" {
  source     = "./fabric/modules/iam-service-account"
  project_id = module.project.id
  name       = "cloudbuild"
}

module "secret_manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = module.project.id
  secrets = {
    webhook-secret = {
      versions = {
        v1 = {
          data = "ENTER HERE YOUR SECRET VALUE"
          data_config = {
            write_only_version = 1
          }
        }
      }
      iam = {
        "roles/secretmanager.secretAccessor" = [module.project.service_agents.cloudbuild.iam_email]
      }
    }
    read-authorizer-credential = {
      versions = {
        v1 = {
          data = "ENTER HERE YOUR SECRET VALUE"
          data_config = {
            write_only_version = 1
          }
        }
      }
      iam = {
        "roles/secretmanager.secretAccessor" = [module.project.service_agents.cloudbuild.iam_email]
      }
    }
    authorizer-credential = {
      versions = {
        v1 = {
          data = "ENTER HERE YOUR SECRET VALUE"
          data_config = {
            write_only_version = 1
          }
        }
      }
      iam = {
        "roles/secretmanager.secretAccessor" = [module.project.service_agents.cloudbuild.iam_email]
      }
    }
  }
}

module "cb_connection" {
  source     = "./fabric/modules/cloud-build-v2-connection"
  project_id = module.project.id
  prefix     = var.prefix
  name       = "my-connection"
  location   = var.region
  context = {
    iam_principals = {
      mygroup = "group:${var.group_email}"
    }
  }
  connection_config = {
    gitlab = {
      webhook_secret_secret_version             = module.secret_manager.version_ids["webhook-secret/v1"]
      read_authorizer_credential_secret_version = module.secret_manager.version_ids["read-authorizer-credential/v1"]
      authorizer_credential_secret_version      = module.secret_manager.version_ids["authorizer-credential/v1"]
    }
  }
  repositories = {
    my-repository = {
      remote_uri = "https://github.com/my-user/my-repo.git"
      triggers = {
        my-trigger = {
          push = {
            branch = "main"
          }
          filename = "cloudbuild.yaml"
        }
      }
    }
  }
  iam = {
    "roles/cloudbuild.connectionViewer" = ["$iam_principals:mygroup"]
  }
}
# tftest modules=4 resources=21 inventory=gitlab.yaml skip-tofu
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [location](variables.tf#L103) | Location. | <code>string</code> | ✓ |  |
| [name](variables.tf#L108) | Name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L123) | Project ID. | <code>string</code> | ✓ |  |
| [annotations](variables.tf#L17) | Annotations. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [connection_config](variables.tf#L23) | Connection configuration. | <code title="object&#40;&#123;&#10;  bitbucket_cloud &#61; optional&#40;object&#40;&#123;&#10;    app_installation_id                       &#61; optional&#40;string&#41;&#10;    authorizer_credential_secret_version      &#61; string&#10;    read_authorizer_credential_secret_version &#61; string&#10;    webhook_secret_secret_version             &#61; string&#10;    workspace                                 &#61; string&#10;  &#125;&#41;&#41;&#10;  bitbucket_data_center &#61; optional&#40;object&#40;&#123;&#10;    authorizer_credential_secret_version      &#61; string&#10;    host_uri                                  &#61; string&#10;    read_authorizer_credential_secret_version &#61; string&#10;    service                                   &#61; optional&#40;string&#41;&#10;    ssl_ca                                    &#61; optional&#40;string&#41;&#10;    webhook_secret_secret_version             &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  github &#61; optional&#40;object&#40;&#123;&#10;    app_installation_id                  &#61; optional&#40;string&#41;&#10;    authorizer_credential_secret_version &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  github_enterprise &#61; optional&#40;object&#40;&#123;&#10;    app_id                        &#61; optional&#40;string&#41;&#10;    app_installation_id           &#61; optional&#40;string&#41;&#10;    app_slug                      &#61; optional&#40;string&#41;&#10;    host_uri                      &#61; string&#10;    private_key_secret_version    &#61; optional&#40;string&#41;&#10;    service                       &#61; optional&#40;string&#41;&#10;    ssl_ca                        &#61; optional&#40;string&#41;&#10;    webhook_secret_secret_version &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  gitlab &#61; optional&#40;object&#40;&#123;&#10;    host_uri                                  &#61; optional&#40;string&#41;&#10;    webhook_secret_secret_version             &#61; string&#10;    read_authorizer_credential_secret_version &#61; string&#10;    authorizer_credential_secret_version      &#61; string&#10;    service                                   &#61; optional&#40;string&#41;&#10;    ssl_ca                                    &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [connection_create](variables.tf#L78) | Create connection. | <code>bool</code> |  | <code>true</code> |
| [context](variables.tf#L85) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  custom_roles   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [disabled](variables.tf#L97) | Flag indicating whether the connection is disabled or not. | <code>bool</code> |  | <code>false</code> |
| [iam](variables-iam.tf#L17) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L23) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L38) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L53) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L113) | Prefix. | <code>string</code> |  | <code>null</code> |
| [repositories](variables.tf#L128) | Repositories. | <code title="map&#40;object&#40;&#123;&#10;  remote_uri  &#61; string&#10;  annotations &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  triggers &#61; optional&#40;map&#40;object&#40;&#123;&#10;    approval_required &#61; optional&#40;bool, false&#41;&#10;    description       &#61; optional&#40;string&#41;&#10;    pull_request &#61; optional&#40;object&#40;&#123;&#10;      branch          &#61; optional&#40;string&#41;&#10;      invert_regex    &#61; optional&#40;string&#41;&#10;      comment_control &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    push &#61; optional&#40;object&#40;&#123;&#10;      branch       &#61; optional&#40;string&#41;&#10;      invert_regex &#61; optional&#40;string&#41;&#10;      tag          &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    disabled           &#61; optional&#40;bool, false&#41;&#10;    filename           &#61; string&#10;    include_build_logs &#61; optional&#40;string&#41;&#10;    substitutions      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    service_account    &#61; optional&#40;string&#41;&#10;    tags               &#61; optional&#40;map&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Connection id. |  |
| [repositories](outputs.tf#L24) | Repositories. |  |
| [repository_ids](outputs.tf#L29) | Repository ids. |  |
| [trigger_ids](outputs.tf#L34) | Trigger ids. |  |
| [triggers](outputs.tf#L39) | Triggers. |  |
<!-- END TFDOC -->
