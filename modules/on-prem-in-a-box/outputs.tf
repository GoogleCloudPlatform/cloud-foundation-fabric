/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "external_address" {
  value = google_compute_instance.on_prem_in_a_box.network_interface.0.access_config.0.nat_ip
}

output "internal_address" {
  value = google_compute_instance.on_prem_in_a_box.network_interface.0.network_ip
}

output "instance_name" {
  value = google_compute_instance.on_prem_in_a_box.name
}

output "vpn_ip_address" {
  value = cidrhost(var.local_ip_cidr_range, 2)
}

output "dns_ip_address" {
  value = cidrhost(var.local_ip_cidr_range, 3)
}

output "web_ip_address" {
  value = cidrhost(var.local_ip_cidr_range, 4)
}

output "toolbox_ip_address" {
  value = cidrhost(var.local_ip_cidr_range, 5)
}
