/**
 * Copyright 2022 Google LLC
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
  # we need keys in the endpoint type to address issue #1055
  _neg_endpoints = flatten([
    for k, v in local.neg_zonal : [
      for kk, vv in v.endpoints : merge(vv, {
        key = "${k}-${kk}", neg = k, zone = v.zone
      })
    ]
  ])
  neg_endpoints = {
    for v in local._neg_endpoints : (v.key) => v
  }
  neg_zonal = {
    # we need to rebuild new objects as we cannot merge different types
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
  health_check = (
    var.health_check != null
    ? var.health_check
    : google_compute_region_health_check.default[0].self_link
  )
}

resource "google_compute_forwarding_rule" "default" {
  provider              = google-beta
  project               = var.project_id
  region                = var.region
  name                  = var.name
  description           = var.description
  ip_address            = var.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = var.vpc_config.network
  port_range            = var.port
  subnetwork            = var.vpc_config.subnetwork
  labels                = var.labels
  target                = google_compute_region_target_tcp_proxy.default.id
  # during the preview phase you cannot change this attribute on an existing rule
  allow_global_access = var.global_access
}

resource "google_compute_region_target_tcp_proxy" "default" {
  project         = var.project_id
  name            = var.name
  description     = var.description
  region          = var.region
  backend_service = google_compute_region_backend_service.default.self_link
}

resource "google_compute_network_endpoint_group" "default" {
  for_each = local.neg_zonal
  project = (
    each.value.project_id == null
    ? var.project_id
    : each.value.project_id
  )
  zone = each.value.zone
  name = "${var.name}-${each.key}"
  # re-enable once provider properly supports this
  # default_port = each.value.default_port
  description           = var.description
  network_endpoint_type = each.value.type
  network = (
    each.value.network != null ? each.value.network : var.vpc_config.network
  )
  subnetwork = (
    each.value.type == "NON_GCP_PRIVATE_IP_PORT"
    ? null
    : try(each.value.subnetwork, var.vpc_config.subnetwork)
  )
}

resource "google_compute_network_endpoint" "default" {
  for_each = local.neg_endpoints
  project = (
    google_compute_network_endpoint_group.default[each.value.neg].project
  )
  network_endpoint_group = (
    google_compute_network_endpoint_group.default[each.value.neg].name
  )
  instance   = try(each.value.instance, null)
  ip_address = each.value.ip_address
  port       = each.value.port
  zone       = each.value.zone
}

resource "google_compute_region_network_endpoint_group" "psc" {
  for_each = local.neg_regional_psc
  project  = var.project_id
  region   = each.value.psc.region
  name     = "${var.name}-${each.key}"
  //description           = coalesce(each.value.description, var.description)
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = each.value.psc.target_service
  network               = each.value.psc.network
  subnetwork            = each.value.psc.subnetwork
}
