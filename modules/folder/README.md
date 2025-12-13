# Google Cloud Folder Module

This module allows the creation and management of folders, including support for IAM bindings, organization policies, and hierarchical firewall rules.

<!-- BEGIN TOC -->
- [Basic example with IAM bindings](#basic-example-with-iam-bindings)
- [IAM](#iam)
- [Assured Workload Folder](#assured-workload-folder)
- [Privileged Access Manager (PAM) Entitlements](#privileged-access-manager-pam-entitlements)
  - [Privileged Access Manager (PAM) Entitlements Factory](#privileged-access-manager-pam-entitlements-factory)
- [Organization policies](#organization-policies)
  - [Organization Policy Factory](#organization-policy-factory)
- [Hierarchical Firewall Policy Attachments](#hierarchical-firewall-policy-attachments)
- [Log Sinks](#log-sinks)
- [Data Access Logs](#data-access-logs)
- [KMS Autokey](#kms-autokey)
- [Custom Security Health Analytics Modules](#custom-security-health-analytics-modules)
  - [Custom Security Health Analytics Modules Factory](#custom-security-health-analytics-modules-factory)
- [Tags](#tags)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Basic example with IAM bindings

```hcl
module "folder" {
  source = "./fabric/modules/folder"
  parent = var.folder_id
  name   = "Folder name"
  iam_by_principals = {
    "group:${var.group_email}" = [
      "roles/owner",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.projectCreator"
    ]
  }
  iam = {
    "roles/owner" = ["serviceAccount:${var.service_account.email}"]
  }
  iam_bindings_additive = {
    am1-storage-admin = {
      member = "serviceAccount:${var.service_account.email}"
      role   = "roles/storage.admin"
    }
  }
}
# tftest modules=1 resources=5 inventory=iam.yaml e2e
```

## IAM

IAM is managed via several variables that implement different features and levels of control:

- `iam` and `iam_by_principals` configure authoritative bindings that manage individual roles exclusively, and are internally merged
- `iam_bindings` configure authoritative bindings with optional support for conditions, and are not internally merged with the previous two variables
- `iam_bindings_additive` configure additive bindings via individual role/member pairs with optional support  conditions

The authoritative and additive approaches can be used together, provided different roles are managed by each. Some care must also be taken with the `iam_by_principals` variable to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

IAM also supports variable interpolation for both roles and principals, via the respective attributes in the `var.context` variable. Refer to the [project module](../project/README.md#iam) for examples of the IAM interface.

## Assured Workload Folder

To create [Assured Workload](https://cloud.google.com/security/products/assured-workloads) folder instead of regular folder.
Note that an existing folder can not be converted to an Assured Workload folder, hence `assured_workload_config` is mutually exclusive with `folder_create=false`.

```hcl
module "folder" {
  source = "./fabric/modules/folder"
  parent = var.folder_id
  name   = "Folder name"

  assured_workload_config = {
    compliance_regime         = "EU_REGIONS_AND_SUPPORT"
    display_name              = "workload-name"
    location                  = "europe-west1"
    organization              = var.organization_id
    enable_sovereign_controls = true
  }
  iam = {
    "roles/owner" = ["serviceAccount:${var.service_account.email}"]
  }
  iam_bindings_additive = {
    am1-storage-admin = {
      member = "serviceAccount:${var.service_account.email}"
      role   = "roles/storage.admin"
    }
  }
}
# tftest modules=1 resources=3 inventory=assured-workload.yaml
```

## Privileged Access Manager (PAM) Entitlements

[Privileged Access Manager](https://cloud.google.com/iam/docs/privileged-access-manager-overview) entitlements can be defined via the `pam_entitlements` variable.

Note that using PAM entitlements requires specific roles to be granted to the users and groups that will be using them. For more information, see the [official documentation](https://cloud.google.com/iam/docs/pam-permissions-and-setup#before-you-begin).

Additionally, the Privileged Access Manager Service Agent must be created and granted the `roles/privilegedaccessmanager.folderServiceAgent` role. The service agent is not created automatically, and you can find the `gcloud` command to create it in the `service_agents` output of this module. For more information on service agents, see the [official documentation](https://cloud.google.com/iam/docs/service-agents). Refer to the [organization module's documentation](../organization/README.md#privileged-access-manager-pam-entitlements) for an example on how to grant the required role.

```hcl
module "folder" {
  source              = "./fabric/modules/folder"
  parent              = var.folder_id
  name                = "Networking"
  deletion_protection = false
  pam_entitlements = {
    net-admins = {
      max_request_duration = "3600s"
      eligible_users = ["group:gcp-network-admins@example.com"]
      privileged_access = [
        { role = "roles/compute.networkAdmin" },
        { role = "roles/compute.admin" },
      ]
      manual_approvals = {
        require_approver_justification = true
        steps = [{
          approvers = ["group:gcp-organization-admins@example.com"]
        }]
      }
    }
  }
}
```

### Privileged Access Manager (PAM) Entitlements Factory

PAM entitlements can be loaded from a directory containing YAML files where each file defines one or more entitlements. The structure of the YAML files is exactly the same as the `pam_entitlements` variable.

Note that entitlements defined via `pam_entitlements` take precedence over those in the factory. In other words, if you specify the same entitlement in a YAML file and in the `pam_entitlements` variable, the latter will take priority.

```hcl
module "folder" {
  source = "./fabric/modules/folder"
  parent = var.folder_id
  name   = "Folder name"
  factories_config = {
    pam_entitlements = "configs/pam-entitlements/"
  }
}
```

## Organization policies

To manage organization policies, the `orgpolicy.googleapis.com` service should be enabled in the quota project.

```hcl
module "folder" {
  source = "./fabric/modules/folder"
  parent = var.folder_id
  name   = "Folder name"
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
      rules = [{
        allow = {
          values = ["C0xxxxxxx", "C0yyyyyyy", "C0zzzzzzz"]
        }
      }]
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
    "essentialcontacts.managed.allowedContactDomains" = {
      rules = [
        {
          enforce = true
          parameters = jsonencode({
            allowedDomains = ["@example.com", "@secondary.example.com"]
          })
        }
      ]
    }
  }
}
# tftest modules=1 resources=9 inventory=org-policies.yaml e2e
```

### Organization Policy Factory

Organization policies can be loaded from a directory containing YAML files where each file defines one or more constraints. The structure of the YAML files is exactly the same as the org_policies variable.

Note that constraints defined via org_policies take precedence over those in org_policies_data_path. In other words, if you specify the same constraint in a YAML file and in the org_policies variable, the latter will take priority.

The example below deploys a few organization policies split between two YAML files.

```hcl
module "folder" {
  source = "./fabric/modules/folder"
  parent = var.folder_id
  name   = "Folder name"
  factories_config = {
    org_policies = "configs/org-policies/"
  }
  context = {
    condition_vars = {
      tags = {
        my_conditional_tag = "tagKeys/1234"
      }
      domains = {
        secondary = "@secondary.example.com"
      }
      customer_ids = {
        extra = "C0zzzzzzz"
      }
    }
  }
}
# tftest modules=1 resources=9 files=boolean,list inventory=org-policies.yaml e2e
```

```yaml
compute.disableGuestAttributesAccess:
  rules:
  - enforce: true
compute.skipDefaultNetworkCreation:
  rules:
  - enforce: true
iam.disableServiceAccountKeyCreation:
  rules:
  - enforce: true
iam.disableServiceAccountKeyUpload:
  rules:
  - condition:
      description: test condition
      expression: resource.matchTagId('${tags.my_conditional_tag}', 'tagValues/1234')
      location: somewhere
      title: condition
    enforce: true
  - enforce: false
essentialcontacts.managed.allowedContactDomains:
  rules:
  - enforce: true
    parameters: |
      {"allowedDomains": ["@example.com", "${domains.secondary}"]}

# tftest-file id=boolean path=configs/org-policies/boolean.yaml schema=org-policies.schema.json
```

```yaml
compute.trustedImageProjects:
  rules:
  - allow:
      values:
      - projects/my-project
compute.vmExternalIpAccess:
  rules:
  - deny:
      all: true
iam.allowedPolicyMemberDomains:
  rules:
  - allow:
      values:
      - C0xxxxxxx
      - C0yyyyyyy
      - ${customer_ids.extra}

# tftest-file id=list path=configs/org-policies/list.yaml schema=org-policies.schema.json
```

## Hierarchical Firewall Policy Attachments

Hierarchical firewall policies can be managed via the [`net-firewall-policy`](../net-firewall-policy/) module, including support for factories. Once a policy is available, attaching it to the organization can be done either in the firewall policy module itself, or here:

```hcl
module "firewall-policy" {
  source    = "./fabric/modules/net-firewall-policy"
  name      = "test-1"
  parent_id = module.folder.id
  # attachment via the firewall policy module
  # attachments = {
  #   folder-1 = module.folder.id
  # }
}

module "folder" {
  source = "./fabric/modules/folder"
  parent = var.folder_id
  name   = "Folder name"
  # attachment via the organization module
  firewall_policy = {
    name   = "test-1"
    policy = module.firewall-policy.id
  }
}
# tftest modules=2 resources=3 e2e serial
```

## Log Sinks

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

module "folder-sink" {
  source = "./fabric/modules/folder"
  name   = "Folder name"
  parent = var.folder_id
  logging_sinks = {
    warnings = {
      destination = module.gcs.id
      filter      = "severity=WARNING"
      type        = "storage"
    }
    info = {
      destination = module.dataset.id
      filter      = "severity=INFO"
      type        = "bigquery"
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
# tftest inventory=logging.yaml e2e
```

## Data Access Logs

Activation of data access logs can be controlled via the `logging_data_access` variable. If the `iam_bindings_authoritative` variable is used to set a resource-level IAM policy, the data access log configuration will also be authoritative as part of the policy.

This example shows how to set a non-authoritative access log configuration:

```hcl
module "folder" {
  source = "./fabric/modules/folder"
  parent = var.folder_id
  name   = "Folder name"
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
# tftest modules=1 resources=3 inventory=logging-data-access.yaml e2e
```

## KMS Autokey

To enable KMS Autokey at the folder level, set `autokey_config.project` to a valid project id or number, prefixed by `projects/`. The project must already be [configured correctly](https://docs.cloud.google.com/kms/docs/enable-autokey) for Autokey to work.

If `autokey_config.project` leverages context expansion, the `projects/` prefix is added automatically by the module.

```hcl
module "folder" {
  source = "./fabric/modules/folder"
  parent = var.folder_id
  name   = "Folder name"
}

# avoid a dependency cycle by configuring autokey in a separate module

module "folder-iam" {
  source        = "./fabric/modules/folder"
  id            = module.folder.id
  folder_create = false
  autokey_config = {
    project = "$project_numbers:test"
  }
  context = {
    project_numbers = {
      test = module.project.number
    }
  }
}

module "project" {
  source          = "./fabric/modules/project"
  parent          = module.folder.id
  name            = "test-autokey"
  billing_account = var.billing_account_id
  services = [
    "cloudkms.googleapis.com"
  ]
  iam = {
    "roles/cloudkms.admin" = [
      "group:key-admins@example.com",
      module.project.service_agents["cloudkms"].iam_email
    ]
    "roles/cloudkms.autokeyUser" = [
      "group:key-user@example.com"
    ]
  }
}

# tftest modules=3 resources=8 inventory=autokey.yaml
```

## Custom Security Health Analytics Modules

[Security Health Analytics custom modules](https://cloud.google.com/security-command-center/docs/custom-modules-sha-create) can be defined via the `scc_sha_custom_modules` variable:

```hcl
module "folder" {
  source = "./fabric/modules/folder"
  parent = var.folder_id
  name   = "Folder name"
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
# tftest modules=1 resources=2 inventory=custom-modules-sha.yaml
```

### Custom Security Health Analytics Modules Factory

Custom modules can also be specified via a factory. Each file is mapped to a custom module, where the module name defaults to the file name.

Custom modules defined via the variable are merged with those coming from the factory, and override them in case of duplicate names.

```hcl
module "folder" {
  source = "./fabric/modules/folder"
  parent = var.folder_id
  name   = "Folder name"
  factories_config = {
    scc_sha_custom_modules = "data/scc_sha_custom_modules"
  }
}
# tftest modules=1 resources=2 files=custom-module-sha-1 inventory=custom-modules-sha.yaml
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

## Tags

Refer to the [Creating and managing tags](https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing) documentation for details on usage.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  tags = {
    environment = {
      description = "Environment specification."
      values = {
        dev  = {}
        prod = {}
      }
    }
  }
}

module "folder" {
  source = "./fabric/modules/folder"
  name   = "Folder name"
  parent = var.folder_id
  tag_bindings = {
    env-prod = module.org.tag_values["environment/prod"].id
  }
}
# tftest modules=2 resources=5 inventory=tags.yaml e2e serial
```

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | resources |
|---|---|---|
| [iam.tf](./iam.tf) | IAM bindings. | <code>google_folder_iam_binding</code> · <code>google_folder_iam_member</code> |
| [logging.tf](./logging.tf) | Log sinks and supporting resources. | <code>google_bigquery_dataset_iam_member</code> · <code>google_folder_iam_audit_config</code> · <code>google_logging_folder_exclusion</code> · <code>google_logging_folder_settings</code> · <code>google_logging_folder_sink</code> · <code>google_project_iam_member</code> · <code>google_pubsub_topic_iam_member</code> · <code>google_storage_bucket_iam_member</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_assured_workloads_workload</code> · <code>google_compute_firewall_policy_association</code> · <code>google_essential_contacts_contact</code> · <code>google_folder</code> · <code>google_kms_autokey_config</code> |
| [organization-policies.tf](./organization-policies.tf) | Folder-level organization policies. | <code>google_org_policy_policy</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [pam.tf](./pam.tf) | None | <code>google_privileged_access_manager_entitlement</code> |
| [scc-sha-custom-modules.tf](./scc-sha-custom-modules.tf) | Folder-level Custom modules with Security Health Analytics. | <code>google_scc_management_folder_security_health_analytics_custom_module</code> |
| [service-agents.tf](./service-agents.tf) | Service agents supporting resources. |  |
| [tags.tf](./tags.tf) | None | <code>google_tags_tag_binding</code> |
| [variables-iam.tf](./variables-iam.tf) | None |  |
| [variables-logging.tf](./variables-logging.tf) | None |  |
| [variables-pam.tf](./variables-pam.tf) | None |  |
| [variables-scc.tf](./variables-scc.tf) | None |  |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [assured_workload_config](variables.tf#L17) | Create AssuredWorkloads folder instead of regular folder when value is provided. Incompatible with folder_create=false. | <code title="object&#40;&#123;&#10;  compliance_regime         &#61; string&#10;  display_name              &#61; string&#10;  location                  &#61; string&#10;  organization              &#61; string&#10;  enable_sovereign_controls &#61; optional&#40;bool&#41;&#10;  labels                    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  partner                   &#61; optional&#40;string&#41;&#10;  partner_permissions &#61; optional&#40;object&#40;&#123;&#10;    assured_workloads_monitoring &#61; optional&#40;bool&#41;&#10;    data_logs_viewer             &#61; optional&#40;bool&#41;&#10;    service_access_approver      &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  violation_notifications_enabled &#61; optional&#40;bool&#41;&#10;&#10;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [autokey_config](variables.tf#L70) | Enable autokey support for this folder's children. Project accepts either project id or number. | <code title="object&#40;&#123;&#10;  project &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [contacts](variables.tf#L79) | List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L98) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  condition_vars  &#61; optional&#40;map&#40;map&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  custom_roles    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  email_addresses &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  folder_ids      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals  &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_numbers &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  tag_values      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [deletion_protection](variables.tf#L114) | Deletion protection setting for this folder. | <code>bool</code> |  | <code>false</code> |
| [factories_config](variables.tf#L120) | Paths to data files and folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  org_policies           &#61; optional&#40;string&#41;&#10;  pam_entitlements       &#61; optional&#40;string&#41;&#10;  scc_sha_custom_modules &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [firewall_policy](variables.tf#L131) | Hierarchical firewall policy to associate to this folder. | <code title="object&#40;&#123;&#10;  name   &#61; string&#10;  policy &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [folder_create](variables.tf#L140) | Create folder. When set to false, uses id to reference an existing folder. | <code>bool</code> |  | <code>true</code> |
| [iam](variables-iam.tf#L17) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L24) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L39) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L61) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals_additive](variables-iam.tf#L54) | Additive IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid errors. Merged internally with the `iam_bindings_additive` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [id](variables.tf#L150) | Folder ID in case you use folder_create=false. | <code>string</code> |  | <code>null</code> |
| [logging_data_access](variables-logging.tf#L17) | Control activation of data access logs. The special 'allServices' key denotes configuration for all services. | <code title="map&#40;object&#40;&#123;&#10;  ADMIN_READ &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41; &#125;&#41;&#41;,&#10;  DATA_READ  &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41; &#125;&#41;&#41;,&#10;  DATA_WRITE &#61; optional&#40;object&#40;&#123; exempted_members &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41; &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_exclusions](variables-logging.tf#L28) | Logging exclusions for this folder in the form {NAME -> FILTER}. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_settings](variables-logging.tf#L35) | Default settings for logging resources. | <code title="object&#40;&#123;&#10;  disable_default_sink &#61; optional&#40;bool&#41;&#10;  storage_location     &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [logging_sinks](variables-logging.tf#L45) | Logging sinks to create for the folder. | <code title="map&#40;object&#40;&#123;&#10;  bq_partitioned_table &#61; optional&#40;bool, false&#41;&#10;  description          &#61; optional&#40;string&#41;&#10;  destination          &#61; string&#10;  disabled             &#61; optional&#40;bool, false&#41;&#10;  exclusions           &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  filter               &#61; optional&#40;string&#41;&#10;  iam                  &#61; optional&#40;bool, true&#41;&#10;  include_children     &#61; optional&#40;bool, true&#41;&#10;  intercept_children   &#61; optional&#40;bool, false&#41;&#10;  type                 &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [name](variables.tf#L156) | Folder name. | <code>string</code> |  | <code>null</code> |
| [org_policies](variables.tf#L162) | Organization policies applied to this folder keyed by policy name. | <code title="map&#40;object&#40;&#123;&#10;  inherit_from_parent &#61; optional&#40;bool&#41; &#35; for list policies only.&#10;  reset               &#61; optional&#40;bool&#41;&#10;  rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;    allow &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    deny &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    enforce &#61; optional&#40;bool&#41; &#35; for boolean policies only.&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      description &#61; optional&#40;string&#41;&#10;      expression  &#61; optional&#40;string&#41;&#10;      location    &#61; optional&#40;string&#41;&#10;      title       &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    parameters &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [pam_entitlements](variables-pam.tf#L17) | Privileged Access Manager entitlements for this resource, keyed by entitlement ID. | <code title="map&#40;object&#40;&#123;&#10;  max_request_duration &#61; string&#10;  eligible_users       &#61; list&#40;string&#41;&#10;  privileged_access &#61; list&#40;object&#40;&#123;&#10;    role      &#61; string&#10;    condition &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  requester_justification_config &#61; optional&#40;object&#40;&#123;&#10;    not_mandatory &#61; optional&#40;bool, true&#41;&#10;    unstructured  &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;, &#123; not_mandatory &#61; false, unstructured &#61; true &#125;&#41;&#10;  manual_approvals &#61; optional&#40;object&#40;&#123;&#10;    require_approver_justification &#61; bool&#10;    steps &#61; list&#40;object&#40;&#123;&#10;      approvers                 &#61; list&#40;string&#41;&#10;      approvals_needed          &#61; optional&#40;number, 1&#41;&#10;      approver_email_recipients &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  additional_notification_targets &#61; optional&#40;object&#40;&#123;&#10;    admin_email_recipients     &#61; optional&#40;list&#40;string&#41;&#41;&#10;    requester_email_recipients &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [parent](variables.tf#L190) | Parent in folders/folder_id or organizations/org_id format. | <code>string</code> |  | <code>null</code> |
| [scc_sha_custom_modules](variables-scc.tf#L17) | SCC custom modules keyed by module name. | <code title="map&#40;object&#40;&#123;&#10;  description    &#61; optional&#40;string&#41;&#10;  severity       &#61; string&#10;  recommendation &#61; string&#10;  predicate &#61; object&#40;&#123;&#10;    expression &#61; string&#10;  &#125;&#41;&#10;  resource_selector &#61; object&#40;&#123;&#10;    resource_types &#61; list&#40;string&#41;&#10;  &#125;&#41;&#10;  enablement_state &#61; optional&#40;string, &#34;ENABLED&#34;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [tag_bindings](variables.tf#L204) | Tag bindings for this folder, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [assured_workload](outputs.tf#L17) | Assured Workloads workload resource. |  |
| [folder](outputs.tf#L22) | Folder resource. |  |
| [id](outputs.tf#L27) | Fully qualified folder id. |  |
| [name](outputs.tf#L38) | Folder name. |  |
| [organization_policies_ids](outputs.tf#L47) | Map of ORGANIZATION_POLICIES => ID in the folder. |  |
| [scc_custom_sha_modules_ids](outputs.tf#L52) | Map of SCC CUSTOM SHA MODULES => ID in the folder. |  |
| [service_agents](outputs.tf#L57) | Identities of all folder-level service agents. |  |
| [sink_writer_identities](outputs.tf#L62) | Writer identities created for each sink. |  |
<!-- END TFDOC -->
