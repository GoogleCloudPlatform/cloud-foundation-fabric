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
  description = "Route identifier (fully qualified route ID)."
  value       = try(google_compute_route.route[0].id, null)
}

output "name" {
  description = "Route name."
  value       = try(google_compute_route.route[0].name, null)
}

output "next_hop_network" {
  description = "The URL of the network to which this route applies."
  value       = try(google_compute_route.route[0].next_hop_network, null)
}

output "self_link" {
  description = "The URI of the created route resource."
  value       = try(google_compute_route.route[0].self_link, null)
}