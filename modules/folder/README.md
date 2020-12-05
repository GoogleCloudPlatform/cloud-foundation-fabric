# Google Cloud Folder Module

This module allows the creation and management of folders together with their individual IAM bindings and organization policies.

## Examples

### IAM bindings

```hcl
module "folder" {
  source = "./modules/folder"
  parent = "organizations/1234567890"
  name  = "Folder name"
  iam = {
    "roles/owner" = ["group:users@example.com"]
  }
}
# tftest:modules=1:resources=2
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

module "folder-sink" {
  source = "./modules/folder"
  parent = "folders/657104291943"
  name   = "my-folder"
  logging_sinks = {
    warnings = {
      type        = "gcs"
      destination = module.gcs.name
      filter      = "severity=WARNING"
      grant       = false
    }
    info = {
      type        = "bigquery"
      destination = module.dataset.id
      filter      = "severity=INFO"
      grant       = false
    }
    notice = {
      type        = "pubsub"
      destination = module.pubsub.id
      filter      = "severity=NOTICE"
      grant       = true
    }
  }
  logging_exclusions = {
    no-gce-instances = "resource.type=gce_instance"
  }
}
# tftest:modules=4:resources=9
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
|---|---|:---: |:---:|:---:|
| *firewall_policies* | Hierarchical firewall policies to *create* in this folder. | <code title="map&#40;map&#40;object&#40;&#123;&#10;description             &#61; string&#10;direction               &#61; string&#10;action                  &#61; string&#10;priority                &#61; number&#10;ranges                  &#61; list&#40;string&#41;&#10;ports                   &#61; map&#40;list&#40;string&#41;&#41;&#10;target_service_accounts &#61; list&#40;string&#41;&#10;target_resources        &#61; list&#40;string&#41;&#10;logging                 &#61; bool&#10;&#125;&#41;&#41;&#41;">map(map(object({...})))</code> |  | <code title="">{}</code> |
| *firewall_policy_attachments* | List of hierarchical firewall policy IDs to *attach* to this folder. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *folder_create* | Create folder. When set to false, uses id to reference an existing folder. | <code title="">bool</code> |  | <code title="">true</code> |
| *iam* | IAM bindings in {ROLE => [MEMBERS]} format. | <code title="map&#40;set&#40;string&#41;&#41;">map(set(string))</code> |  | <code title="">{}</code> |
| *id* | Folder ID in case you use folder_create=false | <code title="">string</code> |  | <code title="">null</code> |
| *logging_exclusions* | Logging exclusions for this folder in the form {NAME -> FILTER}. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *logging_sinks* | Logging sinks to create for this folder. | <code title="map&#40;object&#40;&#123;&#10;destination &#61; string&#10;type &#61; string&#10;filter      &#61; string&#10;grant       &#61; bool&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *name* | Folder name. | <code title="">string</code> |  | <code title="">null</code> |
| *parent* | Parent in folders/folder_id or organizations/org_id format. | <code title="">string</code> |  | <code title="null&#10;validation &#123;&#10;condition     &#61; var.parent &#61;&#61; null &#124;&#124; can&#40;regex&#40;&#34;&#40;organizations&#124;folders&#41;&#47;&#91;0-9&#93;&#43;&#34;, var.parent&#41;&#41;&#10;error_message &#61; &#34;Parent must be of the form folders&#47;folder_id or organizations&#47;organization_id.&#34;&#10;&#125;">...</code> |
| *policy_boolean* | Map of boolean org policies and enforcement value, set value to null for policy restore. | <code title="map&#40;bool&#41;">map(bool)</code> |  | <code title="">{}</code> |
| *policy_list* | Map of list org policies, status is true for allow, false for deny, null for restore. Values can only be used for allow or deny. | <code title="map&#40;object&#40;&#123;&#10;inherit_from_parent &#61; bool&#10;suggested_value     &#61; string&#10;status              &#61; bool&#10;values              &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| firewall_policies | Map of firewall policy resources created in this folder. |  |
| firewall_policy_id | Map of firewall policy ids created in this folder. |  |
| folder | Folder resource. |  |
| id | Folder id. |  |
| name | Folder name. |  |
| sink_writer_identities | None |  |
<!-- END TFDOC -->
