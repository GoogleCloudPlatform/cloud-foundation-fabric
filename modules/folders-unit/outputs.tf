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

output "env_folders" {
  description = "Unit environments folders."
  value = {
    for key, folder in google_folder.environment
    : key => {
      id   = folder.name,
      name = folder.display_name
    }
  }
}

output "env_gcs_buckets" {
  description = "Unit environments tfstate gcs buckets."
  value = {
    for key, bucket in google_storage_bucket.tfstate
    : key => bucket.name
  }
}

output "env_sa_keys" {
  description = "Unit environments service account keys."
  sensitive   = true
  value = {
    for key, sa_key in google_service_account_key.keys :
    key => sa_key.private_key
  }
}

output "env_service_accounts" {
  description = "Unit environments service accounts."
  value = {
    for key, sa in google_service_account.environment
    : key => sa.email
  }
}

output "unit_folder" {
  description = "Unit top level folder."
  value = {
    id   = google_folder.unit.name,
    name = google_folder.unit.display_name
  }
}
