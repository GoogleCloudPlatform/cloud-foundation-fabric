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

output "domain" {
  description = "Cloud Identity domain"
  value       = var.domain
}

output "project_ids" {
  description = "Project IDs"
  value       = { for env in var.environments : env => module.project-factory[env].project_id }
}

output "service_accounts" {
  description = "Project service accounts"
  value       = { for env in var.environments : env => replace(module.project-service-account[env].iam_email, "serviceAccount:", "") }
}

output "project_numbers" {
  description = "Project numbers"
  value       = { for env in var.environments : env => module.project-factory[env].number }
}

output "project_ids_per_environment" {
  description = "Project IDs mapped per environment"
  value       = { for env in var.environments : env => module.project-factory[env].project_id }
}
