/**
 * Copyright 2018 Google LLC
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

output "project_id" {
  description = "Project id."
  value       = google_project.project.project_id
  depends_on = [
    google_project_organization_policy.boolean,
    google_project_organization_policy.list,
    google_project_service.project_services
  ]
}

output "name" {
  description = "Project ame."
  value       = google_project.project.name
  depends_on = [
    google_project_organization_policy.boolean,
    google_project_organization_policy.list,
    google_project_service.project_services
  ]
}

output "number" {
  description = "Project number."
  value       = google_project.project.number
  depends_on = [
    google_project_organization_policy.boolean,
    google_project_organization_policy.list,
    google_project_service.project_services
  ]
}

output "service_accounts" {
  description = "Product robot service accounts in project."
  value = {
    cloud_services = local.service_account_cloud_services
    default        = local.service_accounts_default
    robots         = local.service_accounts_robots
  }
  depends_on = [google_project_service.project_services]
}

output "custom_roles" {
  description = "Ids of the created custom roles."
  value       = [for role in google_project_iam_custom_role.roles : role.role_id]
}
