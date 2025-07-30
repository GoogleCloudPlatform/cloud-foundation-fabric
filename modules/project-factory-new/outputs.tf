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

output "folder_ids" {
  value = local.folder_ids
}

output "iam_principals" {
  value = local.iam_principals
}

output "project_ids" {
  value = local.project_ids
}

output "projects" {
  value = {
    for k, v in local.projects_input : k => {
      number     = module.projects[k].number
      project_id = module.projects[k].project_id
      buckets = {
        for sk, sv in lookup(v, "buckets", {}) :
        "${k}/${sk}" => (
          module.buckets["${k}/${sk}"].name
        )
      }
      log_buckets = {
        for sk, sv in lookup(v, "log_buckets", {}) :
        "${k}/${sk}" => (
          module.log-buckets["${k}/${sk}"].id
        )
      }
      service_accounts = {
        for sk, sv in lookup(v, "service_accounts", {}) :
        "${k}/${sk}" => (
          module.service-accounts["${k}/${sk}"].email
        )
      }
    }
  }
}
