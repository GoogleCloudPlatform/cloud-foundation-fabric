/**
 * Copyright 2024 Google LLC
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

# any changes to this factory should be mirrored in the project factory

locals {
  _factory_data = {
    for f in fileset(local._factory_path, "**/*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${local._factory_path}/${f}"))
  }
  _factory_path = try(pathexpand(var.factories_config.budgets_data_path), "")
  factory_budgets = {
    for k, v in local._factory_data : k => merge(v, {
      amount = merge(
        {
          currency_code   = null
          nanos           = null
          units           = null
          use_last_period = null
        },
        try(v.amount, {})
      )
      display_name    = try(v.display_name, null)
      ownership_scope = try(v.ownership_scope, null)
      filter = try(v.filter, null) == null ? null : {
        credit_types_treatment = (
          try(v.filter.credit_types_treatment, null) == null
          ? null
          : merge(
            { exclude_all = null, include_specified = null },
            v.filter.credit_types_treatment
          )
        )
        label              = try(v.filter.label, null)
        projects           = try(v.filter.projects, null)
        resource_ancestors = try(v.filter.resource_ancestors, null)
        services           = try(v.filter.services, null)
        subaccounts        = try(v.filter.subaccounts, null)
      }
      threshold_rules = [
        for vv in try(v.threshold_rules, []) : merge({
          percent          = null
          forecasted_spend = null
        }, vv)
      ]
      update_rules = {
        for kk, vv in try(v.update_rules, {}) : kk => merge({
          disable_default_iam_recipients   = null
          monitoring_notification_channels = null
          pubsub_topic                     = null
        }, vv)
      }
    })
  }
}

# check data coming from the factory as it bypasses variable validation rules

check "factory_budgets" {
  assert {
    condition = alltrue([
      for k, v in local.factory_budgets : v.amount != null && (
        try(v.amount.use_last_period, null) == true ||
        try(v.amount.units, null) != null
      )
    ])
    error_message = "Factory budgets need either amount units or last period set."
  }
  assert {
    condition = alltrue([
      for k, v in local.factory_budgets :
      v.threshold_rules == null || try(v.threshold_rules.percent, null) != null
    ])
    error_message = "Threshold rules need percent set."
  }
  assert {
    condition = alltrue(flatten([
      for k, v in local.factory_budgets : [
        for kk, vv in v.update_rules : [
          vv.monitoring_notification_channels != null
          ||
          vv.pubsub_topic != null
        ]
      ]
    ]))
    error_message = "Notification rules need either a pubsub topic or monitoring channels defined."
  }
}
