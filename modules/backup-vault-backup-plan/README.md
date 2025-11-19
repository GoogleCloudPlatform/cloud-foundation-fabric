# Terraform Google Backup DR Plan

This Terraform module creates a Google Cloud Backup and DR backup plan and, optionally, a backup vault.

## Description

This module allows you to define a backup plan for your Google Cloud resources. You can specify backup rules, including schedules and retention policies. The module can also create a new backup vault or use an existing one.

## Examples

<!-- BEGIN TOC -->
- [Description](#description)
- [Examples](#examples)
  - [Minimal example](#minimal-example)
  - [Create example with association with diff project resource](#create-example-with-association-with-diff-project-resource)
  - [Maximum example](#maximum-example)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

### Minimal example
```hcl
module "dr_plan_example_with_existing_vault" {
  source                    = "./fabric/modules/backup-vault-backup-plan" # Adjust the path as necessary
  project_id                = "your-gcp-project-id"
  location                  = "us-central1"
  backup_vault_id           = "my-backup-vault"
  backup_plan_id            = "my-backup-plan"
  backup_vault_create       = false
  backup_plan_resource_type = "compute.googleapis.com/Instance"

  backup_rules = [
    {
      rule_id               = "daily-backup"
      backup_retention_days = 30
      standard_schedule = {
        recurrence_type = "DAILY"
        time_zone       = "UTC"
        backup_window = {
          start_hour_of_day = 2
          end_hour_of_day   = 4
        }
      }
    }
  ]
}
# tftest modules=1 resources=1
```

### Create example with association with diff project resource
```hcl
module "dr_example" {
  source                                     = "./fabric/modules/backup-vault-backup-plan"
  project_id                                 = "project-id-12345"
  location                                   = "us-central1"
  backup_vault_id                            = "backup-vault-02"
  vault_description                          = "This is a backup vault built by Terraform."
  plan_description                           = "This is a backup plan built by Terraform."
  backup_minimum_enforced_retention_duration = "100000s"
  annotations = {
    annotations1 = "bar1"
    annotations2 = "baz1"
  }
  labels = {
    foo = "bar1"
    bar = "baz1"
  }
  force_update                  = "true"
  access_restriction            = "WITHIN_ORGANIZATION"
  backup_retention_inheritance  = "INHERIT_VAULT_RETENTION"
  ignore_inactive_datasources   = "true"
  ignore_backup_plan_references = "true"
  allow_missing                 = "true"
  backup_rules = [
    {
      rule_id               = "rule-1"
      backup_retention_days = 5
      standard_schedule = {
        recurrence_type  = "HOURLY"
        hourly_frequency = 4 # Required for HOURLY
        time_zone        = "UTC"
        backup_window = {
          start_hour_of_day = 0
          end_hour_of_day   = 6
        }
      }
    }
  ]
  backup_plan_id            = "backup-plan-test"
  backup_plan_resource_type = "compute.googleapis.com/Instance"

  backup_associations = {
    "5710079875457037878" = {
      resource_full_id = "projects/project-id-12345/zones/us-central1-a/instances/instance-1"
      resource_type    = "compute.googleapis.com/Instance"
      location         = "us-central1"
      project_id       = "project-id-12345"
    },
    "6774881012065854230" = {
      resource_full_id = "projects/project-id-12345/zones/us-central1-a/instances/instance-20251112-191939"
      resource_type    = "compute.googleapis.com/Instance"
      project_id       = "project-id-67890"
      location         = "us-central1"
    }
  }
}
# tftest modules=1 resources=4
```

### Maximum example
```hcl
module "dr_example" {
  source                                     = "./fabric/modules/backup-vault-backup-plan"
  project_id                                 = "project-id-12345"
  location                                   = "us-central1"
  backup_vault_id                            = "backup-vault-02"
  vault_description                          = "This is a backup vault built by Terraform."
  plan_description                           = "This is a backup plan built by Terraform."
  backup_minimum_enforced_retention_duration = "100000s"
  annotations = {
    annotations1 = "bar1"
    annotations2 = "baz1"
  }
  labels = {
    foo = "bar1"
    bar = "baz1"
  }
  force_update                  = true
  access_restriction            = "WITHIN_ORGANIZATION"
  backup_retention_inheritance  = "INHERIT_VAULT_RETENTION"
  ignore_inactive_datasources   = true
  ignore_backup_plan_references = true
  allow_missing                 = true
  backup_rules = [
    {
      rule_id               = "rule-1"
      backup_retention_days = 5
      standard_schedule = {
        recurrence_type  = "HOURLY"
        hourly_frequency = 4 # Required for HOURLY
        time_zone        = "UTC"
        backup_window = {
          start_hour_of_day = 0
          end_hour_of_day   = 6
        }
      }
    }
  ]
  backup_plan_id            = "backup-plan-test"
  backup_plan_resource_type = "compute.googleapis.com/Instance"

  backup_associations = {
    "5710079875457037878" = {
      resource_full_id = "projects/project-id-12345/zones/us-central1-a/instances/instance-1"
      resource_type    = "compute.googleapis.com/Instance"
      location         = "us-central1"
      project_id       = "project-id-12345"
    },
    "6774881012065854230" = {
      resource_full_id = "projects/project-id-12345/zones/us-central1-a/instances/instance-20251112-191939"
      resource_type    = "compute.googleapis.com/Instance"
      project_id       = "project-id-12345"
      location         = "us-central1"
    }
  }

  management_server_create = true
  management_server_config = {
    location               = "us-central1"
    management_server_name = "test-server"
    type                   = "BACKUP_RESTORE"
    network_config = {
      network      = "projects/project_id/global/networks/network_id"
      peering_mode = "PRIVATE_SERVICE_ACCESS"
    }
  }

  default_backup_dr_create = true
  default_backup_dr_configs = {
    "prj-region" = {
      location      = "us-central1"
      project       = "project-id-12345"
      resource_type = "compute.googleapis.com/Instance"
    }
  }
}
# tftest modules=1 resources=6
```

See the `examples/multi-resource-backup` directory for a more complex example.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [backup_plan_id](variables.tf#L51) | The resource ID of the Backup Plan. | <code>string</code> | ✓ |  |
| [backup_plan_resource_type](variables.tf#L56) | The type of resource being backed up (e.g., 'compute.googleapis.com/Disk'). | <code>string</code> | ✓ |  |
| [backup_rules](variables.tf#L85) | A list of backup rules, including schedules and retention. | <code title="list&#40;object&#40;&#123;&#10;  rule_id               &#61; string&#10;  backup_retention_days &#61; number&#10;  standard_schedule &#61; object&#40;&#123;&#10;    recurrence_type  &#61; string&#10;    hourly_frequency &#61; optional&#40;number&#41;&#10;    days_of_week     &#61; optional&#40;list&#40;string&#41;&#41;&#10;    days_of_month    &#61; optional&#40;list&#40;number&#41;&#41;&#10;    months           &#61; optional&#40;list&#40;string&#41;&#41;&#10;    time_zone        &#61; string&#10;    backup_window &#61; object&#40;&#123;&#10;      start_hour_of_day &#61; number&#10;      end_hour_of_day   &#61; number&#10;    &#125;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [location](variables.tf#L142) | The region of the Backup Vault. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L154) | The ID of the GCP project in which resources will be created. | <code>string</code> | ✓ |  |
| [access_restriction](variables.tf#L16) | Access restriction policy for the vault. E.g., ACCESS_RESTRICTION_UNSPECIFIED, WITHIN_PROJECT, WITHIN_ORGANIZATION, UNRESTRICTED, or WITHIN_ORG_BUT_UNRESTRICTED_FOR_BA. | <code>string</code> |  | <code>&#34;WITHIN_ORGANIZATION&#34;</code> |
| [allow_missing](variables.tf#L33) | If true, the request succeeds even if the Backup Vault does not exist. (Used for deletion/update operations). | <code>bool</code> |  | <code>false</code> |
| [annotations](variables.tf#L39) | User-defined key/value map of annotations. Required for certain features. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [backup_associations](variables.tf#L165) | A list of backup plan associations. resource id could be anything like instance id, disk id etc based on resource type. If project id or location is not provided, the project_id, location where backup plan is created will be used. | <code title="map&#40;object&#40;&#123;&#10;  resource_full_id &#61; string&#10;  resource_type    &#61; string&#10;  project_id       &#61; optional&#40;string&#41;&#10;  location         &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [backup_minimum_enforced_retention_duration](variables.tf#L45) | Minimum retention duration for backup data in the vault, specified in seconds (e.g., '100000s'). | <code>string</code> |  | <code>&#34;100000s&#34;</code> |
| [backup_retention_inheritance](variables.tf#L71) | Controls if the vault inherits retention from the backup plan or uses its own retention policy. E.g., 'INHERIT_VAULT_RETENTION' or 'NO_INHERITANCE'. | <code>string</code> |  | <code>&#34;INHERIT_VAULT_RETENTION&#34;</code> |
| [backup_vault_create](variables.tf#L111) | If true, creates a new Backup Vault. If false, uses an existing Backup Vault specified by backup_vault_id. | <code>bool</code> |  | <code>true</code> |
| [backup_vault_id](variables.tf#L105) | The resource ID of the Backup Vault. Must contain only lowercase letters, numbers, and hyphens. | <code>string</code> |  | <code>null</code> |
| [default_backup_dr_configs](variables.tf#L204) | Configuration for default Backup DR service config. If project_id or location is not provided, the project_id, location where backup plan is created will be used. | <code title="map&#40;object&#40;&#123;&#10;  project_id    &#61; optional&#40;string&#41;&#10;  location      &#61; optional&#40;string&#41;&#10;  resource_type &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [default_backup_dr_create](variables.tf#L197) | If true, enables default Backup DR service config for the specified resource type in the project and location. | <code>bool</code> |  | <code>false</code> |
| [force_update](variables.tf#L117) | Indicates if the resource should be force-updated. | <code>bool</code> |  | <code>false</code> |
| [ignore_backup_plan_references](variables.tf#L123) | If true, allows deletion of the vault even if it's referenced by a backup plan. | <code>bool</code> |  | <code>false</code> |
| [ignore_inactive_datasources](variables.tf#L129) | If true, allows deletion of the vault even if it contains inactive datasources. | <code>bool</code> |  | <code>false</code> |
| [labels](variables.tf#L135) | User-defined key/value map of labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [management_server_config](variables.tf#L183) | Configuration for the Management Server if created. | <code title="object&#40;&#123;&#10;  management_server_name &#61; string&#10;  location               &#61; string&#10;  type                   &#61; string&#10;  network_config &#61; optional&#40;object&#40;&#123;&#10;    network      &#61; string&#10;    peering_mode &#61; string&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [management_server_create](variables.tf#L176) | If true, creates a new Management Server for Backup DR. | <code>bool</code> |  | <code>false</code> |
| [plan_description](variables.tf#L147) | Backup Plan. | <code>string</code> |  | <code>&#34;Backup Vault managed by Terraform.&#34;</code> |
| [vault_description](variables.tf#L159) | Backup Vault. | <code>string</code> |  | <code>&#34;Backup Vault managed by Terraform.&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [backup_plan_id](outputs.tf#L16) | The ID of the created Backup Plan. |  |
| [backup_vault_id](outputs.tf#L21) | The ID of the Backup Vault. |  |
| [backup_vault_service_account](outputs.tf#L26) | The service account used by the Backup Vault. |  |
| [google_backup_dr_backup_plan_associations](outputs.tf#L31) | The Backup Plan Associations created. |  |
| [google_backup_dr_management_server](outputs.tf#L36) | The Management Server created. |  |
| [google_backup_dr_management_server_id](outputs.tf#L41) | The Management Server ID created. |  |
<!-- END TFDOC -->
