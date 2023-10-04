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

output "dns_keys" {
  description = "DNSKEY and DS records of DNSSEC-signed managed zones."
  value       = try(data.google_dns_keys.dns_keys, null)
}

output "domain" {
  description = "The DNS zone domain."
  value       = local.managed_zone.dns_name
}

output "id" {
  description = "Fully qualified zone id."
  value       = local.managed_zone.id
}

output "name" {
  description = "The DNS zone name."
  value       = local.managed_zone.name
}

output "name_servers" {
  description = "The DNS zone name servers."
  value       = local.managed_zone.name_servers
}

output "zone" {
  description = "DNS zone resource."
  value       = local.managed_zone
}
