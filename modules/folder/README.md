# Google Cloud Folder Module

This module allows the creation and management of folders, including support for IAM bindings, organization policies, and hierarchical firewall rules.

## Examples

### IAM bindings

```hcl
module "folder" {
  source = "./modules/folder"
  parent = "organizations/1234567890"
  name  = "Folder name"
  group_iam       = {
    "cloud-owners@example.org" = [
        "roles/owner",
        "roles/resourcemanager.projectCreator"
    ]
  }
  iam = {
    "roles/owner" = ["user:one@example.com"]
  }
}
# tftest:modules=1:resources=3
```

### Organization policies

```hcl
module "folder" {
  source = "./modules/folder"
  parent = "organizations/1234567890"
  name  = "Folder name"
  policy_boolean = {
    "constraints/compute.disableGuestAttributesAccess" = true
    "constraints/compute.skipDefaultNetworkCreation" = true
  }
  policy_list = {
    "constraints/compute.trustedImageProjects" = {
      inherit_from_parent = null
      suggested_value = null
      status = true
      values = ["projects/my-project"]
    }
  }
}
# tftest:modules=1:resources=4
```

### Firewall policy factory

In the same way as for the [organization]()../organization) module, the in-built factory allows you to define a single policy, using one file for rules, and an optional file for CIDR range substitution variables. Remember that non-absolute paths are relative to the root module (the folder where you run `terraform`).

```hcl
module "folder" {
  source          = "./modules/folder"
  parent = "organizations/1234567890"
  name  = "Folder name"
  firewall_policy_factory = {
    cidr_file   = "data/cidrs.yaml
    policy_name = null
    rules_file  = "data/rules.yaml"
  }
}
# tftest:skip
```

```yaml
# cidrs.yaml

rfc1918:
  - 10.0.0.0/8
  - 172.168.0.0/12
  - 192.168.0.0/16
```

```yaml
# rules.yaml

allow-admins:
  description: Access from the admin subnet to all subnets
  direction: INGRESS
  action: allow
  priority: 1000
  ranges:
    - $rfc1918
  ports:
    all: []
  target_resources: null
  enable_logging: false

allow-ssh-from-iap:
  description: Enable SSH from IAP
  direction: INGRESS
  action: allow
  priority: 1002
  ranges:
    - 35.235.240.0/20
  ports:
    tcp: ["22"]
  target_resources: null
  enable_logging: false
```

### Logging Sinks

```hcl
module "gcs" {
  source        = "./modules/gcs"
  project_id    = "my-project"
  name          = "gcs_sink"
  force_destroy = true
}

module "dataset" {
  source     = "./modules/bigquery-dataset"
  project_id = "my-project"
  id         = "bq_sink"
}

module "pubsub" {
  source     = "./modules/pubsub"
  project_id = "my-project"
  name       = "pubsub_sink"
}

module "bucket" {
  source      = "./modules/logging-bucket"
  parent_type = "project"
  parent      = "my-project"
  id          = "bucket"
}

module "folder-sink" {
  source = "./modules/folder"
  parent = "folders/657104291943"
  name   = "my-folder"
  logging_sinks = {
    warnings = {
      type             = "gcs"
      destination      = module.gcs.name
      filter           = "severity=WARNING"
      iam              = false
      include_children = true
      exclusions       = {}
    }
    info = {
      type             = "bigquery"
      destination      = module.dataset.id
      filter           = "severity=INFO"
      iam              = false
      include_children = true
      exclusions       = {}
    }
    notice = {
      type             = "pubsub"
      destination      = module.pubsub.id
      filter           = "severity=NOTICE"
      iam              = true
      include_children = true
      exclusions       = {}
    }
    debug = {
      type             = "logging"
      destination      = module.bucket.id
      filter           = "severity=DEBUG"
      iam              = true
      include_children = true
      exclusions = {
        no-compute = "logName:compute"
      }
    }
  }
  logging_exclusions = {
    no-gce-instances = "resource.type=gce_instance"
  }
}
# tftest:modules=5:resources=12
```

### Hierarchical firewall policies

```hcl
module "folder1" {
  source = "./modules/folder"
  parent = var.organization_id
  name   = "policy-container"

  firewall_policies = {
    iap-policy = {
      allow-iap-ssh = {
        description = "Always allow ssh from IAP"
        direction   = "INGRESS"
        action      = "allow"
        priority    = 100
        ranges      = ["35.235.240.0/20"]
        ports = {
          tcp = ["22"]
        }
        target_service_accounts = null
        target_resources        = null
        logging                 = false
      }
    }
  }
  firewall_policy_attachments = {
    iap-policy = module.folder1.firewall_policy_id["iap-policy"]
  }
}

module "folder2" {
  source = "./modules/folder"
  parent = var.organization_id
  name   = "hf2"
  firewall_policy_attachments = {
    iap-policy = module.folder1.firewall_policy_id["iap-policy"]
  }
}
# tftest:modules=2:resources=6
```

<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| contacts | List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| firewall_policies | Hierarchical firewall policies created in this folder. | <code title="map&#40;map&#40;object&#40;&#123;&#10;  action                  &#61; string&#10;  description             &#61; string&#10;  direction               &#61; string&#10;  logging                 &#61; bool&#10;  ports                   &#61; map&#40;list&#40;string&#41;&#41;&#10;  priority                &#61; number&#10;  ranges                  &#61; list&#40;string&#41;&#10;  target_resources        &#61; list&#40;string&#41;&#10;  target_service_accounts &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;&#41;">map&#40;map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| firewall_policy_attachments | List of hierarchical firewall policy IDs to attached to this folder. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| firewall_policy_factory | Configuration for the firewall policy factory. | <code title="object&#40;&#123;&#10;  cidr_file   &#61; string&#10;  policy_name &#61; string&#10;  rules_file  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| folder_create | Create folder. When set to false, uses id to reference an existing folder. | <code>bool</code> |  | <code>true</code> |
| group_iam | Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| iam | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| id | Folder ID in case you use folder_create=false | <code>string</code> |  | <code>null</code> |
| logging_exclusions | Logging exclusions for this folder in the form {NAME -> FILTER}. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| logging_sinks | Logging sinks to create for this folder. | <code title="map&#40;object&#40;&#123;&#10;  destination      &#61; string&#10;  type             &#61; string&#10;  filter           &#61; string&#10;  iam              &#61; bool&#10;  include_children &#61; bool&#10;  exclusions &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| name | Folder name. | <code>string</code> |  | <code>null</code> |
| parent | Parent in folders/folder_id or organizations/org_id format. | <code>string</code> |  | <code>null</code> |
| policy_boolean | Map of boolean org policies and enforcement value, set value to null for policy restore. | <code>map&#40;bool&#41;</code> |  | <code>&#123;&#125;</code> |
| policy_list | Map of list org policies, status is true for allow, false for deny, null for restore. Values can only be used for allow or deny. | <code title="map&#40;object&#40;&#123;&#10;  inherit_from_parent &#61; bool&#10;  suggested_value     &#61; string&#10;  status              &#61; bool&#10;  values              &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| firewall_policies | Map of firewall policy resources created in this folder. |  |
| firewall_policy_id | Map of firewall policy ids created in this folder. |  |
| folder | Folder resource. |  |
| id | Folder id. |  |
| name | Folder name. |  |
| sink_writer_identities | Writer identities created for each sink. |  |


<!-- END TFDOC -->
