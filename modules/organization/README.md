# Organization Module

This module allows managing several organization properties:

- IAM bindings, both authoritative and additive
- custom IAM roles
- audit logging configuration for services
- organization policies
- organization policy custom constraints
- Security Command Center custom modules

To manage organization policies, the `orgpolicy.googleapis.com` service should be enabled in the quota project.

## TOC

<!-- BEGIN TOC -->
- [TOC](#toc)
- [Example](#example)
- [IAM](#iam)
  - [Conditional IAM by Principals](#conditional-iam-by-principals)
- [Organization Policies](#organization-policies)
  - [Organization Policy Factory](#organization-policy-factory)
  - [Organization Policy Custom Constraints](#organization-policy-custom-constraints)
  - [Organization Policy Custom Constraints Factory](#organization-policy-custom-constraints-factory)
- [Privileged Access Manager (PAM) Entitlements](#privileged-access-manager-pam-entitlements)
  - [Privileged Access Manager (PAM) Entitlements Factory](#privileged-access-manager-pam-entitlements-factory)
- [Hierarchical Firewall Policy Attachments](#hierarchical-firewall-policy-attachments)
- [Log Sinks](#log-sinks)
- [Data Access Logs](#data-access-logs)
- [Custom Roles](#custom-roles)
  - [Custom Roles Factory](#custom-roles-factory)
- [Custom Security Health Analytics Modules](#custom-security-health-analytics-modules)
  - [Custom Security Health Analytics Modules Factory](#custom-security-health-analytics-modules-factory)
- [Security Command Center Mute Configs](#security-command-center-mute-configs)
  - [Security Command Center Mute Configs Factory](#security-command-center-mute-configs-factory)
- [Cloud Asset Search](#cloud-asset-search)
- [Cloud Asset Inventory Feeds](#cloud-asset-inventory-feeds)
- [Tags](#tags)
  - [Tags Factory](#tags-factory)
- [Workforce Identity](#workforce-identity)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Example

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  iam_by_principals = {
    "group:${var.group_email}" = ["roles/owner"]
  }
  iam = {
    "roles/resourcemanager.projectCreator" = ["group:${var.group_email}"]
  }
  iam_bindings_additive = {
    am1-storage-admin = {
      member = "group:${var.group_email}"
      role   = "roles/storage.admin"
    }
  }
  tags = {
    allowexternal = {
      description = "Allow external identities."
      values = {
        true = {}, false = {}
      }
    }
  }
  org_policies = {
    "compute.disableGuestAttributesAccess" = {
      rules = [{ enforce = true }]
    }
    "compute.skipDefaultNetworkCreation" = {
      rules = [{ enforce = true }]
    }
    "iam.disableServiceAccountKeyCreation" = {
      rules = [{ enforce = true }]
    }
    "iam.disableServiceAccountKeyUpload" = {
      rules = [
        {
          condition = {
            expression  = "resource.matchTagId('tagKeys/1234', 'tagValues/1234')"
            title       = "condition"
            description = "test condition"
            location    = "somewhere"
          }
          enforce = true
        },
        {
          enforce = false
        }
      ]
    }
    "iam.allowedPolicyMemberDomains" = {
      rules = [
        {
          allow = { all = true }
          condition = {
            expression  = "resource.matchTag('1234567890/allowexternal', 'true')"
            title       = "Allow external identities"
            description = "Allow external identities when resource has the `allowexternal` tag set to true."
          }
        },
        {
          allow = { values = ["C0xxxxxxx", "C0yyyyyyy"] }
          condition = {
            expression  = "!resource.matchTag('1234567890/allowexternal', 'true')"
            title       = ""
            description = "For any resource without allowexternal=true, only allow identities from restricted domains."
          }
        }
      ]
    }
    "compute.trustedImageProjects" = {
      rules = [{
        allow = {
          values = ["projects/my-project"]
        }
      }]
    }
    "compute.vmExternalIpAccess" = {
      rules = [{ deny = { all = true } }]
    }
  }
}
# tftest modules=1 resources=13 inventory=basic.yaml e2e serial
```

## IAM

IAM is managed via several variables that implement different features and levels of control:

- `iam` and `iam_by_principals` configure authoritative bindings that manage individual roles exclusively, and are internally merged
- `iam_bindings` configure authoritative bindings with optional support for conditions, and are not internally merged with the previous two variables
- `iam_bindings_additive` configure additive bindings via individual role/member pairs with optional support for conditions
- `iam_by_principals_additive` configure additive bindings via individual principal/role pairs with optional support for conditions, and is internally merged with the previous variable

The authoritative and additive approaches can be used together, provided different roles are managed by each. Some care must also be taken with the `iam_by_principals` variable to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

IAM also supports variable interpolation for both roles and principals, via the respective attributes in the `var.context` variable. Refer to the [project module](../project/README.md#iam) for examples of the IAM interface.

### Conditional IAM by Principals

The `iam_by_principals_conditional` variable allows defining IAM bindings keyed by principal, where each principal shares a common condition for multiple roles. This is useful for granting access with specific conditions (e.g., time-based or resource-based) to users or groups across different roles.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  iam_by_principals_conditional = {
    "user:one@example.com" = {
      roles = ["roles/owner", "roles/viewer"]
      condition = {
        title       = "expires_after_2024_12_31"
        description = "Expiring at midnight of 2024-12-31"
        expression  = "request.time < timestamp(\"2025-01-01T00:00:00Z\")"
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=iam-bpc.yaml
```

## Organization Policies

### Organization Policy Factory

See the [organization policy factory in the project module](../project/README.md#organization-policy-factory).

### Organization Policy Custom Constraints

Refer to the [Creating and managing custom constraints](https://cloud.google.com/resource-manager/docs/organization-policy/creating-managing-custom-constraints) documentation for details on usage.
To manage organization policy custom constraints, the `orgpolicy.googleapis.com` service should be enabled in the quota project.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  org_policy_custom_constraints = {
    "custom.gkeEnableAutoUpgrade" = {
      resource_types = ["container.googleapis.com/NodePool"]
      method_types   = ["CREATE"]
      condition      = "resource.management.autoUpgrade == true"
      action_type    = "ALLOW"
      display_name   = "Enable node auto-upgrade"
      description    = "All node pools must have node auto-upgrade enabled."
    }
  }
  # not necessarily to enforce on the org level, policy may be applied on folder/project levels
  org_policies = {
    "custom.gkeEnableAutoUpgrade" = {
      rules = [{ enforce = true }]
    }
  }
}
# tftest modules=1 resources=2 inventory=custom-constraints.yaml
```

You can use the `id` or `custom_constraint_ids` outputs to prevent race conditions between the creation of a custom constraint and an organization policy using that constraint. Both of these outputs depend on the actual constraint, which would make any resource referring to them to wait for the creation of the constraint.

### Organization Policy Custom Constraints Factory

Org policy custom constraints can be loaded from a directory containing YAML files where each file defines one or more custom constraints. The structure of the YAML files is exactly the same as the `org_policy_custom_constraints` variable.

The example below deploys a few org policy custom constraints split between two YAML files.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  factories_config = {
    org_policy_custom_constraints = "configs/custom-constraints"
  }
  org_policies = {
    "custom.gkeEnableAutoUpgrade" = {
      rules = [{ enforce = true }]
    }
  }
}
# tftest modules=1 resources=3 files=gke inventory=custom-constraints.yaml
```

```yaml
custom.gkeEnableLogging:
  resource_types:
  - container.googleapis.com/Cluster
  method_types:
  - CREATE
  - UPDATE
  condition: resource.loggingService == "none"
  action_type: DENY
  display_name: Do not disable Cloud Logging
custom.gkeEnableAutoUpgrade:
  resource_types:
  - container.googleapis.com/NodePool
  method_types:
  - CREATE
  condition: resource.management.autoUpgrade == true
  action_type: ALLOW
  display_name: Enable node auto-upgrade
  description: All node pools must have node auto-upgrade enabled.

# tftest-file id=gke path=configs/custom-constraints/gke.yaml
```

```yaml
custom.dataprocNoMoreThan10Workers:
  resource_types:
  - dataproc.googleapis.com/Cluster
  method_types:
  - CREATE
  - UPDATE
  condition: resource.config.workerConfig.numInstances + resource.config.secondaryWorkerConfig.numInstances > 10
  action_type: DENY
  display_name: Total number of worker instances cannot be larger than 10
  description: Cluster cannot have more than 10 workers, including primary and secondary workers.

# tftest-file id=dataproc path=configs/custom-constraints/dataproc.yaml
```

## Privileged Access Manager (PAM) Entitlements

[Privileged Access Manager](https://docs.cloud.google.com/iam/docs/pam-overview) entitlements can be defined via the `pam_entitlements` variable.

Note that using PAM entitlements requires specific roles to be granted to the users and groups that will be using them. For more information, see the [official documentation](https://cloud.google.com/iam/docs/pam-permissions-and-setup#before-you-begin).

Additionally, the Privileged Access Manager Service Agent must be created and granted the `roles/privilegedaccessmanager.organizationServiceAgent` role. The service agent is not created automatically, and you can find the `gcloud` command to create it in the `service_agents` output of this module. For more information on service agents, see the [official documentation](https://cloud.google.com/iam/docs/service-agents).

The following example shows how to grant the required role to the PAM service agent:

```hcl
module "organization" {
  source          = "./fabric/modules/organization"
  organization_id = var.org_id
  factories_config = {
    pam_entitlements = "factory/"
  }
  iam = {
    "roles/privilegedaccessmanager.serviceAgent" = [
      module.organization.service_agents.pam.iam_email
    ]
  }
}
```

```hcl
module "org" {
  source              = "./fabric/modules/organization"
  organization_id     = var.organization_id
  pam_entitlements = {
    net-admins = {
      max_request_duration = "3600s"
      manual_approvals = {
        require_approver_justification = true
        steps = [{
          approvers = ["group:gcp-organization-admins@example.com"]
        }]
      }
      eligible_users = ["group:gcp-network-admins@example.com"]
      privileged_access = [
        { role = "roles/compute.networkAdmin" },
        { role = "roles/compute.admin" }
      ]
    }
  }
}
```

### Privileged Access Manager (PAM) Entitlements Factory

PAM entitlements can be loaded from a directory containing YAML files where each file defines one or more entitlements. The structure of the YAML files is exactly the same as the `pam_entitlements` variable.

Note that entitlements defined via `pam_entitlements` take precedence over those in the factory. In other words, if you specify the same entitlement in a YAML file and in the `pam_entitlements` variable, the latter will take priority.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  factories_config = {
    pam_entitlements = "configs/pam-entitlements/"
  }
}
```

## Hierarchical Firewall Policy Attachments

Hierarchical firewall policies can be managed via the [`net-firewall-policy`](../net-firewall-policy/) module, including support for factories. Once a policy is available, attaching it to the organization can be done either in the firewall policy module itself, or here:

```hcl
module "firewall-policy" {
  source    = "./fabric/modules/net-firewall-policy"
  name      = "test-1"
  parent_id = var.organization_id
  # attachment via the firewall policy module
  # attachments = {
  #   org = var.organization_id
  # }
}

module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  # attachment via the organization module
  firewall_policy = {
    name   = "test-1"
    policy = module.firewall-policy.id
  }
}
# tftest modules=2 resources=2 e2e serial
```

## Log Sinks

The following example shows how to define organization-level log sinks, which support interpolation in the destination argument.

```hcl
module "gcs" {
  source        = "./fabric/modules/gcs"
  project_id    = var.project_id
  prefix        = var.prefix
  name          = "gcs_sink"
  location      = "EU"
  force_destroy = true
}

module "dataset" {
  source     = "./fabric/modules/bigquery-dataset"
  project_id = var.project_id
  id         = "bq_sink"
}

module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "pubsub_sink"
}

module "bucket" {
  source = "./fabric/modules/logging-bucket"
  parent = var.project_id
  name   = "${var.prefix}-bucket"
}

module "destination-project" {
  source          = "./fabric/modules/project"
  name            = "dest-prj"
  billing_account = var.billing_account_id
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "logging.googleapis.com"
  ]
}

module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  context = {
    storage_buckets = {
      my_bucket = "test-prod-log-audit-0"
    }
  }
  logging_sinks = {
    audit = {
      destination = "$storage_buckets:my_bucket"
      filter      = "log_id('cloudaudit.googleapis.com/activity')"
      type        = "storage"
    }
    warnings = {
      destination = module.gcs.id
      filter      = "severity=WARNING"
      type        = "storage"
    }
    info = {
      bq_partitioned_table = true
      destination          = module.dataset.id
      filter               = "severity=INFO"
      type                 = "bigquery"
    }
    notice = {
      destination = module.pubsub.id
      filter      = "severity=NOTICE"
      type        = "pubsub"
    }
    debug = {
      destination = module.bucket.id
      filter      = "severity=DEBUG"
      exclusions = {
        no-compute = "logName:compute"
      }
      type = "logging"
    }
    alert = {
      destination = module.destination-project.id
      filter      = "severity=ALERT"
      type        = "project"
    }
  }
  logging_exclusions = {
    no-gce-instances = "resource.type=gce_instance"
  }
}
# tftest inventory=logging.yaml
```

## Data Access Logs

Activation of data access logs can be controlled via the `logging_data_access` variable.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  logging_data_access = {
    allServices = {
      ADMIN_READ = {
        exempted_members = ["group:${var.group_email}"]
      }
    }
    "storage.googleapis.com" = {
      DATA_READ  = {}
      DATA_WRITE = {}
    }
  }
}
# tftest modules=1 resources=2 inventory=logging-data-access.yaml e2e serial
```

## Custom Roles

Custom roles can be defined via the `custom_roles` variable, and referenced via the `custom_role_id` output (this also provides explicit dependency on the custom role):

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  custom_roles = {
    "myRole${replace(var.prefix, "/[^a-zA-Z0-9_\\.]/", "")}" = [
      "compute.instances.list",
    ]
  }
  iam = {
    (module.org.custom_role_id["myRole${replace(var.prefix, "/[^a-zA-Z0-9_\\.]/", "")}"]) = ["group:${var.group_email}"]
  }
}
# tftest modules=1 resources=2 inventory=roles.yaml e2e serial
```

### Custom Roles Factory

Custom roles can also be specified via a factory in a similar way to organization policies and policy constraints. Each file is mapped to a custom role, where

- the role name defaults to the file name but can be overridden via a `name` attribute in the yaml
- role permissions are defined in an `includedPermissions` map

Custom roles defined via the variable are merged with those coming from the factory, and override them in case of duplicate names.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  factories_config = {
    custom_roles = "data/custom_roles"
  }
}
# tftest modules=1 resources=2 files=custom-role-1,custom-role-2 inventory=custom-roles.yaml
```

```yaml
# tftest-file id=custom-role-1 path=data/custom_roles/test_1.yaml

includedPermissions:
 - compute.globalOperations.get
```

```yaml
# tftest-file id=custom-role-2 path=data/custom_roles/test_2.yaml

name: projectViewer
includedPermissions:
  - resourcemanager.projects.get
  - resourcemanager.projects.getIamPolicy
  - resourcemanager.projects.list
```

## Custom Security Health Analytics Modules

[Security Health Analytics custom modules](https://cloud.google.com/security-command-center/docs/custom-modules-sha-create) can be defined via the `scc_sha_custom_modules` variable:

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  scc_sha_custom_modules = {
    cloudkmKeyRotationPeriod = {
      description    = "The rotation period of the identified cryptokey resource exceeds 30 days."
      recommendation = "Set the rotation period to at most 30 days."
      severity       = "MEDIUM"
      predicate = {
        expression = "resource.rotationPeriod > duration(\"2592000s\")"
      }
      resource_selector = {
        resource_types = ["cloudkms.googleapis.com/CryptoKey"]
      }
    }
  }
}
# tftest modules=1 resources=1 inventory=custom-modules-sha.yaml
```

### Custom Security Health Analytics Modules Factory

Custom modules can also be specified via a factory. Each file is mapped to a custom module, where the module name defaults to the file name.

Custom modules defined via the variable are merged with those coming from the factory, and override them in case of duplicate names.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  factories_config = {
    scc_sha_custom_modules = "data/scc_sha_custom_modules"
  }
}
# tftest modules=1 resources=1 files=custom-module-sha-1 inventory=custom-modules-sha.yaml
```

```yaml
# tftest-file id=custom-module-sha-1 path=data/scc_sha_custom_modules/cloudkmKeyRotationPeriod.yaml schema=scc-sha-custom-modules.schema.json
cloudkmKeyRotationPeriod:
  description: "The rotation period of the identified cryptokey resource exceeds 30 days."
  recommendation: "Set the rotation period to at most 30 days."
  severity: "MEDIUM"
  predicate:
    expression: "resource.rotationPeriod > duration(\"2592000s\")"
  resource_selector:
    resource_types:
    - "cloudkms.googleapis.com/CryptoKey"
```

## Security Command Center Mute Configs

[Security Command Center Mute Configs](https://cloud.google.com/security-command-center/docs/how-to-mute-findings) can be defined via the `scc_mute_configs` variable:

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  scc_mute_configs = {
    muteHighSeverity = {
      description = "Mute high severity findings"
      filter      = "severity=\"HIGH\""
      type        = "DYNAMIC"
    }
  }
}
# tftest modules=1 resources=1 inventory=scc-mute-configs.yaml
```

### Security Command Center Mute Configs Factory

Mute configs can also be specified via a factory. Each file is mapped to a mute config, where the config ID defaults to the file name.

Mute configs defined via the variable are merged with those coming from the factory, and override them in case of duplicate names.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  factories_config = {
    scc_mute_configs = "data/scc_mute_configs"
  }
}
# tftest modules=1 resources=1 files=mute-config-1 inventory=scc-mute-configs.yaml
```

```yaml
# tftest-file id=mute-config-1 path=data/scc_mute_configs/mute-high-severity.yaml schema=scc-mute-config.schema.json
muteHighSeverity:
  description: "Mute high severity findings"
  filter: "severity=\"HIGH\""
  type: "DYNAMIC"
```

## Cloud Asset Search

The Cloud Asset Search feature allows you to search for resources within the organization using the Cloud Asset Inventory API. This is useful for discovering and auditing resources based on asset types and query filters.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  asset_search = {
    org-policies = {
      asset_types = ["orgpolicy.googleapis.com/Policy"]
    }
  }
}

output "org_policies" {
  value = module.org.asset_search_results["org-policies"]
}
# tftest skip
```

## Cloud Asset Inventory Feeds

Cloud Asset Inventory feeds allow you to monitor asset changes in real-time by publishing notifications to a Pub/Sub topic. Feeds configured at the organization level will monitor all resources within the organization.

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "org-asset-feed"
}

module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  asset_feeds = {
    security-monitoring = {
      billing_project = var.project_id
      feed_output_config = {
        pubsub_destination = {
          topic = module.pubsub.id
        }
      }
      content_type = "IAM_POLICY"
    }
  }
}
# tftest inventory=feeds.yaml
```

## Tags

Refer to the [Creating and managing tags](https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing) documentation for details on usage.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  tags = {
    environment = {
      description = "Environment specification."
      iam = {
        "roles/resourcemanager.tagAdmin" = ["group:${var.group_email}"]
      }
      iam_bindings = {
        viewer = {
          role    = "roles/resourcemanager.tagViewer"
          members = ["group:gcp-support@example.org"]
        }
      }
      iam_bindings_additive = {
        user_app1 = {
          role   = "roles/resourcemanager.tagUser"
          member = "group:app1-team@example.org"
        }
      }
      values = {
        dev = {
          iam_bindings_additive = {
            user_app2 = {
              role   = "roles/resourcemanager.tagUser"
              member = "group:app2-team@example.org"
            }
          }
        }
        prod = {
          description = "Environment: production."
          iam = {
            "roles/resourcemanager.tagViewer" = ["group:app1-team@example.org"]
          }
          iam_bindings = {
            admin = {
              role    = "roles/resourcemanager.tagAdmin"
              members = ["group:gcp-support@example.org"]
              condition = {
                title      = "gcp_support"
                expression = <<-END
                  request.time.getHours("Europe/Berlin") <= 9 &&
                  request.time.getHours("Europe/Berlin") >= 17
                END
              }
            }
          }
        }
      }
    }
  }
  tag_bindings = {
    env-prod = module.org.tag_values["environment/prod"].id
  }
}
# tftest modules=1 resources=10 inventory=tags.yaml
```

You can also define network tags, through a dedicated variable *network_tags*:

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  network_tags = {
    net-environment = {
      description = "This is a network tag."
      network     = "${var.project_id}/${var.vpc.name}"
      iam = {
        "roles/resourcemanager.tagAdmin" = ["group:${var.group_email}"]
      }
      values = {
        dev = {}
        prod = {
          description = "Environment: production."
          iam = {
            "roles/resourcemanager.tagUser" = ["group:${var.group_email}"]
          }
        }
      }
    }
  }
}
# tftest modules=1 resources=5 inventory=network-tags.yaml e2e serial
```

### Tags Factory

Tags can also be specified via a factory in a similar way to organization policies and policy constraints. Each file is mapped to tag key, where

- the key name defaults to the file name but can be overridden via a `name` attribute in the yaml
- The structure of the YAML file allows defining the `description`, `iam` bindings, and a map of `values` for the tag key, including their own descriptions and IAM.
- Tags defined via the `tags` and `network_tags` variables are merged with those from the factory, and will override factory definitions in case of duplicate names.

The example below deploys a `cost-center` tag key and its values from a YAML file. Context expansion supports interpolation via the `context.tag_keys` and `context.tag_values` variables, as shown below.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  context = {
    tag_keys = {
      environment = "tagKeys/1234567890"
    }
    tag_values = {
      "environment/production" = "tagValues/1234567890"
    }
  }
  factories_config = {
    tags = "data/tags"
  }
}
# tftest modules=1 resources=7 files=0,1 inventory=tags-factory.yaml
```

```yaml
# tftest-file id=0 path=data/tags/cost-center.yaml

description: "Tag for internal cost allocation."
iam:
  "roles/resourcemanager.tagViewer":
    - "group:finance-team@example.com"
values:
  engineering:
    description: "Engineering department."
  marketing:
    description: "Marketing department."
```

```yaml
# tftest-file id=1 path=data/tags/environment.yaml

id: $tag_keys:environment
iam:
  "roles/resourcemanager.tagViewer":
    - "group:gcp-devops@example.com"
values:
  development:
    description: "Development."
  production:
    id: $tag_values:environment/production
    iam:
      "roles/resourcemanager.tagUser":
        - "group:gcp-devops@example.com"

```

## Workforce Identity

A Workforce Identity pool and providers can be created via the `workforce_identity_config` variable.

Auto-population of provider attributes is supported via the `attribute_mapping_template` provider attribute. Currently only `azuread` and `okta` are supported.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  workforce_identity_config = {
    # optional, defaults to 'default'
    pool_name = "test-pool"
    providers = {
      saml-basic = {
        attribute_mapping_template = "azuread"
        identity_provider = {
          saml = {
            idp_metadata_xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>..."
          }
        }
      }
      saml-full = {
        attribute_mapping = {
          "google.subject" = "assertion.sub"
        }
        identity_provider = {
          saml = {
            idp_metadata_xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>..."
          }
        }
        oauth2_client_config = {
          extra_attributes = {
            issuer_uri      = "https://login.microsoftonline.com/abcdef/v2.0"
            client_id       = "client-id"
            client_secret   = "client-secret"
            attributes_type = "AZURE_AD_GROUPS_ID"
            query_filter    = "mail:gcp"
          }
        }
      }
      oidc-full = {
        attribute_mapping = {
          "google.subject" = "assertion.sub"
        }
        identity_provider = {
          oidc = {
            issuer_uri    = "https://sts.windows.net/abcd01234/"
            client_id     = "https://analysis.windows.net/powerbi/connector/GoogleBigQuery"
            client_secret = "client-secret"
            web_sso_config = {
              response_type             = "CODE"
              assertion_claims_behavior = "MERGE_USER_INFO_OVER_ID_TOKEN_CLAIMS"
            }
          }
        }
        oauth2_client_config = {
          extra_attributes = {
            issuer_uri      = "https://login.microsoftonline.com/abcd01234/v2.0"
            client_id       = "client-id"
            client_secret   = "client-secret"
            attributes_type = "AZURE_AD_GROUPS_MAIL"
          }
        }
      }
    }
  }
}
# tftest modules=1 resources=4 inventory=wfif.yaml
```

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | resources |
|---|---|---|
| [assets.tf](./assets.tf) | None | <code>google_cloud_asset_organization_feed</code> |
| [iam.tf](./iam.tf) | IAM bindings. | <code>google_organization_iam_binding</code> · <code>google_organization_iam_custom_role</code> · <code>google_organization_iam_member</code> |
| [identity-providers.tf](./identity-providers.tf) | Workforce Identity Federation provider definitions. | <code>google_iam_workforce_pool</code> · <code>google_iam_workforce_pool_provider</code> |
| [logging.tf](./logging.tf) | Log sinks and data access logs. | <code>google_bigquery_dataset_iam_member</code> · <code>google_logging_organization_exclusion</code> · <code>google_logging_organization_settings</code> · <code>google_logging_organization_sink</code> · <code>google_organization_iam_audit_config</code> · <code>google_project_iam_member</code> · <code>google_pubsub_topic_iam_member</code> · <code>google_storage_bucket_iam_member</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_compute_firewall_policy_association</code> · <code>google_essential_contacts_contact</code> |
| [org-policy-custom-constraints.tf](./org-policy-custom-constraints.tf) | None | <code>google_org_policy_custom_constraint</code> |
| [organization-policies.tf](./organization-policies.tf) | Organization-level organization policies. | <code>google_org_policy_policy</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [pam.tf](./pam.tf) | None | <code>google_privileged_access_manager_entitlement</code> |
| [scc-mute-configs.tf](./scc-mute-configs.tf) | Organization-level SCC mute configurations. | <code>google_scc_v2_organization_mute_config</code> |
| [scc-sha-custom-modules.tf](./scc-sha-custom-modules.tf) | Organization-level Custom modules with Security Health Analytics. | <code>google_scc_management_organization_security_health_analytics_custom_module</code> |
| [service-agents.tf](./service-agents.tf) | Service agents supporting resources. |  |
| [tags.tf](./tags.tf) | Manages GCP Secure Tags, keys, values, and IAM. | <code>google_tags_tag_binding</code> · <code>google_tags_tag_key</code> · <code>google_tags_tag_key_iam_binding</code> · <code>google_tags_tag_key_iam_member</code> · <code>google_tags_tag_value</code> · <code>google_tags_tag_value_iam_binding</code> · <code>google_tags_tag_value_iam_member</code> |
| [variables-iam.tf](./variables-iam.tf) | None |  |
| [variables-identity-providers.tf](./variables-identity-providers.tf) | None |  |
| [variables-logging.tf](./variables-logging.tf) | None |  |
| [variables-pam.tf](./variables-pam.tf) | None |  |
| [variables-scc.tf](./variables-scc.tf) | None |  |
| [variables-tags.tf](./variables-tags.tf) | None |  |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [organization_id](variables.tf#L172) | Organization id in organizations/nnnnnn format. | <code>string</code> | ✓ |  |
| [asset_feeds](variables.tf#L18) | Cloud Asset Inventory feeds. | <code title="map&#40;object&#40;&#123;&#10;  billing_project &#61; string&#10;  content_type    &#61; optional&#40;string&#41;&#10;  asset_types     &#61; optional&#40;list&#40;string&#41;&#41;&#10;  asset_names     &#61; optional&#40;list&#40;string&#41;&#41;&#10;  feed_output_config &#61; object&#40;&#123;&#10;    pubsub_destination &#61; object&#40;&#123;&#10;      topic &#61; string&#10;    &#125;&#41;&#10;  &#125;&#41;&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; optional&#40;string&#41;&#10;    description &#61; optional&#40;string&#41;&#10;    location    &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [asset_search](variables.tf#L51) | Cloud Asset Inventory search configurations. | <code title="map&#40;object&#40;&#123;&#10;  asset_types &#61; list&#40;string&#41;&#10;  query       &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [contacts](variables.tf#L61) | List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L79) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  bigquery_datasets &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  condition_vars    &#61; optional&#40;map&#40;map&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  custom_roles      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  email_addresses   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations         &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  log_buckets       &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids       &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  pubsub_topics     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  storage_buckets   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_keys          &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_values        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [custom_roles](variables.tf#L99) | Map of role name => list of permissions to create in this project. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [factories_config](variables.tf#L106) | Paths to data files and folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  custom_roles                  &#61; optional&#40;string&#41;&#10;  org_policies                  &#61; optional&#40;string&#41;&#10;  org_policy_custom_constraints &#61; optional&#40;string&#41;&#10;  pam_entitlements              &#61; optional&#40;string&#41;&#10;  scc_mute_configs              &#61; optional&#40;string&#41;&#10;  scc_sha_custom_modules        &#61; optional&#40;string&#41;&#10;  tags                          &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [firewall_policy](variables.tf#L121) | Hierarchical firewall policies to associate to the organization. | <code title="object&#40;&#123;&#10;  name   &#61; string&#10;  policy &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [iam](variables-iam.tf#L17) | Authoritative IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L24) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L39) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L61) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals_additive](variables-iam.tf#L54) | Additive IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid errors. Merged internally with the `iam_bindings_additive` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals_conditional](variables-iam.tf#L68) | Authoritative IAM binding in {PRINCIPAL => {roles = [roles], condition = {cond}}} format. Principals need to be statically defined to avoid errors. Condition is required. | <code title="map&#40;object&#40;&#123;&#10;  roles &#61; list&#40;string&#41;&#10;  condition &#61; object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_data_access](variables-logging.tf#L17) | Control activation of data access logs. The special 'allServices' key denotes configuration for all services. | <code title="map&#40;object&#40;&#123;&#10;  ADMIN_READ &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41; &#125;&#41;&#41;,&#10;  DATA_READ  &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41; &#125;&#41;&#41;,&#10;  DATA_WRITE &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41; &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_exclusions](variables-logging.tf#L28) | Logging exclusions for this organization in the form {NAME -> FILTER}. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_settings](variables-logging.tf#L35) | Default settings for logging resources. | <code title="object&#40;&#123;&#10;  disable_default_sink &#61; optional&#40;bool&#41;&#10;  kms_key_name         &#61; optional&#40;string&#41;&#10;  storage_location     &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [logging_sinks](variables-logging.tf#L46) | Logging sinks to create for the organization. | <code title="map&#40;object&#40;&#123;&#10;  destination          &#61; string&#10;  bq_partitioned_table &#61; optional&#40;bool, false&#41;&#10;  description          &#61; optional&#40;string&#41;&#10;  disabled             &#61; optional&#40;bool, false&#41;&#10;  exclusions           &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  filter               &#61; optional&#40;string&#41;&#10;  iam                  &#61; optional&#40;bool, true&#41;&#10;  include_children     &#61; optional&#40;bool, true&#41;&#10;  intercept_children   &#61; optional&#40;bool, false&#41;&#10;  type                 &#61; optional&#40;string, &#34;logging&#34;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [network_tags](variables-tags.tf#L17) | Network tags by key name. If `id` is provided, key creation is skipped. The `iam` attribute behaves like the similarly named one at module level. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string, &#34;Managed by the Terraform organization module.&#34;&#41;&#10;  id          &#61; optional&#40;string&#41;&#10;  network     &#61; string &#35; project_id&#47;vpc_name or &#34;ALL&#34; to toggle GCE_FIREWALL purpose&#10;  iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  values &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description &#61; optional&#40;string, &#34;Managed by the Terraform organization module.&#34;&#41;&#10;    id          &#61; optional&#40;string&#41;&#10;    iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;      members &#61; list&#40;string&#41;&#10;      role    &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;      member &#61; string&#10;      role   &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [org_policies](variables.tf#L130) | Organization policies applied to this organization keyed by policy name. | <code title="map&#40;object&#40;&#123;&#10;  inherit_from_parent &#61; optional&#40;bool&#41; &#35; for list policies only.&#10;  reset               &#61; optional&#40;bool&#41;&#10;  rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;    allow &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    deny &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    enforce &#61; optional&#40;bool&#41; &#35; for boolean policies only.&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      description &#61; optional&#40;string&#41;&#10;      expression  &#61; optional&#40;string&#41;&#10;      location    &#61; optional&#40;string&#41;&#10;      title       &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    parameters &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [org_policy_custom_constraints](variables.tf#L158) | Organization policy custom constraints keyed by constraint name. | <code title="map&#40;object&#40;&#123;&#10;  display_name   &#61; optional&#40;string&#41;&#10;  description    &#61; optional&#40;string&#41;&#10;  action_type    &#61; string&#10;  condition      &#61; string&#10;  method_types   &#61; list&#40;string&#41;&#10;  resource_types &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [pam_entitlements](variables-pam.tf#L17) | Privileged Access Manager entitlements for this resource, keyed by entitlement ID. | <code title="map&#40;object&#40;&#123;&#10;  max_request_duration &#61; string&#10;  eligible_users       &#61; list&#40;string&#41;&#10;  privileged_access &#61; list&#40;object&#40;&#123;&#10;    role      &#61; string&#10;    condition &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  requester_justification_config &#61; optional&#40;object&#40;&#123;&#10;    not_mandatory &#61; optional&#40;bool, true&#41;&#10;    unstructured  &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;, &#123; not_mandatory &#61; false, unstructured &#61; true &#125;&#41;&#10;  manual_approvals &#61; optional&#40;object&#40;&#123;&#10;    require_approver_justification &#61; bool&#10;    steps &#61; list&#40;object&#40;&#123;&#10;      approvers                 &#61; list&#40;string&#41;&#10;      approvals_needed          &#61; optional&#40;number, 1&#41;&#10;      approver_email_recipients &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  additional_notification_targets &#61; optional&#40;object&#40;&#123;&#10;    admin_email_recipients     &#61; optional&#40;list&#40;string&#41;&#41;&#10;    requester_email_recipients &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [scc_mute_configs](variables-scc.tf#L17) | SCC mute configurations keyed by name. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string&#41;&#10;  filter      &#61; string&#10;  type        &#61; optional&#40;string, &#34;DYNAMIC&#34;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [scc_sha_custom_modules](variables-scc.tf#L28) | SCC custom modules keyed by module name. | <code title="map&#40;object&#40;&#123;&#10;  description    &#61; optional&#40;string&#41;&#10;  severity       &#61; string&#10;  recommendation &#61; string&#10;  predicate &#61; object&#40;&#123;&#10;    expression &#61; string&#10;  &#125;&#41;&#10;  resource_selector &#61; object&#40;&#123;&#10;    resource_types &#61; list&#40;string&#41;&#10;  &#125;&#41;&#10;  enablement_state &#61; optional&#40;string, &#34;ENABLED&#34;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [tag_bindings](variables-tags.tf#L89) | Tag bindings for this organization, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [tags](variables-tags.tf#L96) | Tags by key name. If `id` is provided, key or value creation is skipped. The `iam` attribute behaves like the similarly named one at module level. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string, &#34;Managed by the Terraform organization module.&#34;&#41;&#10;  iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    members &#61; list&#40;string&#41;&#10;    role    &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    member &#61; string&#10;    role   &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  id &#61; optional&#40;string&#41;&#10;  values &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description &#61; optional&#40;string, &#34;Managed by the Terraform organization module.&#34;&#41;&#10;    iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;      members &#61; list&#40;string&#41;&#10;      role    &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;      member &#61; string&#10;      role   &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    id &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [tags_config](variables-tags.tf#L161) | Fine-grained control on tag resource and IAM creation. | <code title="object&#40;&#123;&#10;  force_context_ids &#61; optional&#40;bool, false&#41;&#10;  ignore_iam        &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [workforce_identity_config](variables-identity-providers.tf#L17) | Workforce Identity Federation pool and providers. | <code title="object&#40;&#123;&#10;  pool_name &#61; optional&#40;string, &#34;default&#34;&#41;&#10;  providers &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description                &#61; optional&#40;string&#41;&#10;    display_name               &#61; optional&#40;string&#41;&#10;    attribute_condition        &#61; optional&#40;string&#41;&#10;    attribute_mapping          &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    attribute_mapping_template &#61; optional&#40;string&#41;&#10;    disabled                   &#61; optional&#40;bool, false&#41;&#10;    identity_provider &#61; object&#40;&#123;&#10;      oidc &#61; optional&#40;object&#40;&#123;&#10;        issuer_uri    &#61; string&#10;        client_id     &#61; string&#10;        client_secret &#61; optional&#40;string&#41;&#10;        jwks_json     &#61; optional&#40;string&#41;&#10;        web_sso_config &#61; optional&#40;object&#40;&#123;&#10;          response_type             &#61; optional&#40;string, &#34;CODE&#34;&#41;&#10;          assertion_claims_behavior &#61; optional&#40;string, &#34;ONLY_ID_TOKEN_CLAIMS&#34;&#41;&#10;          additional_scopes         &#61; optional&#40;list&#40;string&#41;&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      saml &#61; optional&#40;object&#40;&#123;&#10;        idp_metadata_xml &#61; string&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#10;    oauth2_client_config &#61; optional&#40;object&#40;&#123;&#10;      extended_attributes &#61; optional&#40;object&#40;&#123;&#10;        issuer_uri      &#61; string&#10;        client_id       &#61; string&#10;        client_secret   &#61; string&#10;        attributes_type &#61; optional&#40;string&#41;&#10;        query_filter    &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      extra_attributes &#61; optional&#40;object&#40;&#123;&#10;        issuer_uri      &#61; string&#10;        client_id       &#61; string&#10;        client_secret   &#61; string&#10;        attributes_type &#61; optional&#40;string&#41;&#10;        query_filter    &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [asset_search_results](outputs.tf#L17) | Cloud Asset Inventory search results. |  |
| [custom_constraint_ids](outputs.tf#L24) | Map of CUSTOM_CONSTRAINTS => ID in the organization. |  |
| [custom_role_id](outputs.tf#L29) | Map of custom role IDs created in the organization. |  |
| [custom_roles](outputs.tf#L34) | Map of custom roles resources created in the organization. |  |
| [id](outputs.tf#L39) | Fully qualified organization id. |  |
| [logging_identities](outputs.tf#L57) | Principals used for logging sinks. |  |
| [network_tag_keys](outputs.tf#L69) | Tag key resources. |  |
| [network_tag_values](outputs.tf#L78) | Tag value resources. |  |
| [organization_id](outputs.tf#L88) | Organization id dependent on module resources. |  |
| [organization_policies_ids](outputs.tf#L105) | Map of ORGANIZATION_POLICIES => ID in the organization. |  |
| [scc_custom_sha_modules_ids](outputs.tf#L110) | Map of SCC CUSTOM SHA MODULES => ID in the organization. |  |
| [scc_mute_configs](outputs.tf#L115) | SCC mute configurations. |  |
| [service_agents](outputs.tf#L120) | Identities of all organization-level service agents. |  |
| [sink_writer_identities](outputs.tf#L125) | Writer identities created for each sink. |  |
| [tag_keys](outputs.tf#L133) | Tag key resources. |  |
| [tag_values](outputs.tf#L142) | Tag value resources. |  |
| [workforce_identity_provider_names](outputs.tf#L150) | Workforce Identity provider names. |  |
| [workforce_identity_providers](outputs.tf#L157) | Workforce Identity provider attributes. |  |
<!-- END TFDOC -->
