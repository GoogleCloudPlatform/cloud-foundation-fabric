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

locals {
  secops_api_key_secret_key   = "secops-feeds-api-key"
  secops_workspace_int_sa_key = "secops-workspace-ing-sa-key"
  secops_project_id           = coalesce(try(var.secops_project_ids[var.stage_config.environment], null), var.project_id)
  secops_feeds_api_path       = "projects/${module.project.project_id}/locations/${var.tenant_config.region}/instances/${var.tenant_config.customer_id}/feeds"
  workspace_log_ingestion     = var.workspace_integration_config != null
}

module "project" {
  source          = "../../../modules/project"
  billing_account = var.project_reuse == null ? var.billing_account.id : null
  name            = local.secops_project_id
  parent          = var.folder_ids[var.stage_config.name]
  project_reuse   = var.project_reuse
  org_policies = var.workspace_integration_config != null ? {
    "iam.disableServiceAccountKeyCreation" = {
      rules = [{ enforce = false }]
    }
  } : {}
  services = concat([
    "apikeys.googleapis.com",
    "compute.googleapis.com",
    "iap.googleapis.com",
    "secretmanager.googleapis.com",
    "stackdriver.googleapis.com",
    "pubsub.googleapis.com",
    "cloudfunctions.googleapis.com",
    ],
    var.workspace_integration_config != null ? [
      "admin.googleapis.com",
      "alertcenter.googleapis.com"
    ] : [],
  )
  custom_roles = {
    "secopsDashboardViewer" = [
      "chronicle.dashboardCharts.get",
      "chronicle.dashboardCharts.list",
      "chronicle.dashboardQueries.execute",
      "chronicle.dashboardQueries.get",
      "chronicle.dashboardQueries.list",
      "chronicle.dashboards.get",
      "chronicle.dashboards.list",
      "chronicle.dashboards.schedule",
      "chronicle.nativeDashboards.get",
      "chronicle.nativeDashboards.list"
    ]
    "secopsDataViewer" = [
      "chronicle.legacies.legacyFindRawLogs",
      "chronicle.legacies.legacySearchRawLogs",
      "chronicle.referenceLists.get",
      "chronicle.referenceLists.update"
    ]
  }
  iam = {}
  iam_bindings_additive = merge(
    { for group in var.iam_default.admins :
    "${group}-admins" => { member = "group:${group}", role = "roles/chronicle.admin" } },
    { for group in var.iam_default.editors :
    "${group}-editors" => { member = "group:${group}", role = "roles/chronicle.editor" } },
    { for group in var.iam_default.editors :
    "${group}-viewers" => { member = "group:${group}", role = "roles/chronicle.viewer" } },
    { for k, v in var.iam :
      k => {
        member = k
        role   = "roles/chronicle.restrictedDataAccess"
        condition = {
          expression  = join(" || ", [for scope in v.scopes : "resource.name.endsWith('/${scope}')"])
          title       = "datarbac"
          description = "datarbac"
        }
      }
  })
  iam_by_principals_additive = { for k, v in var.iam : k => v.roles }
}

resource "google_apikeys_key" "feed_api_key" {
  project      = module.project.project_id
  name         = "secops-feed-key"
  display_name = "SecOps Feeds API Key"

  restrictions {
    api_targets {
      service = "chronicle.googleapis.com"
    }
  }
}

module "secops-rules" {
  source     = "../../../modules/secops-rules"
  project_id = local.secops_project_id
  tenant_config = {
    region      = var.tenant_config.region
    customer_id = var.tenant_config.customer_id
  }
  factories_config = var.factories_config
}
