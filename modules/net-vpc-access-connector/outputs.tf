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

output "id" {
  description = "Connector identifier (fully qualified connector ID)."
  value       = try(google_vpc_access_connector.connector[0].id, null)
}

output "name" {
  description = "Connector name."
  value       = try(google_vpc_access_connector.connector[0].name, null)
}

output "self_link" {
  description = "The URI of the created connector resource."
  value       = try(google_vpc_access_connector.connector[0].self_link, null)
}

output "state" {
  description = "State of the VPC access connector (e.g., READY, CREATING, DELETING)."
  value       = try(google_vpc_access_connector.connector[0].state, null)
}