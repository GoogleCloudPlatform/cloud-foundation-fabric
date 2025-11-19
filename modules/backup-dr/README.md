# Terraform Google Backup DR Plan

This Terraform module creates a Google Cloud Backup and DR backup plan and, optionally, a backup vault.

## Description

This module allows you to define a backup plan for your Google Cloud resources. You can specify backup rules, including schedules and retention policies. The module can also create a new backup vault or use an existing one.

## Examples

<!-- BEGIN TOC -->
- [Description](#description)
- [Examples](#examples)
  - [Create backup vault with minimal example](#create-backup-vault-with-minimal-example)
  - [Create backup vault with maximum example](#create-backup-vault-with-maximum-example)
  - [Create vault and plan](#create-vault-and-plan)
  - [Create only backup plan with existing vault](#create-only-backup-plan-with-existing-vault)
  - [Create management_server](#create-management_server)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

### Create backup vault with minimal example
```hcl
module "dr_example" {
  source     = "./fabric/modules/backup-dr"
  project_id = "your-gcp-project-id"
  location   = "us-central1"
  name       = "backup-vault-01"
}
# tftest modules=1 resources=1
```

### Create backup vault with maximum example
```hcl
module "dr_example" {
  source     = "./fabric/modules/backup-dr"
  project_id = "your-gcp-project-id"
  location   = "us-central1"
  name       = "backup-vault"
  vault_config = {
    access_restriction = "WITHIN_ORGANIZATION"
    annotations = {
      "key" = "value"
    }
    backup_minimum_enforced_retention_duration = "100000s"
    backup_retention_inheritance               = "INHERIT_VAULT_RETENTION"
    description                                = "Backup Vault managed by Terraform IAC."
    allow_missing                              = false
    force_update                               = false
    ignore_backup_plan_references              = false
    ignore_inactive_datasources                = false
    labels = {
      "key" = "value"
    }
  }
}
# tftest modules=1 resources=1
```

### Create vault and plan
```hcl
module "dr_example" {
  source     = "./fabric/modules/backup-dr"
  project_id = "your-gcp-project-id"
  location   = "us-central1"
  name       = "backup-vault"

  backup_plans = {
    "my-backup-plan" = {
      resource_type = "compute.googleapis.com/Instance"
      description   = "Backup Plan for GCE Instances."
      backup_rules = [
        {
          rule_id               = "daily-backup-rule"
          backup_retention_days = 30
          standard_schedule = {
            recurrence_type  = "HOURLY"
            hourly_frequency = 6
            time_zone        = "America/Los_Angeles"
            backup_window = {
              start_hour_of_day = 1
              end_hour_of_day   = 5
            }
          }
        },
        {
          rule_id               = "monthly-backup-rule"
          backup_retention_days = 30
          standard_schedule = {
            recurrence_type = "MONTHLY"
            time_zone       = "America/Los_Angeles"
            week_day_of_month = {
              week_of_month = "FIRST"
              day_of_week   = "MONDAY"
            }
            backup_window = {
              start_hour_of_day = 1
              end_hour_of_day   = 5
            }
          }
        }
      ]
    }
  }
}
# tftest modules=1 resources=2
```

### Create only backup plan with existing vault
```hcl
module "dr_example" {
  source     = "./fabric/modules/backup-dr"
  project_id = "yashwant-argolis"
  location   = "us-central1"

  vault_reuse = {
    vault_id = "backup-vault-test"
  }

  backup_plans = {
    "my-backup-plan" = {
      resource_type = "compute.googleapis.com/Instance"
      description   = "Backup Plan for GCE Instances."
      backup_rules = [
        {
          rule_id               = "daily-backup-rule"
          backup_retention_days = 30
          standard_schedule = {
            recurrence_type  = "HOURLY"
            hourly_frequency = 6
            time_zone        = "America/Los_Angeles"
            backup_window = {
              start_hour_of_day = 1
              end_hour_of_day   = 5
            }
          }
        },
        {
          rule_id               = "monthly-backup-rule"
          backup_retention_days = 30
          standard_schedule = {
            recurrence_type = "MONTHLY"
            time_zone       = "America/Los_Angeles"
            week_day_of_month = {
              week_of_month = "FIRST"
              day_of_week   = "MONDAY"
            }
            backup_window = {
              start_hour_of_day = 1
              end_hour_of_day   = 5
            }
          }
        }
      ]
    }
  }
}
# tftest modules=1 resources=1
```

### Create management_server
```hcl
module "dr_example" {
  source     = "./fabric/modules/backup-dr"
  project_id = "your-gcp-project-id"
  location   = "us-central1"

  management_server_config = {
    name     = "backup-dr-mgmt-server"
    location = "us-central1"
    type     = "BACKUP_RESTORE"
    network_config = {
      network      = "default"
      peering_mode = "PRIVATE_SERVICE_ACCESS"
    }
  }
}
# tftest modules=1 resources=1
```
See the `examples/multi-resource-backup` directory for a more complex example.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [location](variables.tf#L46) | Location for the Backup Vault and Plans (e.g. us-central1). | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L71) | Project ID. | <code>string</code> | ✓ |  |
| [backup_plans](variables.tf#L17) | Map of Backup Plans to create in this Vault. | <code title="map&#40;object&#40;&#123;&#10;  resource_type &#61; string&#10;  description   &#61; optional&#40;string&#41;&#10;  backup_rules &#61; list&#40;object&#40;&#123;&#10;    rule_id               &#61; string&#10;    backup_retention_days &#61; number&#10;    standard_schedule &#61; object&#40;&#123;&#10;      recurrence_type  &#61; string&#10;      hourly_frequency &#61; optional&#40;number&#41;&#10;      days_of_week     &#61; optional&#40;list&#40;string&#41;&#41;&#10;      days_of_month    &#61; optional&#40;list&#40;number&#41;&#41;&#10;      months           &#61; optional&#40;list&#40;string&#41;&#41;&#10;      week_day_of_month &#61; optional&#40;object&#40;&#123;&#10;        week_of_month &#61; string&#10;        day_of_week   &#61; string&#10;      &#125;&#41;&#41;&#10;      time_zone &#61; string&#10;      backup_window &#61; object&#40;&#123;&#10;        start_hour_of_day &#61; number&#10;        end_hour_of_day   &#61; number&#10;      &#125;&#41;&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [management_server_config](variables.tf#L51) | Configuration to create a Management Server. If null, no server is created. | <code title="object&#40;&#123;&#10;  name     &#61; string&#10;  type     &#61; optional&#40;string, &#34;BACKUP_RESTORE&#34;&#41;&#10;  location &#61; optional&#40;string&#41;&#10;  network_config &#61; optional&#40;object&#40;&#123;&#10;    network      &#61; string&#10;    peering_mode &#61; optional&#40;string, &#34;PRIVATE_SERVICE_ACCESS&#34;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [name](variables.tf#L65) | Name of the Backup Vault to create. Leave null if reusing an existing vault via `vault_reuse`. | <code>string</code> |  | <code>null</code> |
| [vault_config](variables.tf#L76) | Configuration for the Backup Vault. Only used if `vault_reuse` is null. | <code title="object&#40;&#123;&#10;  description                                &#61; optional&#40;string, &#34;Backup Vault managed by Terraform.&#34;&#41;&#10;  labels                                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  annotations                                &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  access_restriction                         &#61; optional&#40;string, &#34;WITHIN_ORGANIZATION&#34;&#41;&#10;  backup_minimum_enforced_retention_duration &#61; optional&#40;string, &#34;100000s&#34;&#41;&#10;  backup_retention_inheritance               &#61; optional&#40;string, &#34;INHERIT_VAULT_RETENTION&#34;&#41;&#10;  force_update                               &#61; optional&#40;bool, false&#41;&#10;  ignore_inactive_datasources                &#61; optional&#40;bool, false&#41;&#10;  ignore_backup_plan_references              &#61; optional&#40;bool, false&#41;&#10;  allow_missing                              &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [vault_reuse](variables.tf#L93) | Configuration to reuse an existing Backup Vault. | <code title="object&#40;&#123;&#10;  vault_id   &#61; string&#10;  location   &#61; optional&#40;string&#41;&#10;  project_id &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [backup_plans](outputs.tf#L16) | The ID of the created Backup Plans. |  |
| [backup_vault_id](outputs.tf#L21) | The ID of the Backup Vault. |  |
| [backup_vault_service_account](outputs.tf#L26) | The service account used by the Backup Vault. |  |
| [google_backup_dr_management_server](outputs.tf#L31) | The Management Server created. |  |
| [google_backup_dr_management_server_uri](outputs.tf#L36) | The Management Server ID created. |  |
<!-- END TFDOC -->
