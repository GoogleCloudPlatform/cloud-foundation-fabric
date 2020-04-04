/**
 * Copyright 2019 Google LLC
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
  value = (
    var.network_interfaces[0].nat
    ? [
      for name, instance in google_compute_instance.default :
      try(instance.network_interface.0.access_config.0.nat_ip, null)
    ]
    : []
  )
}

output "group" {
  description = "Instance group resource."
  value = (
    length(google_compute_instance_group.unmanaged) > 0
    ? google_compute_instance_group.unmanaged.0
    : null
  )
}

output "group_manager" {
  description = "Instance group resource."
  value = (
    length(google_compute_instance_group_manager.managed) > 0
    ? google_compute_instance_group_manager.managed.0
    : (
      length(google_compute_region_instance_group_manager.managed) > 0
      ? google_compute_region_instance_group_manager.managed.0
      : null
    )
  )
}

output "instances" {
  description = "Instance resources."
  value       = [for name, instance in google_compute_instance.default : instance]
}

output "internal_ips" {
  description = "Instance main interface internal IP addresses."
  value = [
    for name, instance in google_compute_instance.default :
    instance.network_interface.0.network_ip
  ]
}

output "names" {
  description = "Instance names."
  value       = [for name, instance in google_compute_instance.default : instance.name]
}

output "self_links" {
  description = "Instance self links."
  value       = [for name, instance in google_compute_instance.default : instance.self_link]
}

output "service_account" {
  description = "Service account resource."
  value = (
    var.service_account_create ? google_service_account.service_account[0] : null
  )
}

output "service_account_email" {
  description = "Service account email."
  value       = local.service_account_email
}

output "service_account_iam_email" {
  description = "Service account email."
  value = join("", [
    "serviceAccount:",
    local.service_account_email == null ? "" : local.service_account_email
  ])
}

output "template" {
  description = "Template resource."
  value = (
    length(google_compute_instance_template.default) > 0
    ? google_compute_instance_template.default[0]
    : null
  )
}

output "template_name" {
  description = "Template name."
  value = (
    length(google_compute_instance_template.default) > 0
    ? google_compute_instance_template.default[0].name
    : null
  )
}
