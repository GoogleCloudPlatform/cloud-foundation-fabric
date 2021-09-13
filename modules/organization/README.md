# Organization Module

This module allows managing several organization properties:

- IAM bindings, both authoritative and additive
- custom IAM roles
- audit logging configuration for services
- organization policies

## Example

```hcl
module "org" {
  source          = "./modules/organization"
  organization_id = "organizations/1234567890"
  group_iam       = {
    "cloud-owners@example.org" = ["roles/owner", "roles/projectCreator"]
  }
  iam             = {
    "roles/projectCreator" = ["group:cloud-admins@example.org"]
  }
  policy_boolean = {
    "constraints/compute.disableGuestAttributesAccess" = true
    "constraints/compute.skipDefaultNetworkCreation"   = true
  }
  policy_list = {
    "constraints/compute.trustedImageProjects" = {
      inherit_from_parent = null
      suggested_value     = null
      status              = true
      values              = ["projects/my-project"]
    }
  }
}
# tftest:modules=1:resources=5
```

## IAM

There are several mutually exclusive ways of managing IAM in this module

- non-authoritative via the `iam_additive` and `iam_additive_members` variables, where bindings created outside this module will coexist with those managed here
- authoritative via the `group_iam` and `iam` variables, where bindings created outside this module (eg in the console) will be removed at each `terraform apply` cycle if the same role is also managed here
- authoritative policy via the `iam_bindings_authoritative` variable, where any binding created outside this module (eg in the console) will be removed at each `terraform apply` cycle regardless of the role

Some care must be takend with the `groups_iam` variable (and in some situations with the additive variables) to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

## Hierarchical firewall rules

```hcl
module "org" {
  source          = "./modules/organization"
  organization_id = var.organization_id
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
    iap_policy = module.org.firewall_policy_id["iap-policy"]
  }
}
# tftest:modules=1:resources=3
```

## Logging Sinks

```hcl
module "gcs" {
  source        = "./modules/gcs"
  project_id    = var.project_id
  name          = "gcs_sink"
  force_destroy = true
}

module "dataset" {
  source     = "./modules/bigquery-dataset"
  project_id = var.project_id
  id         = "bq_sink"
}

module "pubsub" {
  source     = "./modules/pubsub"
  project_id = var.project_id
  name       = "pubsub_sink"
}

module "bucket" {
  source      = "./modules/logging-bucket"
  parent_type = "project"
  parent      = "my-project"
  id          = "bucket"
}

module "org" {
  source          = "./modules/organization"
  organization_id = var.organization_id

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
      include_children = false
      exclusions = {
        no-compute = "logName:compute"
      }
    }
  }
  logging_exclusions = {
    no-gce-instances = "resource.type=gce_instance"
  }
}
# tftest:modules=5:resources=11
```

## Custom Roles
```hcl
module "org" {
  source          = "./modules/organization"
  organization_id = var.organization_id
  custom_roles = {
    "myRole" = [
      "compute.instances.list",
    ]
  }
  iam = {
    (module.org.custom_role_id.myRole) = ["user:me@example.com"]
  }
}
# tftest:modules=1:resources=2
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| organization_id | Organization id in organizations/nnnnnn format. | <code title="string&#10;validation &#123;&#10;condition     &#61; can&#40;regex&#40;&#34;&#94;organizations&#47;&#91;0-9&#93;&#43;&#34;, var.organization_id&#41;&#41;&#10;error_message &#61; &#34;The organization_id must in the form organizations&#47;nnn.&#34;&#10;&#125;">string</code> | ✓ |  |
| *contacts* | List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *custom_roles* | Map of role name => list of permissions to create in this project. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *firewall_policies* | Hierarchical firewall policies to *create* in the organization. | <code title="map&#40;map&#40;object&#40;&#123;&#10;description             &#61; string&#10;direction               &#61; string&#10;action                  &#61; string&#10;priority                &#61; number&#10;ranges                  &#61; list&#40;string&#41;&#10;ports                   &#61; map&#40;list&#40;string&#41;&#41;&#10;target_service_accounts &#61; list&#40;string&#41;&#10;target_resources        &#61; list&#40;string&#41;&#10;logging                 &#61; bool&#10;&#125;&#41;&#41;&#41;">map(map(object({...})))</code> |  | <code title="">{}</code> |
| *firewall_policy_attachments* | List of hierarchical firewall policy IDs to *attach* to the organization | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *group_iam* | Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam* | IAM bindings, in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_additive* | Non authoritative IAM bindings, in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_additive_members* | IAM additive bindings in {MEMBERS => [ROLE]} format. This might break if members are dynamic values. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_audit_config* | Service audit logging configuration. Service as key, map of log permission (eg DATA_READ) and excluded members as value for each service. | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">{}</code> |
| *iam_audit_config_authoritative* | IAM Authoritative service audit logging configuration. Service as key, map of log permission (eg DATA_READ) and excluded members as value for each service. Audit config should also be authoritative when using authoritative bindings. Use with caution. | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">null</code> |
| *iam_bindings_authoritative* | IAM authoritative bindings, in {ROLE => [MEMBERS]} format. Roles and members not explicitly listed will be cleared. Bindings should also be authoritative when using authoritative audit config. Use with caution. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">null</code> |
| *logging_exclusions* | Logging exclusions for this organization in the form {NAME -> FILTER}. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *logging_sinks* | Logging sinks to create for this organization. | <code title="map&#40;object&#40;&#123;&#10;destination      &#61; string&#10;type &#61; string&#10;filter           &#61; string&#10;iam              &#61; bool&#10;include_children &#61; bool&#10;exclusions &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *policy_boolean* | Map of boolean org policies and enforcement value, set value to null for policy restore. | <code title="map&#40;bool&#41;">map(bool)</code> |  | <code title="">{}</code> |
| *policy_list* | Map of list org policies, status is true for allow, false for deny, null for restore. Values can only be used for allow or deny. | <code title="map&#40;object&#40;&#123;&#10;inherit_from_parent &#61; bool&#10;suggested_value     &#61; string&#10;status              &#61; bool&#10;values              &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| custom_role_id | Map of custom role IDs created in the organization. |  |
| custom_roles | Map of custom roles resources created in the organization. |  |
| firewall_policies | Map of firewall policy resources created in the organization. |  |
| firewall_policy_id | Map of firewall policy ids created in the organization. |  |
| organization_id | Organization id dependent on module resources. |  |
| sink_writer_identities | Writer identities created for each sink. |  |
<!-- END TFDOC -->
