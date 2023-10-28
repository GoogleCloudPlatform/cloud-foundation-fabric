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

resource "google_monitoring_notification_channel" "default" {
  for_each    = var.budget_notification_channels
  description = each.value.description
  display_name = coalesce(
    each.value.display_name, "Budget email notification ${each.key}."
  )
  project      = each.value.project_id
  enabled      = each.value.enabled
  force_delete = each.value.force_delete
  type         = each.value.type
  labels       = each.value.labels
  user_labels  = each.value.user_labels
  dynamic "sensitive_labels" {
    for_each = toset(coalesce(each.value.sensitive_labels, []))
    content {
      auth_token  = sensitive_labels.value.auth_token
      password    = sensitive_labels.value.password
      service_key = sensitive_labels.value.service_key
    }
  }
}

resource "google_billing_budget" "default" {
  for_each        = merge(local.factory_budgets, var.budgets)
  billing_account = var.id
  display_name    = each.value.display_name
  dynamic "amount" {
    for_each = each.value.amount.use_last_period == true ? [""] : []
    content {
      last_period_amount = true
    }
  }
  dynamic "amount" {
    for_each = each.value.amount.use_last_period != true ? [""] : []
    content {
      specified_amount {
        currency_code = each.value.amount.currency_code
        nanos         = each.value.amount.nanos
        units         = each.value.amount.units
      }
    }
  }
  budget_filter {
    calendar_period = try(each.value.filter.period.calendar, null)
    credit_types_treatment = (
      try(each.value.filter.credit_types_treatment.exclude_all, null) == true
      ? "EXCLUDE_ALL_CREDITS"
      : (
        try(each.value.filter.credit_types_treatment.include_specified, null) != null
        ? "INCLUDE_SPECIFIED_CREDITS"
        : "INCLUDE_ALL_CREDITS"
      )
    )
    labels = each.value.filter.label == null ? null : {
      (each.value.filter.label.key) = each.value.filter.label.value
    }
    projects           = each.value.filter.projects
    resource_ancestors = each.value.filter.resource_ancestors
    services           = each.value.filter.services
    subaccounts        = each.value.filter.subaccounts
    dynamic "custom_period" {
      for_each = try(each.value.filter.period.custom, null) != null ? [""] : []
      content {
        start_date {
          day   = each.value.filter.period.custom.start_date.day
          month = each.value.filter.period.custom.start_date.month
          year  = each.value.filter.period.custom.start_date.year
        }
        dynamic "end_date" {
          for_each = try(each.value.filter.period.custom.end_date, null) != null ? [""] : []
          content {
            day   = each.value.filter.period.custom.end_date.day
            month = each.value.filter.period.custom.end_date.month
            year  = each.value.filter.period.custom.end_date.year
          }
        }
      }
    }
  }
  dynamic "threshold_rules" {
    for_each = toset(each.value.threshold_rules)
    iterator = rule
    content {
      threshold_percent = rule.value.percent
      spend_basis = (
        rule.value.forecasted_spend == true
        ? "FORECASTED_SPEND"
        : "CURRENT_SPEND"
      )
    }
  }
  dynamic "all_updates_rule" {
    for_each = each.value.update_rules
    iterator = rule
    content {
      pubsub_topic                   = rule.value.pubsub_topic
      schema_version                 = "1.0"
      disable_default_iam_recipients = rule.value.disable_default_iam_recipients
      monitoring_notification_channels = (
        rule.value.monitoring_notification_channels == null
        ? null
        : [
          for v in rule.value.monitoring_notification_channels : try(
            google_monitoring_notification_channel.default[v].id, v
          )
        ]
      )
    }
  }
}
