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

module "secops-tenant-secrets" {
  source     = "../../../modules/secret-manager"
  project_id = module.project.project_id
  secrets = merge({
    (local.secops_api_key_secret_key) = {
      locations = [var.region]
    }
    }, local.workspace_log_ingestion ? {
    (local.secops_workspace_int_sa_key) = {
      locations = [var.region]
    } } : {}
  )
  versions = merge({
    (local.secops_api_key_secret_key) = {
      latest = {
        enabled = true, data = google_apikeys_key.feed_api_key.key_string
      }
    }
    }, local.workspace_log_ingestion ? {
    (local.secops_workspace_int_sa_key) = {
      latest = {
        enabled = true, data = google_service_account_key.workspace_integration_key[0].private_key
      }
    }
  } : {})
  labels = merge({
    (local.secops_api_key_secret_key) = { scope = "secops" }
    }, local.workspace_log_ingestion ? {
    (local.secops_workspace_int_sa_key) = { scope = "secops" }
  } : {})
}
