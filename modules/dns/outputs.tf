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

output "type" {
  description = "The DNS zone type."
  value       = var.type
}

output "zone" {
  description = "DNS zone resource."
  value       = local.zone
}

output "name" {
  description = "The DNS zone name."
  value       = local.zone.name
}

output "domain" {
  description = "The DNS zone domain."
  value       = local.zone.dns_name
}

output "name_servers" {
  description = "The DNS zone name servers."
  value       = local.zone.name_servers
}
