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
  description = "Subnet fully qualified id."
  value       = try(google_compute_subnetwork.subnet[0].id, null)
}

output "name" {
  description = "Subnet name."
  value       = try(google_compute_subnetwork.subnet[0].name, var.name)
}

output "region" {
  description = "Subnet region."
  value       = try(google_compute_subnetwork.subnet[0].region, var.region)
}

output "self_link" {
  description = "Subnet self link."
  value       = try(google_compute_subnetwork.subnet[0].self_link, null)
}

output "subnet" {
  description = "Subnet resource."
  value       = try(google_compute_subnetwork.subnet[0], null)
}

output "debug_ctx" {
  description = "Debug: Context after transformation"
  value       = local.ctx
}

output "debug_iam_by_principals" {
  description = "Debug: IAM by principals input"
  value       = var.iam_by_principals
}