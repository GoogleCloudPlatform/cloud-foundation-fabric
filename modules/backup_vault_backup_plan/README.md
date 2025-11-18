# Terraform Google Backup DR Plan

This Terraform module creates a Google Cloud Backup and DR backup plan and, optionally, a backup vault.

## Description

This module allows you to define a backup plan for your Google Cloud resources. You can specify backup rules, including schedules and retention policies. The module can also create a new backup vault or use an existing one.

## Usage

```hcl
module "backup_plan" {
  source = "path/to/this/module"

  project_id      = "your-gcp-project-id"
  location        = "us-central1"
  backup_vault_id = "my-backup-vault"
  backup_plan_id  = "my-backup-plan"

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
```

See the `examples/multi-resource-backup` directory for a more complex example.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [backup_plan_id](variables.tf#L50) | The resource ID of the Backup Plan. | <code>string</code> | ✓ |  |
| [backup_rules](variables.tf#L80) | A list of backup rules, including schedules and retention. | <code title="list&#40;object&#40;&#123;&#10;  rule_id               &#61; string&#10;  backup_retention_days &#61; number&#10;  standard_schedule &#61; object&#40;&#123;&#10;    recurrence_type  &#61; string&#10;    hourly_frequency &#61; optional&#40;number&#41;&#10;    days_of_week     &#61; optional&#40;list&#40;string&#41;&#41;&#10;    days_of_month    &#61; optional&#40;list&#40;number&#41;&#41;&#10;    months           &#61; optional&#40;list&#40;string&#41;&#41;&#10;    time_zone        &#61; string&#10;    backup_window &#61; object&#40;&#123;&#10;      start_hour_of_day &#61; number&#10;      end_hour_of_day   &#61; number&#10;    &#125;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [location](variables.tf#L140) | The region of the Backup Vault. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L152) | The ID of the GCP project in which resources will be created. | <code>string</code> | ✓ |  |
| [access_restriction](variables.tf#L16) | Access restriction policy for the vault. E.g., ACCESS_RESTRICTION_UNSPECIFIED, WITHIN_PROJECT, WITHIN_ORGANIZATION, UNRESTRICTED, or WITHIN_ORG_BUT_UNRESTRICTED_FOR_BA. | <code>string</code> |  | <code>&#34;WITHIN_ORGANIZATION&#34;</code> |
| [allow_missing](variables.tf#L32) | If true, the request succeeds even if the Backup Vault does not exist. (Used for deletion/update operations). | <code>string</code> |  | <code>&#34;false&#34;</code> |
| [annotations](variables.tf#L38) | User-defined key/value map of annotations. Required for certain features. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [backup_minimum_enforced_retention_duration](variables.tf#L44) | Minimum retention duration for backup data in the vault, specified in seconds (e.g., '100000s'). | <code>string</code> |  | <code>&#34;100000s&#34;</code> |
| [backup_plan_resource_type](variables.tf#L59) | The type of resource being backed up (e.g., 'compute.googleapis.com/Disk'). | <code>string</code> |  | <code>&#34;compute.googleapis.com&#47;Instance&#34;</code> |
| [backup_retention_inheritance](variables.tf#L74) | Controls if the vault inherits retention from the backup plan or uses its own retention policy. E.g., 'INHERIT_VAULT_RETENTION' or 'NO_INHERITANCE'. | <code>string</code> |  | <code>&#34;INHERIT_VAULT_RETENTION&#34;</code> |
| [backup_vault_id](variables.tf#L100) | The resource ID of the Backup Vault. Must contain only lowercase letters, numbers, and hyphens. | <code>string</code> |  | <code>null</code> |
| [create_backup_vault](variables.tf#L110) | If true, creates a new Backup Vault. If false, uses an existing Backup Vault specified by backup_vault_id. | <code>bool</code> |  | <code>true</code> |
| [force_update](variables.tf#L116) | Indicates if the resource should be force-updated. | <code>string</code> |  | <code>&#34;false&#34;</code> |
| [ignore_backup_plan_references](variables.tf#L122) | If true, allows deletion of the vault even if it's referenced by a backup plan. | <code>string</code> |  | <code>&#34;false&#34;</code> |
| [ignore_inactive_datasources](variables.tf#L128) | If true, allows deletion of the vault even if it contains inactive datasources. | <code>string</code> |  | <code>&#34;false&#34;</code> |
| [labels](variables.tf#L134) | User-defined key/value map of labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [plan_description](variables.tf#L145) | Backup Plan. | <code>string</code> |  | <code>&#34;Backup Vault managed by Terraform.&#34;</code> |
| [vault_description](variables.tf#L157) | Backup Vault | <code>string</code> |  | <code>&#34;Backup Vault managed by Terraform.&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [backup_plan_id](outputs.tf#L22) | The ID of the created Backup Plan. |  |
| [backup_vault_id](outputs.tf#L17) | The ID of the Backup Vault. |  |
<!-- END TFDOC -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| google | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google\_project\_service.api\_backup\_dr](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google\_backup\_dr\_backup\_vault.backup\_vault](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/backup_dr_backup_vault) | resource |
| [google\_backup\_dr\_backup\_plan.backup\_plan](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/backup_dr_backup_plan) | resource |