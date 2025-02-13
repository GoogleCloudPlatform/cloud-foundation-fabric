/**
 * Copyright 2022 Google LLC
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

output "external_ip" {
  description = "Instance main interface external IP addresses."
  value = (
    var.network_interfaces[0].nat
    ? try(google_compute_instance.default[0].network_interface[0].access_config[0].nat_ip, null)
    : null
  )
}

output "group" {
  description = "Instance group resource."
  value       = try(google_compute_instance_group.unmanaged[0], null)
}

output "id" {
  description = "Fully qualified instance id."
  value       = try(google_compute_instance.default[0].id, null)
}

output "instance" {
  description = "Instance resource."
  sensitive   = true
  value       = try(google_compute_instance.default[0], null)
}

output "internal_ip" {
  description = "Instance main interface internal IP address."
  value = try(
    google_compute_instance.default[0].network_interface[0].network_ip,
    null
  )
}

output "internal_ips" {
  description = "Instance interfaces internal IP addresses."
  value = [
    for nic in try(google_compute_instance.default[0].network_interface, [])
    : nic.network_ip
  ]
}

output "self_link" {
  description = "Instance self links."
  value       = try(google_compute_instance.default[0].self_link, null)
}

output "service_account" {
  description = "Service account resource."
  value       = try(google_service_account.service_account[0], null)
}

output "service_account_email" {
  description = "Service account email."
  value       = try(local.service_account.email, null)
}

output "service_account_iam_email" {
  description = "Service account email."
  value = (
    try(local.service_account.email, null) == null
    ? null
    : "serviceAccount:${local.service_account.email}"
  )
}

output "template" {
  description = "Template resource."
  value       = try(google_compute_instance_template.default[0], null)
}

output "template_name" {
  description = "Template name."
  value       = try(google_compute_instance_template.default[0].name, null)
}
