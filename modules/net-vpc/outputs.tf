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
  description = "Fully qualified network id."
  value       = local.network.id
  depends_on = [
    google_compute_network_peering.local,
    google_compute_network_peering.remote,
    google_compute_shared_vpc_host_project.shared_vpc_host,
    google_compute_shared_vpc_service_project.service_projects,
  ]
}

output "internal_ipv6_range" {
  description = "ULA range."
  value       = try(google_compute_network.network[0].internal_ipv6_range, null)
}

output "name" {
  description = "Network name."
  value       = local.network.name
  depends_on = [
    google_compute_network_peering.local,
    google_compute_network_peering.remote,
    google_compute_shared_vpc_host_project.shared_vpc_host,
  ]
}

output "network" {
  description = "Network resource."
  value       = local.network
  depends_on = [
    google_compute_network_peering.local,
    google_compute_network_peering.remote,
    google_compute_shared_vpc_host_project.shared_vpc_host,
    google_compute_shared_vpc_service_project.service_projects,
  ]
}


output "project_id" {
  description = "Project ID containing the network. Use this when you need to create resources *after* the VPC is fully set up (e.g. subnets created, shared VPC service projects attached, Private Service Networking configured)."
  value       = local.project_id
  depends_on = [
    google_compute_network_peering.local,
    google_compute_network_peering.remote,
    google_compute_shared_vpc_host_project.shared_vpc_host,
    google_compute_shared_vpc_service_project.service_projects,
  ]
}

output "routers" {
  description = "Router resources."
  value       = google_compute_router.routers
}

output "router_ids" {
  description = "Router IDs, keyed by router name."
  value       = { for k, v in google_compute_router.routers : k => v.id }
}

output "self_link" {
  description = "Network self link."
  value       = local.network.self_link
  depends_on = [
    google_compute_network_peering.local,
    google_compute_network_peering.remote,
    google_compute_shared_vpc_host_project.shared_vpc_host,
    google_compute_shared_vpc_service_project.service_projects,
  ]
}

