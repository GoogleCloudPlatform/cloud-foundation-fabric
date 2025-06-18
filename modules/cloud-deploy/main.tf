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
  pipeline_type = "serial"
  target_iam_attributes = { for i, v in flatten([
    for target_key, target in var.targets : [
      for iam_key, iam in target.iam : {
        project_id = coalesce(target.project_id, var.project_id)
        region     = coalesce(target.region, var.region)
        target_id  = target.name
        role       = iam_key
        members    = iam
      }
    ]
    ]) : "${v.target_id}_${replace(v.role, "roles/", "")}" => v
  }
  compute_default_service_account = length(data.google_compute_default_service_account.default) > 0 ? data.google_compute_default_service_account.default[0].email : null
}

data "google_compute_default_service_account" "default" {
  count   = alltrue([for k, v in var.automations : v.service_account != null]) ? 0 : 1
  project = var.project_id
}