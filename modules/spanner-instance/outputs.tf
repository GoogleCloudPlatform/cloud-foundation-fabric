/**
 * Copyright 2024 Google LLC
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

output "spanner_database_ids" {
  description = "Spanner database ids."
  value       = { for k, v in google_spanner_database.spanner_databases : k => v.id }
}

output "spanner_databases" {
  description = "Spanner databases."
  value       = google_spanner_database.spanner_databases
}

output "spanner_instance" {
  description = "Spanner instance."
  value       = local.spanner_instance
}

output "spanner_instance_config" {
  description = "Spanner instance config."
  value       = try(var.instance.config.auto_create, null) == null ? null : google_spanner_instance_config.spanner_instance_config[0]
}

output "spanner_instance_config_id" {
  description = "Spanner instance config id."
  value       = try(var.instance.config.auto_create, null) == null ? null : google_spanner_instance_config.spanner_instance_config[0].id
}

output "spanner_instance_id" {
  description = "Spanner instance id."
  value       = local.spanner_instance.id
}
