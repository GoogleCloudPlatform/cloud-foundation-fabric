/**
 * Copyright 2020 Google LLC
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

output "unit" {
  description = "Unit attributes."
  value = {
    name       = var.name
    folder     = google_folder.unit.name
    tf_gcs_buckets = {
      for env in keys(var.environments) 
      : env => google_storage_bucket.tfstate[env].name
    }
    env_folders = {
      for key, folder in google_folder.environment 
      : key => folder.name
    }
    service_accounts = {
      for key, sa in google_service_account.environment 
      : key => sa.email
    }
  }
}

output "keys" {
  description = "Service account keys."
  sensitive = true
  value = (
    var.generate_keys ? {
      for env in keys(var.environments) :
      env => lookup(google_service_account_key.keys, env, null)
    } : {}
  )
}


