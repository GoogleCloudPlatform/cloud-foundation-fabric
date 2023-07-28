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

  _group_iam_roles = distinct(flatten(values(var.group_iam)))
  _group_iam = {
    for r in local._group_iam_roles : r => [
      for k, v in var.group_iam : "group:${k}" if try(index(v, r), null) != null
    ]
  }
  _iam_additive_pairs = flatten([
    for role, members in var.iam_additive : [
      for member in members : { role = role, member = member }
    ]
  ])
  _iam_additive_member_pairs = flatten([
    for member, roles in var.iam_additive_members : [
      for role in roles : { role = role, member = member }
    ]
  ])
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local._group_iam))) :
    role => concat(
      try(var.iam[role], []),
      try(local._group_iam[role], [])
    )
  }
  iam_additive = {
    for pair in concat(local._iam_additive_pairs, local._iam_additive_member_pairs) :
    "${pair.role}-${pair.member}" => {
      role   = pair.role
      member = pair.member
    }
  }
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
        for_each = try(var.execution_trigger.on_demand, null) != null ? [""] : []
        content {
        }
      }
      dynamic "schedule" {
        for_each = try(var.execution_trigger.schedule, null) != null ? [""] : []
        content {
          cron = var.execution_trigger.schedule.cron
        }
      }
    }
  }

  dynamic "data_profile_spec" {
    for_each = try(var.rules) != null ? [] : [""]
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

resource "google_dataplex_datascan_iam_binding" "authoritative_for_role" {
  for_each     = local.iam
  project      = google_dataplex_datascan.datascan.project
  location     = google_dataplex_datascan.datascan.location
  data_scan_id = google_dataplex_datascan.datascan.data_scan_id
  role         = each.key
  members      = each.value
}

resource "google_dataplex_datascan_iam_member" "additive" {
  for_each = (
    length(var.iam_additive) + length(var.iam_additive_members) > 0
    ? local.iam_additive
    : {}
  )
  project      = google_dataplex_datascan.datascan.project
  location     = google_dataplex_datascan.datascan.location
  data_scan_id = google_dataplex_datascan.datascan.data_scan_id
  role         = each.value.role
  member       = each.value.member
}

resource "google_dataplex_datascan_iam_policy" "authoritative_for_resource" {
  count        = var.iam_policy != null ? 1 : 0
  project      = google_dataplex_datascan.datascan.project
  location     = google_dataplex_datascan.datascan.location
  data_scan_id = google_dataplex_datascan.datascan.data_scan_id
  policy_data  = data.google_iam_policy.authoritative.0.policy_data
}

data "google_iam_policy" "authoritative" {
  count = var.iam_policy != null ? 1 : 0
  dynamic "binding" {
    for_each = try(var.iam_policy, {})
    content {
      role    = binding.key
      members = binding.value
    }
  }
}

