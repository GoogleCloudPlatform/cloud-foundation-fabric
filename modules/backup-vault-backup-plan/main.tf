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

# -----------------------------------------------------------------------------
# Resource for google_backup_dr_backup_vault
# -----------------------------------------------------------------------------
resource "google_backup_dr_backup_vault" "backup_vault" {
  count                                      = var.backup_vault_create == true ? 1 : 0
  project                                    = var.project_id
  location                                   = var.location
  backup_vault_id                            = var.backup_vault_id
  description                                = var.vault_description
  backup_minimum_enforced_retention_duration = var.backup_minimum_enforced_retention_duration
  annotations                                = var.annotations
  labels                                     = var.labels
  force_update                               = var.force_update
  access_restriction                         = var.access_restriction
  backup_retention_inheritance               = var.backup_retention_inheritance
  ignore_inactive_datasources                = var.ignore_inactive_datasources
  ignore_backup_plan_references              = var.ignore_backup_plan_references
  allow_missing                              = var.allow_missing
}

# -----------------------------------------------------------------------------
# Resource for google_backup_dr_backup_plan
# -----------------------------------------------------------------------------
resource "google_backup_dr_backup_plan" "backup_plan" {
  project        = var.project_id
  backup_plan_id = var.backup_plan_id
  description    = var.plan_description
  location       = var.location
  resource_type  = var.backup_plan_resource_type
  backup_vault   = var.backup_vault_create == true ? one(google_backup_dr_backup_vault.backup_vault[*].id) : var.backup_vault_id

  dynamic "backup_rules" {
    for_each = var.backup_rules
    content {
      rule_id               = backup_rules.value.rule_id
      backup_retention_days = backup_rules.value.backup_retention_days

      standard_schedule {
        recurrence_type = backup_rules.value.standard_schedule.recurrence_type

        hourly_frequency = try(backup_rules.value.standard_schedule.hourly_frequency, null)
        days_of_week     = try(backup_rules.value.standard_schedule.days_of_week, null)
        days_of_month    = try(backup_rules.value.standard_schedule.days_of_month, null)
        months           = try(backup_rules.value.standard_schedule.months, null)
        time_zone        = backup_rules.value.standard_schedule.time_zone

        backup_window {
          start_hour_of_day = backup_rules.value.standard_schedule.backup_window.start_hour_of_day
          end_hour_of_day   = backup_rules.value.standard_schedule.backup_window.end_hour_of_day
        }
      }
    }
  }
  depends_on = [google_backup_dr_backup_vault.backup_vault]
}