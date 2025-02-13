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

# tfdoc:file:description Billing budget factory locals.

locals {
  # reimplement the billing account factory here to interpolate projects
  _budget_path = try(pathexpand(var.factories_config.budgets.budgets_data_path), null)
  _budgets = (
    {
      for f in try(fileset(local._budget_path, "**/*.yaml"), []) :
      trimsuffix(f, ".yaml") => yamldecode(file("${local._budget_path}/${f}"))
    }
  )
  budgets = {
    for k, v in local._budgets : k => merge(v, {
      amount = merge(
        {
          currency_code   = null
          nanos           = null
          units           = null
          use_last_period = null
        },
        try(v.amount, {})
      )
      display_name = try(v.display_name, null)
      filter = try(v.filter, null) == null ? null : {
        credit_types_treatment = (
          try(v.filter.credit_types_treatment, null) == null
          ? null
          : merge(
            { exclude_all = null, include_specified = null },
            v.filter.credit_types_treatment
          )
        )
        label = try(v.filter.label, null)
        projects = concat(
          try(v.projects, []),
          [
            for p in lookup(local.project_budgets, k, []) :
            "projects/${module.projects[p].number}"
          ]
        )
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
