/**
 * Copyright 2021 Google LLC
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

output "sa_group_id" {
  description = "Service Account group IDs"
  value = var.only_add_permissions ? {} : { for env in var.environments :
  env => google_cloud_identity_group.sa_group[env].id }
}

output "sa_group_keys" {
  description = "Service Account group keys"
  value = var.only_add_permissions ? {} : { for env in var.environments :
  env => google_cloud_identity_group.sa_group[env].group_key }
}
