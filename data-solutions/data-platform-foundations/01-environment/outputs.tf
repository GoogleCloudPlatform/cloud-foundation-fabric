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

output "project_ids" {
  description = "Project ids for created projects."
  value = {
    datamart       = module.project-datamart.project_id
    dwh            = module.project-dwh.project_id
    landing        = module.project-landing.project_id
    services       = module.project-services.project_id
    transformation = module.project-transformation.project_id
  }
}

output "service_encryption_key_ids" {
  description = "Cloud KMS encryption keys in {LOCATION => [KEY_URL]} format."
  value       = var.service_encryption_key_ids
}

output "service_account" {
  description = "Main service account."
  value       = module.sa-services-main.email
}
