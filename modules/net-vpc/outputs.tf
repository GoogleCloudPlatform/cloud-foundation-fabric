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

output "network" {
  description = "Network resource."
  value       = local.network
  depends_on = [
    google_service_networking_connection.psn_connection
  ]
}

output "name" {
  description = "The name of the VPC being created."
  value       = local.network.name
  depends_on = [
    google_service_networking_connection.psn_connection
  ]
}

output "self_link" {
  description = "The URI of the VPC being created."
  value       = local.network.self_link
  depends_on = [
    google_service_networking_connection.psn_connection
  ]
}

output "project_id" {
  description = "Shared VPC host project id."
  value = (
    var.shared_vpc_host
    ? google_compute_shared_vpc_host_project.shared_vpc_host[*].project
    : null
  )
  depends_on = [
    google_compute_shared_vpc_host_project.shared_vpc_host,
    google_compute_shared_vpc_service_project.service_projects,
    google_service_networking_connection.psn_connection
  ]
}

# TODO(ludoo): use input names as keys
output "subnets" {
  description = "Subnet resources."
  value       = { for k, v in google_compute_subnetwork.subnetwork : k => v }
}

output "subnet_ips" {
  description = "Map of subnet address ranges keyed by name."
  value       = { for k, v in google_compute_subnetwork.subnetwork : k => v.ip_cidr_range }
}

output "subnet_self_links" {
  description = "Map of subnet self links keyed by name."
  value       = { for k, v in google_compute_subnetwork.subnetwork : k => v.self_link }
}

output "subnet_regions" {
  description = "Map of subnet regions keyed by name."
  value       = { for k, v in google_compute_subnetwork.subnetwork : k => v.region }
}

output "subnet_secondary_ranges" {
  description = "Map of subnet secondary ranges keyed by name."
  value = {
    for k, v in google_compute_subnetwork.subnetwork :
    k => {
      for range in v.secondary_ip_range :
      range.range_name => range.ip_cidr_range
    }
  }
}

output "bindings" {
  description = "Subnet IAM bindings."
  value       = { for k, v in google_compute_subnetwork_iam_binding.binding : k => v }
}
