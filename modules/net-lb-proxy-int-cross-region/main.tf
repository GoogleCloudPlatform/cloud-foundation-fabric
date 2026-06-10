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
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  ctx_p      = "$"
  network    = lookup(local.ctx.networks, var.vpc_config.network, var.vpc_config.network)
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)
}

locals {
  _neg_endpoints = flatten([
    for k, v in local.neg_zonal : [
      for kk, vv in v.endpoints : merge(vv, {
        key = "${k}-${kk}", neg = k, zone = v.zone
      })
    ]
  ])
  addresses = {
    for k, v in coalesce(var.addresses, {}) : k => lookup(local.ctx.addresses, v, v)
  }
  health_check = (
    var.health_check != null
    ? var.health_check
    : google_compute_health_check.default[0].self_link
  )
  neg_endpoints = {
    for v in local._neg_endpoints : (v.key) => v
  }
  neg_zonal = {
    for k, v in var.neg_configs : k => {
      endpoints  = v.gce != null ? v.gce.endpoints : v.hybrid.endpoints
      network    = v.gce != null ? v.gce.network : v.hybrid.network
      project_id = v.project_id
      subnetwork = v.gce != null ? v.gce.subnetwork : null
      type       = v.gce != null ? "GCE_VM_IP_PORT" : "NON_GCP_PRIVATE_IP_PORT"
      zone       = v.gce != null ? v.gce.zone : v.hybrid.zone
    } if v.gce != null || v.hybrid != null
  }
  neg_regional_psc = {
    for k, v in var.neg_configs :
    k => v if v.psc != null
  }
  subnetworks = {
    for k, v in var.vpc_config.subnetworks : k => lookup(local.ctx.subnets, v, v)
  }
}

resource "google_compute_global_forwarding_rule" "default" {
  for_each              = local.subnetworks
  provider              = google-beta
  project               = local.project_id
  name                  = "${var.name}-${each.key}"
  description           = var.description
  ip_address            = try(local.addresses[each.key], null)
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = local.network
  port_range            = tostring(var.port)
  subnetwork            = each.value
  labels                = var.labels
  target                = google_compute_target_tcp_proxy.default.id
}

resource "google_compute_target_tcp_proxy" "default" {
  project         = local.project_id
  name            = coalesce(var.target_proxy_config.name, var.name)
  description     = var.target_proxy_config.description
  backend_service = google_compute_backend_service.default.id
  proxy_header    = var.target_proxy_config.proxy_header
}

resource "google_compute_network_endpoint_group" "default" {
  for_each = local.neg_zonal
  project = (
    each.value.project_id == null
    ? local.project_id
    : each.value.project_id
  )
  name = "${var.name}-${each.key}"
  network = (
    each.value.network == null
    ? null
    : lookup(local.ctx.networks, each.value.network, each.value.network)
  )
  subnetwork = (
    each.value.subnetwork == null
    ? null
    : lookup(local.ctx.subnets, each.value.subnetwork, each.value.subnetwork)
  )
  network_endpoint_type = each.value.type
  zone                  = lookup(local.ctx.locations, each.value.zone, each.value.zone)
}

resource "google_compute_network_endpoint" "default" {
  for_each = local.neg_endpoints
  project = (
    local.neg_zonal[each.value.neg].project_id == null
    ? local.project_id
    : local.neg_zonal[each.value.neg].project_id
  )
  network_endpoint_group = google_compute_network_endpoint_group.default[each.value.neg].name
  zone                   = lookup(local.ctx.locations, each.value.zone, each.value.zone)
  instance               = try(each.value.instance, null)
  ip_address             = each.value.ip_address
  port                   = each.value.port
}

resource "google_compute_region_network_endpoint_group" "psc" {
  for_each              = local.neg_regional_psc
  project               = coalesce(each.value.project_id, local.project_id)
  name                  = "${var.name}-${each.key}"
  region                = lookup(local.ctx.locations, each.value.psc.region, each.value.psc.region)
  network               = lookup(local.ctx.networks, each.value.psc.network, each.value.psc.network)
  subnetwork            = lookup(local.ctx.subnets, each.value.psc.subnetwork, each.value.psc.subnetwork)
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = each.value.psc.target_service
}
