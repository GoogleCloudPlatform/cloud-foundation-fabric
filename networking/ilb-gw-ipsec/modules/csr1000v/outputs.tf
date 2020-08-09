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

output "instance" {
  description = "Instance resource."
  value       = google_compute_instance.default
}

output "internal_ip" {
  description = "Instance main interface internal IP address"
  value       = google_compute_instance.default.network_interface.0.network_ip
}

output "internal_ips" {
  description = "Instance internal IP addresses"
  value = [
    for i in google_compute_instance.default.network_interface : i.network_ip
  ]
}


output "name" {
  description = "Instance name"
  value       = google_compute_instance.default.name
}

output "self_link" {
  description = "Instance self link."
  value       = google_compute_instance.default.self_link
}
