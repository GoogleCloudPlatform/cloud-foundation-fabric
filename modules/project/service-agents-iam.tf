/**
 * Copyright 2026 Google LLC
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

# tfdoc:file:description Service agent IAM bindings on external resources.

locals {
  service_agents_folder_bindings = {
    for k, v in var.service_agents_folder_bindings :
    k => v if contains(keys(local.aliased_service_agents), v.service)
  }
  service_agents_project_bindings = {
    for k, v in var.service_agents_project_bindings :
    k => v if contains(keys(local.aliased_service_agents), v.service)
  }
}

resource "google_folder_iam_member" "service_agents_folder_bindings" {
  for_each = local.service_agents_folder_bindings
  folder = lookup(
    local.ctx.folder_ids, each.value.folder, each.value.folder
  )
  role   = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member = local.aliased_service_agents[each.value.service].iam_email
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
  depends_on = [
    google_project_service.project_services,
    google_project_service_identity.default,
    google_project_default_service_accounts.default_service_accounts,
    data.google_bigquery_default_service_account.bq_sa,
    data.google_storage_project_service_account.gcs_sa,
    data.google_logging_project_settings.logging_sa
  ]
}

resource "google_project_iam_member" "service_agents_project_bindings" {
  for_each = local.service_agents_project_bindings
  project = lookup(
    local.ctx.project_ids, each.value.project, each.value.project
  )
  role   = lookup(local.ctx.custom_roles, each.value.role, each.value.role)
  member = local.aliased_service_agents[each.value.service].iam_email
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
  depends_on = [
    google_project_service.project_services,
    google_project_service_identity.default,
    google_project_default_service_accounts.default_service_accounts,
    data.google_bigquery_default_service_account.bq_sa,
    data.google_storage_project_service_account.gcs_sa,
    data.google_logging_project_settings.logging_sa
  ]
}
