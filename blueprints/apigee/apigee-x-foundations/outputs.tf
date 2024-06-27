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

output "apigee_vpc" {
  description = "Apigee VPC."
  value       = var.network_config.apigee_vpc == null ? null : module.apigee_vpc[0]
}

output "apigee_vpc_id" {
  description = "Apigee VPC."
  value       = var.network_config.apigee_vpc == null ? null : module.apigee_vpc[0].id
}

output "apigee_vpc_self_link" {
  description = "Apigee VPC."
  value       = var.network_config.apigee_vpc == null ? null : module.apigee_vpc[0].self_link
}
output "endpoint_attachment_hosts" {
  description = "Endpoint attachment hosts."
  value       = module.apigee.endpoint_attachment_hosts
}

output "ext_lb_ip_address" {
  description = "External IP address."
  value       = var.ext_lb_config != null && length(local.ext_instances) > 0 ? module.ext_lb[0].address : null
}

output "instance_service_attachments" {
  description = "Instance service attachments."
  value       = { for k, v in module.apigee.instances : k => v.service_attachment }
}

output "int_cross_region_lb_ip_addresses" {
  description = "Internal IP addresses."
  value       = var.int_cross_region_lb_config != null && length(local.int_cross_region_instances) > 0 ? module.int_cross_region_lb[0].addresses : null
}

output "int_lb_ip_addresses" {
  description = "Internal IP addresses."
  value       = var.int_lb_config != null && length(local.int_instances) > 0 ? { for k, v in module.int_lb : k => v.address } : null
}

output "project" {
  description = "Project."
  value       = module.project
}

output "project_id" {
  description = "Project id."
  value       = module.project.project_id
}
