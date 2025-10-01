/**
 * Copyright 2025 Google LLC
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

output "address" {
  description = "The IP address that was allocated."
  value = coalesce(
    try(google_compute_address.internal[0].address, null),
    try(google_compute_address.external[0].address, null),
    try(google_compute_global_address.global[0].address, null),
    try(google_compute_global_address.psa[0].address, null),
    try(google_compute_address.ipsec_interconnect[0].address, null),
    try(google_compute_global_address.psc_global[0].address, null),
    try(google_compute_address.psc_regional[0].address, null)
  )
}

output "id" {
  description = "Address identifier (fully qualified address ID)."
  value = coalesce(
    try(google_compute_address.internal[0].id, null),
    try(google_compute_address.external[0].id, null),
    try(google_compute_global_address.global[0].id, null),
    try(google_compute_global_address.psa[0].id, null),
    try(google_compute_address.ipsec_interconnect[0].id, null),
    try(google_compute_global_address.psc_global[0].id, null),
    try(google_compute_address.psc_regional[0].id, null)
  )
}

output "name" {
  description = "Address name."
  value = coalesce(
    try(google_compute_address.internal[0].name, null),
    try(google_compute_address.external[0].name, null),
    try(google_compute_global_address.global[0].name, null),
    try(google_compute_global_address.psa[0].name, null),
    try(google_compute_address.ipsec_interconnect[0].name, null),
    try(google_compute_global_address.psc_global[0].name, null),
    try(google_compute_address.psc_regional[0].name, null)
  )
}

output "self_link" {
  description = "The URI of the created address resource."
  value = coalesce(
    try(google_compute_address.internal[0].self_link, null),
    try(google_compute_address.external[0].self_link, null),
    try(google_compute_global_address.global[0].self_link, null),
    try(google_compute_global_address.psa[0].self_link, null),
    try(google_compute_address.ipsec_interconnect[0].self_link, null),
    try(google_compute_global_address.psc_global[0].self_link, null),
    try(google_compute_address.psc_regional[0].self_link, null)
  )
}

output "psc_forwarding_rule" {
  description = "The PSC forwarding rule self link (if created)."
  value = try(coalesce(
    try(google_compute_global_forwarding_rule.psc_consumer_global[0].self_link, null),
    try(google_compute_forwarding_rule.psc_consumer_regional[0].self_link, null)
  ),{})
}

output "debug" {
  value = {
    context = var.context
    ctx = local.ctx
    vpc_subnet_id = var.vpc_subnet_id
    project_id = var.project_id
    vpc_id = var.vpc_id
    vpc_subnet_id_compute = local.vpc_subnet_id
    project_id_compute = local.project_id
    vpc_id_compute = local.vpc_id
  }
}