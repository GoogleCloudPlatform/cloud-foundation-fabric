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
  workspace_feeds = {
    ws-users = {
      log_type  = "WORKSPACE_USERS"
      feed_type = "workspace_users_settings"
    }
    ws-activity = {
      log_type  = "WORKSPACE_ACTIVITY"
      feed_type = "workspace_activity_settings"
    }
    ws-alerts = {
      log_type  = "WORKSPACE_ALERTS"
      feed_type = "workspace_alerts_settings"
    }
    ws-mobile = {
      log_type  = "WORKSPACE_MOBILE"
      feed_type = "workspace_mobile_settings"
    }
    ws-chrome = {
      log_type  = "WORKSPACE_CHROMEOS"
      feed_type = "workspace_chrome_os_settings"
    }
    ws-group = {
      log_type  = "WORKSPACE_GROUPS"
      feed_type = "workspace_groups_settings"
    }
  }
}

# Workspace logs integration SA
module "workspace-integration-sa" {
  source     = "../../../modules/iam-service-account"
  count      = local.workspace_log_ingestion ? 1 : 0
  project_id = module.project.project_id
  name       = "workspace-integration"
}

resource "google_service_account_key" "workspace_integration_key" {
  count              = local.workspace_log_ingestion ? 1 : 0
  service_account_id = module.workspace-integration-sa[0].email
}

resource "restful_resource" "workspace_feeds" {
  for_each        = local.workspace_log_ingestion ? local.workspace_feeds : {}
  path            = local.secops_feeds_api_path
  create_method   = "POST"
  delete_method   = "DELETE"
  check_existance = false
  delete_path     = "$query_unescape(body.name)"
  read_selector   = "feeds.#(displayName==\"${each.key}\")"
  body = {
    "display_name" : each.key,
    "details" : {
      "feed_source_type" : "API",
      "log_type" : "projects/${module.project.project_id}/locations/${var.tenant_config.region}/instances/${var.tenant_config.customer_id}/logTypes/${each.value.log_type}",
      "asset_namespace" : "",
      "labels" : {},
      (each.value.feed_type) : merge({
        "authentication" : {
          "token_endpoint" : "https://oauth2.googleapis.com/token",
          "claims" : {
            "issuer" : module.workspace-integration-sa[0].email,
            "subject" : var.workspace_integration_config.delegated_user,
            "audience" : "https://oauth2.googleapis.com/token"
          },
          rs_credentials : {
            private_key : jsondecode(base64decode(google_service_account_key.workspace_integration_key[0].private_key)).private_key
          }
        },
        workspace_customer_id : each.key == "ws-alerts" ? trimprefix(var.workspace_integration_config.workspace_customer_id, "C") : var.workspace_integration_config.workspace_customer_id
        }, each.key == "ws-activity" ? {
        applications : var.workspace_integration_config.applications
      } : {})
    }
  }
  write_only_attrs = ["details"]
  lifecycle {
    ignore_changes = [body, output]
  }
}
