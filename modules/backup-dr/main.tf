/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_backup_dr_backup_vault" "backup_vault" {
  count                                      = var.name != null ? 1 : 0
  project                                    = var.project_id
  location                                   = var.location
  backup_vault_id                            = var.name
  description                                = var.vault_config.description
  backup_minimum_enforced_retention_duration = var.vault_config.backup_minimum_enforced_retention_duration
  annotations                                = var.vault_config.annotations
  labels                                     = var.vault_config.labels
  force_update                               = var.vault_config.force_update
  access_restriction                         = var.vault_config.access_restriction
  backup_retention_inheritance               = var.vault_config.backup_retention_inheritance
  ignore_inactive_datasources                = var.vault_config.ignore_inactive_datasources
  ignore_backup_plan_references              = var.vault_config.ignore_backup_plan_references
  allow_missing                              = var.vault_config.allow_missing
}

resource "google_backup_dr_backup_plan" "backup_plan" {
  for_each       = var.backup_plans
  project        = var.project_id
  backup_plan_id = each.key
  description    = each.value.description
  location       = var.location
  resource_type  = each.value.resource_type
  backup_vault   = var.vault_reuse != null ? var.vault_reuse.vault_id : one(google_backup_dr_backup_vault.backup_vault[*].id)

  dynamic "backup_rules" {
    for_each = each.value.backup_rules
    content {
      rule_id               = backup_rules.value.rule_id
      backup_retention_days = backup_rules.value.backup_retention_days

      standard_schedule {
        recurrence_type = backup_rules.value.standard_schedule.recurrence_type

        hourly_frequency = backup_rules.value.standard_schedule.hourly_frequency
        days_of_week     = backup_rules.value.standard_schedule.days_of_week
        days_of_month    = backup_rules.value.standard_schedule.days_of_month
        months           = backup_rules.value.standard_schedule.months
        dynamic "week_day_of_month" {
          for_each = try(backup_rules.value.standard_schedule.week_day_of_month != null ? [backup_rules.value.standard_schedule.week_day_of_month] : [])
          content {
            week_of_month = week_day_of_month.value.week_of_month
            day_of_week   = week_day_of_month.value.day_of_week
          }
        }
        time_zone = backup_rules.value.standard_schedule.time_zone
        backup_window {
          start_hour_of_day = backup_rules.value.standard_schedule.backup_window.start_hour_of_day
          end_hour_of_day   = backup_rules.value.standard_schedule.backup_window.end_hour_of_day
        }
      }
    }
  }
}

resource "google_backup_dr_management_server" "management_server" {
  count    = var.management_server_config != null ? 1 : 0
  project  = var.project_id
  location = coalesce(try(var.management_server_config.location), var.location)
  name     = var.management_server_config.name
  type     = var.management_server_config.type

  dynamic "networks" {
    for_each = var.management_server_config.network_config != null ? [var.management_server_config.network_config] : []
    content {
      network      = networks.value.network
      peering_mode = networks.value.peering_mode
    }
  }
}