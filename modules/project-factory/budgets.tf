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

# tfdoc:file:description Billing budget factory locals.

locals {
  budgets_enabled = (
    var.factories_config.budgets.billing_account != null &&
    local.paths.budgets != null
  )
  budget_folder_sets = flatten([
    for k, v in local.folders_input : [
      for vv in try(v.billing_budgets, []) : {
        folder = k
        budget = replace(vv, "$billing_budgets:", "")
      } if trimspace(vv) != ""
    ]
  ])
  budget_project_sets = flatten([
    for k, v in local.projects_input : [
      for vv in try(v.billing_budgets, []) : {
        project = k
        budget  = replace(vv, "$billing_budgets:", "")
      } if trimspace(vv) != ""
    ]
  ])
}

module "billing-budgets" {
  source = "../billing-account"
  count  = local.budgets_enabled ? 1 : 0
  id     = var.factories_config.budgets.billing_account
  context = merge(local.ctx, {
    folder_ids = local.ctx.folder_ids
    folder_sets = {
      for v in local.budget_folder_sets :
      v.budget => local.folder_ids[v.folder]...
    }
    project_ids = local.ctx_project_ids
    project_sets = {
      for v in local.budget_project_sets :
      v.budget => "projects/${local.outputs_projects[v.project].number}"...
    }
    project_numbers = local.ctx_project_numbers
  })
  factories_config = {
    budgets_data_path = local.paths.budgets
  }
  budget_notification_channels = (
    var.notification_channels
  )
}
