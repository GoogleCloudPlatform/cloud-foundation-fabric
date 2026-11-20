/**
 * Copyright 2026 Google LLC
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
  _regional_apis_addresses = {
    for k, v in var.regional_apis : k => (
      v.address == null
      ? null
      : lookup(local.ctx.addresses, v.address, v.address)
    )
  }
  _regional_apis_networks = {
    for k, v in var.regional_apis :
    k => lookup(local.ctx.networks, v.network, v.network)
  }
  _regional_apis_subnets = {
    for k, v in var.regional_apis :
    k => lookup(local.ctx.subnets, v.subnetwork, v.subnetwork)
  }
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  ctx_p         = "$"
  global_prefix = var.prefix == null ? "" : var.prefix
  prefix        = var.prefix == null ? "" : "${var.prefix}-"
  project_id = lookup(
    local.ctx.project_ids, var.project_id, var.project_id
  )
}

# global PSC endpoints for Google APIs
resource "google_compute_global_address" "global_apis" {
  for_each = {
    for k, v in var.global_apis : k => v if v.address_create
  }
  project = local.project_id
  name    = "${local.global_prefix}${coalesce(each.value.name, each.key)}"
  address = lookup(
    local.ctx.addresses, each.value.address, each.value.address
  )
  address_type = "INTERNAL"
  description  = coalesce(each.value.description, "Terraform managed.")
  labels       = each.value.labels
  purpose      = "PRIVATE_SERVICE_CONNECT"
  network = lookup(
    local.ctx.networks, each.value.network, each.value.network
  )
}

resource "google_compute_global_forwarding_rule" "global_apis" {
  provider    = google-beta
  for_each    = var.global_apis
  project     = local.project_id
  name        = "${local.global_prefix}${coalesce(each.value.name, each.key)}"
  description = each.value.description
  ip_address = (
    each.value.address_create
    ? google_compute_global_address.global_apis[each.key].self_link
    : lookup(local.ctx.addresses, each.value.address, each.value.address)
  )
  load_balancing_scheme = ""
  target                = each.value.target
  deletion_policy       = each.value.deletion_policy
  labels                = each.value.labels
  no_automate_dns_zone  = each.value.no_automate_dns_zone
  network = lookup(
    local.ctx.networks, each.value.network, each.value.network
  )
  dynamic "service_directory_registrations" {
    for_each = (
      each.value.service_directory_registration == null
      ? []
      : [each.value.service_directory_registration]
    )
    content {
      namespace = service_directory_registrations.value.namespace
      service_directory_region = (
        service_directory_registrations.value.region == null
        ? null
        : lookup(
          local.ctx.locations,
          service_directory_registrations.value.region,
          service_directory_registrations.value.region
        )
      )
    }
  }
}

# regional PSC endpoints for published services
resource "google_compute_address" "published_services" {
  for_each = {
    for k, v in var.published_services : k => v if v.address_create
  }
  project = local.project_id
  name    = "${local.prefix}${coalesce(each.value.name, each.key)}"
  address = (
    each.value.address == null
    ? null
    : lookup(local.ctx.addresses, each.value.address, each.value.address)
  )
  address_type = "INTERNAL"
  description  = coalesce(each.value.description, "Terraform managed.")
  labels       = each.value.labels
  region = lookup(
    local.ctx.locations, each.value.region, each.value.region
  )
  subnetwork = lookup(
    local.ctx.subnets, each.value.subnetwork, each.value.subnetwork
  )
}

resource "google_compute_forwarding_rule" "published_services" {
  provider    = google-beta
  for_each    = var.published_services
  project     = local.project_id
  name        = "${local.prefix}${coalesce(each.value.name, each.key)}"
  description = each.value.description
  ip_address = (
    each.value.address_create
    ? google_compute_address.published_services[each.key].self_link
    : lookup(local.ctx.addresses, each.value.address, each.value.address)
  )
  load_balancing_scheme = ""
  recreate_closed_psc   = coalesce(each.value.recreate_closed_psc, true)
  target = lookup(
    local.ctx.service_attachments, each.value.target, each.value.target
  )
  allow_psc_global_access = each.value.global_access
  deletion_policy         = each.value.deletion_policy
  labels                  = each.value.labels
  no_automate_dns_zone    = each.value.no_automate_dns_zone
  region = lookup(
    local.ctx.locations, each.value.region, each.value.region
  )
  subnetwork = lookup(
    local.ctx.subnets, each.value.subnetwork, each.value.subnetwork
  )
  dynamic "service_directory_registrations" {
    for_each = (
      each.value.service_directory_namespace == null
      ? []
      : [each.value.service_directory_namespace]
    )
    content {
      namespace = service_directory_registrations.value
    }
  }
}

# regional and multi-regional PSC endpoints for Google APIs
resource "google_compute_address" "regional_apis" {
  for_each = {
    for k, v in var.regional_apis : k => v if v.address_create
  }
  project      = local.project_id
  name         = "${local.prefix}${coalesce(each.value.name, each.key)}"
  address      = local._regional_apis_addresses[each.key]
  address_type = "INTERNAL"
  description  = coalesce(each.value.description, "Terraform managed.")
  labels       = each.value.labels
  region = lookup(
    local.ctx.locations, each.value.region, each.value.region
  )
  subnetwork = local._regional_apis_subnets[each.key]
}

resource "google_network_connectivity_regional_endpoint" "regional_apis" {
  for_each    = var.regional_apis
  project     = local.project_id
  name        = "${local.prefix}${coalesce(each.value.name, each.key)}"
  description = coalesce(each.value.description, "Terraform managed.")
  location = lookup(
    local.ctx.locations, each.value.region, each.value.region
  )
  target_google_api = each.value.target
  # access_type is required by the provider, so null means regional access
  access_type = (
    each.value.global_access == true ? "GLOBAL" : "REGIONAL"
  )
  address = (
    each.value.address_create
    ? google_compute_address.regional_apis[each.key].id
    : try(
      regex("projects/.*", local._regional_apis_addresses[each.key]),
      local._regional_apis_addresses[each.key]
    )
  )
  deletion_policy = each.value.deletion_policy
  labels          = each.value.labels
  # the API returns relative names and both fields force replacement
  network = try(
    regex("projects/.*", local._regional_apis_networks[each.key]),
    local._regional_apis_networks[each.key]
  )
  subnetwork = try(
    regex("projects/.*", local._regional_apis_subnets[each.key]),
    local._regional_apis_subnets[each.key]
  )
}
