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

output "cloud_run_service" {
  description = "CloudRun service URL."
  value       = module.cloud_run.service.status[0].url
  sensitive   = true
}

output "cloudsql_password" {
  description = "CloudSQL password."
  value       = var.cloudsql_password == null ? module.cloudsql.user_passwords[local.cloudsql_conf.user] : var.cloudsql_password
  sensitive   = true
}

output "phpipam_ip_address" {
  description = "PHPIPAM IP Address either external or internal according to app exposure."
  value       = local.glb_create ? module.addresses.0.global_addresses["phpipam"].address : module.ilb-l7.0.address
}

output "phpipam_password" {
  description = "PHPIPAM user password."
  value       = local.phpipam_password
  sensitive   = true
}

output "phpipam_url" {
  description = "PHPIPAM website url."
  value       = local.domain
}

output "phpipam_user" {
  description = "PHPIPAM username."
  value       = "admin"
}
