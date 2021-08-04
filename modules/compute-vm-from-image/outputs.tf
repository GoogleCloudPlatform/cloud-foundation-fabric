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

 output "external_ips" {
  description = "Instance main interface external IP addresses."
  value = [
      for name, instance in google_compute_instance_from_machine_image.compute-vm-from-image :
      try(instance.network_interface.0.access_config.0.nat_ip, null)
    
  ]
}

output "instances" {
  description = "Instance resources."
  value       = [for name, instance in google_compute_instance_from_machine_image.compute-vm-from-image : instance]
}

output "internal_ips" {
  description = "Instance main interface internal IP addresses."
  value = [
    for name, instance in google_compute_instance_from_machine_image.compute-vm-from-image :
    instance.network_interface.0.network_ip
  ]
}

output "names" {
  description = "Instance names."
  value       = [for name, instance in google_compute_instance_from_machine_image.compute-vm-from-image : instance.name]
}

output "self_links" {
  description = "Instance self links."
  value       = [for name, instance in google_compute_instance_from_machine_image.compute-vm-from-image : instance.self_link]
}




