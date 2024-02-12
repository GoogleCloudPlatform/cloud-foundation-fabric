# Google Cloud Folder Module

This module allows the creation and management of folders, including support for IAM bindings, organization policies, and hierarchical firewall rules.

<!-- BEGIN TOC -->
- [Basic example with IAM bindings](#basic-example-with-iam-bindings)
- [IAM](#iam)
- [Organization policies](#organization-policies)
  - [Organization Policy Factory](#organization-policy-factory)
- [Hierarchical Firewall Policy Attachments](#hierarchical-firewall-policy-attachments)
- [Log Sinks](#log-sinks)
- [Data Access Logs](#data-access-logs)
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

Refer to the [project module](../project/README.md#iam) for examples of the IAM interface.

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
          values = ["C0xxxxxxx", "C0yyyyyyy"]
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
  }
}
# tftest modules=1 resources=8 inventory=org-policies.yaml e2e
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
}
# tftest modules=1 resources=8 files=boolean,list inventory=org-policies.yaml e2e
```

```yaml
# tftest-file id=boolean path=configs/org-policies/boolean.yaml
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
      expression: resource.matchTagId('tagKeys/1234', 'tagValues/1234')
      location: somewhere
      title: condition
    enforce: true
  - enforce: false
```

```yaml
# tftest-file id=list path=configs/org-policies/list.yaml
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
  source      = "./fabric/modules/logging-bucket"
  parent_type = "project"
  parent      = var.project_id
  id          = "${var.prefix}-bucket"
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
  }
  logging_exclusions = {
    no-gce-instances = "resource.type=gce_instance"
  }
}
# tftest modules=5 resources=14 inventory=logging.yaml e2e
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
      # logs for principals listed here will be excluded
      ADMIN_READ = ["group:${var.group_email}"]
    }
    "storage.googleapis.com" = {
      DATA_READ  = []
      DATA_WRITE = []
    }
  }
}
# tftest modules=1 resources=3 inventory=logging-data-access.yaml e2e
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
| [logging.tf](./logging.tf) | Log sinks and supporting resources. | <code>google_bigquery_dataset_iam_member</code> · <code>google_folder_iam_audit_config</code> · <code>google_logging_folder_exclusion</code> · <code>google_logging_folder_sink</code> · <code>google_project_iam_member</code> · <code>google_pubsub_topic_iam_member</code> · <code>google_storage_bucket_iam_member</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_compute_firewall_policy_association</code> · <code>google_essential_contacts_contact</code> · <code>google_folder</code> |
| [organization-policies.tf](./organization-policies.tf) | Folder-level organization policies. | <code>google_org_policy_policy</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [tags.tf](./tags.tf) | None | <code>google_tags_tag_binding</code> |
| [variables-iam.tf](./variables-iam.tf) | None |  |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [contacts](variables.tf#L17) | List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [factories_config](variables.tf#L24) | Paths to data files and folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  org_policies &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [firewall_policy](variables.tf#L33) | Hierarchical firewall policy to associate to this folder. | <code title="object&#40;&#123;&#10;  name   &#61; string&#10;  policy &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [folder_create](variables.tf#L42) | Create folder. When set to false, uses id to reference an existing folder. | <code>bool</code> |  | <code>true</code> |
| [iam](variables-iam.tf#L17) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L24) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L39) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L54) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [id](variables.tf#L48) | Folder ID in case you use folder_create=false. | <code>string</code> |  | <code>null</code> |
| [logging_data_access](variables.tf#L54) | Control activation of data access logs. Format is service => { log type => [exempted members]}. The special 'allServices' key denotes configuration for all services. | <code>map&#40;map&#40;list&#40;string&#41;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_exclusions](variables.tf#L69) | Logging exclusions for this folder in the form {NAME -> FILTER}. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_sinks](variables.tf#L76) | Logging sinks to create for the folder. | <code title="map&#40;object&#40;&#123;&#10;  bq_partitioned_table &#61; optional&#40;bool, false&#41;&#10;  description          &#61; optional&#40;string&#41;&#10;  destination          &#61; string&#10;  disabled             &#61; optional&#40;bool, false&#41;&#10;  exclusions           &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  filter               &#61; string&#10;  iam                  &#61; optional&#40;bool, true&#41;&#10;  include_children     &#61; optional&#40;bool, true&#41;&#10;  type                 &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [name](variables.tf#L107) | Folder name. | <code>string</code> |  | <code>null</code> |
| [org_policies](variables.tf#L113) | Organization policies applied to this folder keyed by policy name. | <code title="map&#40;object&#40;&#123;&#10;  inherit_from_parent &#61; optional&#40;bool&#41; &#35; for list policies only.&#10;  reset               &#61; optional&#40;bool&#41;&#10;  rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;    allow &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    deny &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    enforce &#61; optional&#40;bool&#41; &#35; for boolean policies only.&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      description &#61; optional&#40;string&#41;&#10;      expression  &#61; optional&#40;string&#41;&#10;      location    &#61; optional&#40;string&#41;&#10;      title       &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [parent](variables.tf#L140) | Parent in folders/folder_id or organizations/org_id format. | <code>string</code> |  | <code>null</code> |
| [tag_bindings](variables.tf#L150) | Tag bindings for this folder, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [folder](outputs.tf#L17) | Folder resource. |  |
| [id](outputs.tf#L22) | Fully qualified folder id. |  |
| [name](outputs.tf#L33) | Folder name. |  |
| [sink_writer_identities](outputs.tf#L38) | Writer identities created for each sink. |  |
<!-- END TFDOC -->
