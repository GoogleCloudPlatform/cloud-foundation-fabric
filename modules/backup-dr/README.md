# Terraform Google Backup DR Plan

This Terraform module creates a Google Cloud Backup and DR backup plan and, optionally, a backup vault.

## Description

This module allows you to define a backup plan for your Google Cloud resources. You can specify backup rules, including schedules and retention policies. The module can also create a new backup vault or use an existing one.

## Examples

<!-- BEGIN TOC -->
- [Description](#description)
- [Examples](#examples)
  - [Create backup vault (basic usage)](#create-backup-vault-basic-usage)
  - [Create backup vault (extended options)](#create-backup-vault-extended-options)
  - [Create vault and plan](#create-vault-and-plan)
  - [Create only backup plan with existing vault](#create-only-backup-plan-with-existing-vault)
  - [Create management_server](#create-management_server)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

### Create backup vault (basic usage)
```hcl
module "dr_example" {
  source     = "./fabric/modules/backup-dr"
  project_id = "your-gcp-project-id"
  location   = "us-central1"
  name       = "backup-vault-01"
}
# tftest modules=1 resources=1
```

### Create backup vault (extended options)
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
# tftest inventory=extended.yaml
```

### Create vault and plan
```hcl
module "dr_example" {
  source     = "./fabric/modules/backup-dr"
  project_id = "your-gcp-project-id"
  location   = "us-central1"
  name       = "backup-vault"

  backup_plans = {
    my-backup-plan = {
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
# tftest inventory=vault-plan.yaml
```

### Create only backup plan with existing vault
```hcl
module "dr_example" {
  source     = "./fabric/modules/backup-dr"
  project_id = "your-gcp-project-id"
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
# tftest inventory=reuse.yaml
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
# tftest inventory=server.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [location](variables.tf#L47) | Location for the Backup Vault and Plans (e.g. us-central1). | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L71) | Project ID. | <code>string</code> | ✓ |  |
| [backup_plans](variables.tf#L17) | Map of Backup Plans to create in this Vault. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [management_server_config](variables.tf#L52) | Configuration to create a Management Server. If null, no server is created. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [name](variables.tf#L65) | Name of the Backup Vault to create. Leave null if reusing an existing vault via `vault_reuse`. | <code>string</code> |  | <code>null</code> |
| [vault_config](variables.tf#L76) | Configuration for the Backup Vault. Only used if `vault_reuse` is null. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [vault_reuse](variables.tf#L93) | Configuration to reuse an existing Backup Vault. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [backup_plans](outputs.tf#L16) | The ID of the created Backup Plans. |  |
| [backup_vault_id](outputs.tf#L21) | The ID of the Backup Vault. |  |
| [management_server](outputs.tf#L26) | The Management Server created. |  |
| [management_server_uri](outputs.tf#L31) | The Management Server ID created. |  |
<!-- END TFDOC -->
