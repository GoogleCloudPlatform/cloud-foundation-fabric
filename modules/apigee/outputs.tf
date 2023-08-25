/**
 * Copyright 2023 Google LLC
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

output "endpoint_attachment_hosts" {
  description = "Endpoint hosts."
  value       = { for k, v in google_apigee_endpoint_attachment.endpoint_attachments : k => v.host }
}

output "envgroups" {
  description = "Environment groups."
  value       = try(google_apigee_envgroup.envgroups, null)
}

output "environments" {
  description = "Environment."
  value       = try(google_apigee_environment.environments, null)
}

output "instances" {
  description = "Instances."
  value       = try(google_apigee_instance.instances, null)
}

output "nat_ips" {
  description = "NAT IP addresses used in instances."
  value = {
    for k, v in google_apigee_nat_address.apigee_nat :
    k => v.ip_address
  }
}

output "org_id" {
  description = "Organization ID."
  value       = local.org_id
}

output "org_name" {
  description = "Organization name."
  value       = try(google_apigee_organization.organization[0].name, var.project_id)
}

output "organization" {
  description = "Organization."
  value       = try(google_apigee_organization.organization[0], null)
}

output "service_attachments" {
  description = "Service attachments."
  value       = { for k, v in google_apigee_instance.instances : k => v.service_attachment }
}
