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
    "roles/resourcemanager.projectCreator" = ["group:cloud-admins@example.org"]
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
# tftest modules=1 resources=6
```

## IAM

There are several mutually exclusive ways of managing IAM in this module

- non-authoritative via the `iam_additive` and `iam_additive_members` variables, where bindings created outside this module will coexist with those managed here
- authoritative via the `group_iam` and `iam` variables, where bindings created outside this module (eg in the console) will be removed at each `terraform apply` cycle if the same role is also managed here
- authoritative policy via the `iam_bindings_authoritative` variable, where any binding created outside this module (eg in the console) will be removed at each `terraform apply` cycle regardless of the role

If you set audit policies via the `iam_audit_config_authoritative` variable, be sure to also configure IAM bindings via `iam_bindings_authoritative`, as audit policies use the underlying `google_organization_iam_policy` resource, which is also authoritative for any role.

Some care must also be takend with the `groups_iam` variable (and in some situations with the additive variables) to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

## Hierarchical firewall policies

Hirerarchical firewall policies can be managed in two ways:

- via the `firewall_policies` variable, to directly define policies and rules in Terraform
- via the `firewall_policy_factory` variable, to leverage external YaML files via a simple "factory" embedded in the module ([see here](../../examples/factories) for more context on factories)

Once you have policies (either created via the module or externally), you can associate them using the `firewall_policy_association` variable.

### Directly defined firewall policies

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
  firewall_policy_association = {
    iap_policy = "iap-policy"
  }
}
# tftest modules=1 resources=3
```

### Firewall policy factory

The in-built factory allows you to define a single policy, using one file for rules, and an optional file for CIDR range substitution variables. Remember that non-absolute paths are relative to the root module (the folder where you run `terraform`).

```hcl
module "org" {
  source          = "./modules/organization"
  organization_id = var.organization_id
  firewall_policy_factory = {
    cidr_file   = "data/cidrs.yaml"
    policy_name = null
    rules_file  = "data/rules.yaml"
  }
  firewall_policy_association = {
    factory-policy = module.org.firewall_policy_id["factory"]
  }
}
# tftest skip
```

```yaml
# cidrs.yaml

rfc1918:
  - 10.0.0.0/8
  - 172.16.0.0/12
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
      type                 = "storage"
      destination          = module.gcs.name
      filter               = "severity=WARNING"
      include_children     = true
      bq_partitioned_table = null
      exclusions           = {}
    }
    info = {
      type                 = "bigquery"
      destination          = module.dataset.id
      filter               = "severity=INFO"
      include_children     = true
      bq_partitioned_table = true
      exclusions           = {}
    }
    notice = {
      type                 = "pubsub"
      destination          = module.pubsub.id
      filter               = "severity=NOTICE"
      include_children     = true
      bq_partitioned_table = null
      exclusions           = {}
    }
    debug = {
      type                 = "logging"
      destination          = module.bucket.id
      filter               = "severity=DEBUG"
      include_children     = false
      bq_partitioned_table = null
      exclusions           = {
        no-compute = "logName:compute"
      }
    }
  }
  logging_exclusions = {
    no-gce-instances = "resource.type=gce_instance"
  }
}
# tftest modules=5 resources=13
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
# tftest modules=1 resources=2
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [organization_id](variables.tf#L141) | Organization id in organizations/nnnnnn format. | <code>string</code> | ✓ |  |
| [contacts](variables.tf#L17) | List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [custom_roles](variables.tf#L23) | Map of role name => list of permissions to create in this project. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [firewall_policies](variables.tf#L29) | Hierarchical firewall policy rules created in the organization. | <code title="map&#40;map&#40;object&#40;&#123;&#10;  action                  &#61; string&#10;  description             &#61; string&#10;  direction               &#61; string&#10;  logging                 &#61; bool&#10;  ports                   &#61; map&#40;list&#40;string&#41;&#41;&#10;  priority                &#61; number&#10;  ranges                  &#61; list&#40;string&#41;&#10;  target_resources        &#61; list&#40;string&#41;&#10;  target_service_accounts &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;&#41;">map&#40;map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [firewall_policy_association](variables.tf#L46) | The hierarchical firewall policy to associate to this folder. Must be either a key in the `firewall_policies` map or the id of a policy defined somewhere else. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [firewall_policy_factory](variables.tf#L52) | Configuration for the firewall policy factory. | <code title="object&#40;&#123;&#10;  cidr_file   &#61; string&#10;  policy_name &#61; string&#10;  rules_file  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [group_iam](variables.tf#L62) | Authoritative IAM binding for organization groups, in {GROUP_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L68) | IAM bindings, in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_additive](variables.tf#L74) | Non authoritative IAM bindings, in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_additive_members](variables.tf#L80) | IAM additive bindings in {MEMBERS => [ROLE]} format. This might break if members are dynamic values. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_audit_config](variables.tf#L86) | Service audit logging configuration. Service as key, map of log permission (eg DATA_READ) and excluded members as value for each service. | <code>map&#40;map&#40;list&#40;string&#41;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_audit_config_authoritative](variables.tf#L97) | IAM Authoritative service audit logging configuration. Service as key, map of log permission (eg DATA_READ) and excluded members as value for each service. Audit config should also be authoritative when using authoritative bindings. Use with caution. | <code>map&#40;map&#40;list&#40;string&#41;&#41;&#41;</code> |  | <code>null</code> |
| [iam_bindings_authoritative](variables.tf#L108) | IAM authoritative bindings, in {ROLE => [MEMBERS]} format. Roles and members not explicitly listed will be cleared. Bindings should also be authoritative when using authoritative audit config. Use with caution. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>null</code> |
| [logging_exclusions](variables.tf#L114) | Logging exclusions for this organization in the form {NAME -> FILTER}. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_sinks](variables.tf#L120) | Logging sinks to create for this organization. | <code title="map&#40;object&#40;&#123;&#10;  destination          &#61; string&#10;  type                 &#61; string&#10;  filter               &#61; string&#10;  include_children     &#61; bool&#10;  bq_partitioned_table &#61; bool&#10;  exclusions &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [policy_boolean](variables.tf#L150) | Map of boolean org policies and enforcement value, set value to null for policy restore. | <code>map&#40;bool&#41;</code> |  | <code>&#123;&#125;</code> |
| [policy_list](variables.tf#L156) | Map of list org policies, status is true for allow, false for deny, null for restore. Values can only be used for allow or deny. | <code title="map&#40;object&#40;&#123;&#10;  inherit_from_parent &#61; bool&#10;  suggested_value     &#61; string&#10;  status              &#61; bool&#10;  values              &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [custom_role_id](outputs.tf#L18) | Map of custom role IDs created in the organization. |  |
| [custom_roles](outputs.tf#L31) | Map of custom roles resources created in the organization. |  |
| [firewall_policies](outputs.tf#L36) | Map of firewall policy resources created in the organization. |  |
| [firewall_policy_id](outputs.tf#L41) | Map of firewall policy ids created in the organization. |  |
| [organization_id](outputs.tf#L46) | Organization id dependent on module resources. |  |
| [sink_writer_identities](outputs.tf#L60) | Writer identities created for each sink. |  |

<!-- END TFDOC -->
