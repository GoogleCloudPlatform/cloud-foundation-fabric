/**
 * Copyright 2024 Google LLC
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

locals {
  _all_instances = {
    primary   = google_alloydb_instance.primary
    secondary = one(google_alloydb_instance.secondary)
  }
}

output "id" {
  description = "Fully qualified primary instance id."
  value       = google_alloydb_instance.primary.id
}

output "ids" {
  description = "Fully qualified ids of all instances."
  value = {
    for id, instance in local._all_instances :
    id => try(instance.id, null)
  }
}

output "instances" {
  description = "AlloyDB instance resources."
  value       = local._all_instances
  sensitive   = true
}

output "ip" {
  description = "IP address of the primary instance."
  value       = google_alloydb_instance.primary.ip_address
}

output "ips" {
  description = "IP addresses of all instances."
  value = {
    for id, instance in local._all_instances : id => try(instance.ip_address, null)
  }
}

output "name" {
  description = "Name of the primary instance."
  value       = google_alloydb_instance.primary.name
}

output "names" {
  description = "Names of all instances."
  value = {
    for id, instance in local._all_instances :
    id => try(instance.name, null)
  }
}

output "psc_dns_name" {
  description = "AlloyDB Primary instance PSC DNS name."
  value       = try(google_alloydb_instance.primary.psc_instance_config[0].psc_dns_name, null)
}

output "psc_dns_names" {
  description = "AlloyDB instances PSC DNS names."
  value = {
    for id, instance in local._all_instances : id => try(instance.psc_instance_config[0].psc_dns_name, null)
  }
}

output "secondary_id" {
  description = "Fully qualified primary instance id."
  value       = var.cross_region_replication.enabled ? google_alloydb_instance.secondary[0].id : null
}

output "secondary_ip" {
  description = "IP address of the primary instance."
  value       = var.cross_region_replication.enabled ? google_alloydb_instance.secondary[0].ip_address : null
}

output "service_attachment" {
  description = "AlloyDB Primary instance service attachment."
  value       = try(google_alloydb_instance.primary.psc_instance_config[0].service_attachment_link, null)
}

output "service_attachments" {
  description = "AlloyDB instances service attachment."
  value = {
    for id, instance in local._all_instances : id => try(instance.psc_instance_config[0].service_attachment_link, null)
  }
}

output "user_passwords" {
  description = "Map of containing the password of all users created through terraform."
  value = {
    for name, user in google_alloydb_user.users :
    name => user.password
  }
  sensitive = true
}
