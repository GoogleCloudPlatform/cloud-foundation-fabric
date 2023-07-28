/**
 * Copyright 2023 Google LLC
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

locals {
  prefix = var.prefix == null ? "" : "${var.prefix}-"
}

resource "google_dataplex_datascan" "datascan" {
  project      = var.project_id
  location     = var.region
  data_scan_id = "${local.prefix}${var.name}"
  display_name = "${local.prefix}${var.name}"
  description  = "Terraform Managed." # todo: parametrize
  labels       = var.labels

  data {
    resource = var.data.resource
    entity   = var.data.entity
  }

  execution_spec {
    field = var.incremental_field
    trigger {
      dynamic "on_demand" {
        for_each = try(var.execution_schedule) == null ? [""] : []
        content {
        }
      }
      dynamic "schedule" {
        for_each = try(var.execution_schedule) != null ? [""] : []
        content {
          cron = var.execution_schedule
        }
      }
    }
  }

  dynamic "data_profile_spec" {
    for_each = try(var.rules) == null ? [""] : []
    content {
      sampling_percent = var.sampling_percent
      row_filter       = var.row_filter
    }
  }

  dynamic "data_quality_spec" {
    for_each = try(var.rules) != null ? [""] : []
    content {
      sampling_percent = var.sampling_percent
      row_filter       = var.row_filter
      dynamic "rules" {
        for_each = var.rules
        content {
          column    = try(rules.value.column, null)
          dimension = rules.value.dimension
          threshold = try(rules.value.threshold, null)

          dynamic "non_null_expectation" {
            for_each = try(rules.value.non_null_expectation, null) != null ? [""] : []
            content {
            }
          }

          dynamic "range_expectation" {
            for_each = try(rules.value.range_expectation, null) != null ? [""] : []
            content {
              min_value          = try(rules.value.range_expectation.min_value, null)
              max_value          = try(rules.value.range_expectation.max_value, null)
              strict_min_enabled = try(rules.value.range_expectation.strict_min_enabled, null)
              strict_max_enabled = try(rules.value.range_expectation.strict_max_enabled, null)
            }
          }

          dynamic "set_expectation" {
            for_each = try(rules.value.set_expectation, null) != null ? [""] : []
            content {
              values = rules.value.set_expectation.values
            }
          }

          dynamic "uniqueness_expectation" {
            for_each = try(rules.value.uniqueness_expectation, null) != null ? [""] : []
            content {
            }
          }

          dynamic "regex_expectation" {
            for_each = try(rules.value.regex_expectation, null) != null ? [""] : []
            content {
              regex = rules.value.regex_expectation.regex
            }
          }

          dynamic "statistic_range_expectation" {
            for_each = try(rules.value.statistic_range_expectation, null) != null ? [""] : []
            content {
              min_value          = try(rules.value.statistic_range_expectation.min_value, null)
              max_value          = try(rules.value.statistic_range_expectation.max_value, null)
              strict_min_enabled = try(rules.value.statistic_range_expectation.strict_min_enabled, null)
              strict_max_enabled = try(rules.value.statistic_range_expectation.strict_max_enabled, null)
              statistic          = rules.value.statistic_range_expectation.statistic
            }
          }

          dynamic "row_condition_expectation" {
            for_each = try(rules.value.row_condition_expectation, null) != null ? [""] : []
            content {
              sql_expression = rules.value.row_condition_expectation.sql_expression
            }
          }

          dynamic "table_condition_expectation" {
            for_each = try(rules.value.table_condition_expectation, null) != null ? [""] : []
            content {
              sql_expression = rules.value.table_condition_expectation.sql_expression
            }
          }

        }
      }
    }
  }
}
