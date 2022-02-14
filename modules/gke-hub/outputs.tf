/**
 * Copyright 2022 Google LLC
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

output "service_account" {
  description = "Service account resource."
  value = (
    local.hub_config.config_sync.workload_identity_sa == null
    ? google_service_account.gke-config-management-wid-sa[0]
    : null
  )
}

output "service_account_email" {
  description = "Service account email."
  value = (
    local.hub_config.config_sync.workload_identity_sa == null
    ? google_service_account.gke-config-management-wid-sa[0].email
    : null
  )
}

output "service_account_iam_email" {
  description = "Service account email."
  value = join("", [
    "serviceAccount:",
    local.hub_config.config_sync.workload_identity_sa == null ? google_service_account.gke-config-management-wid-sa[0].email : ""
  ])
}


output "sourcerepo_repository" {
  description = "Service account resource."
  value = (
    local.hub_config.config_sync.repository_url == null
    ? google_sourcerepo_repository.default[0]
    : null
  )
}

output "sourcerepo_repository_url" {
  description = "Source repository url."
  value = (
    local.hub_config.config_sync.repository_url == null
    ? google_sourcerepo_repository.default[0].url
    : null
  )
}
