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
output "backup_plan_id" {
  description = "The ID of the created Backup Plan."
  value       = google_backup_dr_backup_plan.backup_plan.backup_plan_id
}

output "backup_vault_id" {
  description = "The ID of the Backup Vault."
  value       = var.backup_vault_create == true ? one(google_backup_dr_backup_vault.backup_vault[*].id) : var.backup_vault_id
}

output "backup_vault_service_account" {
  description = "The service account used by the Backup Vault."
  value       = var.backup_vault_create == true ? one(google_backup_dr_backup_vault.backup_vault[*].service_account) : null
}

output "google_backup_dr_backup_plan_associations" {
  description = "The Backup Plan Associations created."
  value       = google_backup_dr_backup_plan_association.backup_association
}

output "google_backup_dr_management_server" {
  description = "The Management Server created."
  value       = var.management_server_create ? google_backup_dr_management_server.management_server : null
}

output "google_backup_dr_management_server_id" {
  description = "The Management Server ID created."
  value       = var.management_server_create ? one(google_backup_dr_management_server.management_server[*].management_uri) : null
}