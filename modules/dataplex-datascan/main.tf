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
  data_quality_spec = {
    post_scan_actions = try(
      var.data_quality_spec.post_scan_actions,
      local.factory_data.post_scan_actions,
      null
    )
    row_filter = try(
      var.data_quality_spec.row_filter,
      local.factory_data.row_filter,
      null
    )
    rules = concat(
      try(var.data_quality_spec.rules, []),
      try(local.factory_data.rules, [])
    )
    sampling_percent = try(
      var.data_quality_spec.sampling_percent,
      local.factory_data.sampling_percent,
      null
    )
  }
  prefix = var.prefix == null || var.prefix == "" ? "" : "${var.prefix}-"
  use_data_quality = (
    var.data_quality_spec != null ||
    var.factories_config.data_quality_spec != null
  )
}

resource "google_dataplex_datascan" "datascan" {
  project      = var.project_id
  location     = var.region
  data_scan_id = "${local.prefix}${var.name}"
  display_name = "${local.prefix}${var.name}"
  description  = var.description == null ? "Terraform Managed." : "Terraform Managed. ${var.description}"
  labels       = var.labels

  data {
    resource = var.data.resource
    entity   = var.data.entity
  }

  execution_spec {
    field = var.incremental_field
    trigger {
      dynamic "on_demand" {
        for_each = var.execution_schedule == null ? [""] : []
        content {
        }
      }
      dynamic "schedule" {
        for_each = var.execution_schedule != null ? [""] : []
        content {
          cron = var.execution_schedule
        }
      }
    }
  }

  dynamic "data_profile_spec" {
    for_each = var.data_profile_spec != null ? [""] : []
    content {
      sampling_percent = try(var.data_profile_spec.sampling_percent, null)
      row_filter       = try(var.data_profile_spec.row_filter, null)
    }
  }

  dynamic "data_quality_spec" {
    for_each = local.use_data_quality ? [""] : []
    content {
      sampling_percent = try(local.data_quality_spec.sampling_percent, null)
      row_filter       = try(local.data_quality_spec.row_filter, null)
      dynamic "post_scan_actions" {
        for_each = local.data_quality_spec.post_scan_actions != null ? [""] : []
        content {
          dynamic "bigquery_export" {
            for_each = (
              local.data_quality_spec.post_scan_actions.bigquery_export != null
              ? [""]
              : []
            )
            content {
              results_table = try(
                local.data_quality_spec.post_scan_actions.bigquery_export.results_table,
                null
              )
            }
          }
        }
      }
      dynamic "rules" {
        for_each = local.data_quality_spec.rules
        content {
          column      = try(rules.value.column, null)
          ignore_null = try(rules.value.ignore_null, null)
          dimension   = rules.value.dimension
          threshold   = try(rules.value.threshold, null)

          dynamic "non_null_expectation" {
            for_each = try(rules.value.non_null_expectation, null) != null ? [""] : []
            content {
            }
          }

          dynamic "range_expectation" {
            for_each = (
              try(rules.value.range_expectation, null) != null ? [""] : []
            )
            content {
              min_value = try(
                rules.value.range_expectation.min_value, null
              )
              max_value = try(
                rules.value.range_expectation.max_value, null
              )
              strict_min_enabled = try(
                rules.value.range_expectation.strict_min_enabled, null
              )
              strict_max_enabled = try(
                rules.value.range_expectation.strict_max_enabled, null
              )
            }
          }

          dynamic "set_expectation" {
            for_each = (
              try(rules.value.set_expectation, null) != null ? [""] : []
            )
            content {
              values = rules.value.set_expectation.values
            }
          }

          dynamic "uniqueness_expectation" {
            for_each = (
              try(rules.value.uniqueness_expectation, null) != null ? [""] : []
            )
            content {
            }
          }

          dynamic "regex_expectation" {
            for_each = (
              try(rules.value.regex_expectation, null) != null ? [""] : []
            )
            content {
              regex = rules.value.regex_expectation.regex
            }
          }

          dynamic "statistic_range_expectation" {
            for_each = (
              try(rules.value.statistic_range_expectation, null) != null ? [""] : []
            )
            content {
              min_value = try(
                rules.value.statistic_range_expectation.min_value, null
              )
              max_value = try(
                rules.value.statistic_range_expectation.max_value, null
              )
              strict_min_enabled = try(
                rules.value.statistic_range_expectation.strict_min_enabled, null
              )
              strict_max_enabled = try(
                rules.value.statistic_range_expectation.strict_max_enabled, null
              )
              statistic = rules.value.statistic_range_expectation.statistic
            }
          }

          dynamic "row_condition_expectation" {
            for_each = (
              try(rules.value.row_condition_expectation, null) != null ? [""] : []
            )
            content {
              sql_expression = rules.value.row_condition_expectation.sql_expression
            }
          }

          dynamic "table_condition_expectation" {
            for_each = (
              try(rules.value.table_condition_expectation, null) != null ? [""] : []
            )
            content {
              sql_expression = rules.value.table_condition_expectation.sql_expression
            }
          }

          dynamic "sql_assertion" {
            for_each = (
              try(rules.value.sql_assertion, null) != null ? [""] : []
            )
            content {
              sql_statement = rules.value.sql_assertion.sql_statement
            }
          }

        }
      }
    }
  }

  lifecycle {
    precondition {
      condition = (
        length([
          for spec in [
            var.data_profile_spec,
            var.data_quality_spec,
            var.factories_config.data_quality_spec
          ] : spec if spec != null
        ]) == 1
      )
      error_message = "DataScan can only contain one of 'data_profile_spec', 'data_quality_spec', 'factories_config.data_quality_spec'."
    }
    precondition {
      condition = alltrue([
        for rule in try(local.data_quality_spec.rules, []) :
      contains(["COMPLETENESS", "ACCURACY", "CONSISTENCY", "VALIDITY", "UNIQUENESS", "INTEGRITY"], rule.dimension)])
      error_message = "Datascan 'dimension' field in 'data_quality_spec' must be one of ['COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'VALIDITY', 'UNIQUENESS', 'INTEGRITY']."
    }
    precondition {
      condition = alltrue([
        for rule in try(local.data_quality_spec.rules, []) :
        length([
          for k, v in rule :
          v if contains([
            "non_null_expectation",
            "range_expectation",
            "regex_expectation",
            "set_expectation",
            "uniqueness_expectation",
            "statistic_range_expectation",
            "row_condition_expectation",
            "table_condition_expectation",
            "sql_assertion"
          ], k) && v != null
      ]) == 1])
      error_message = "Datascan rule must contain a key that is one of ['non_null_expectation', 'range_expectation', 'regex_expectation', 'set_expectation', 'uniqueness_expectation', 'statistic_range_expectation', 'row_condition_expectation', 'table_condition_expectation', 'sql_assertion']."
    }
  }
}
