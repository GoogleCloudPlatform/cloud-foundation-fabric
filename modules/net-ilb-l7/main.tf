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
  _neg_endpoints = flatten([
    for k, v in local.neg_zonal : [
      for vv in v.endpoints : merge(vv, { neg = k, zone = v.zone })
    ]
  ])
  fwd_rule_ports = (
    var.protocol == "HTTPS" ? [443] : coalesce(var.ports, [80])
  )
  fwd_rule_target = (
    var.protocol == "HTTPS"
    ? google_compute_region_target_https_proxy.default.0.id
    : google_compute_region_target_http_proxy.default.0.id
  )
  neg_endpoints = {
    for v in local._neg_endpoints :
    "${v.neg}-${v.ip_address}-${coalesce(v.port, "none")}" => v
  }
  neg_regional = {
    for k, v in var.neg_configs :
    k => merge(v.cloudrun, { project_id = v.project_id }) if v.cloudrun != null
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
  proxy_ssl_certificates = concat(
    coalesce(var.ssl_certificates.certificate_ids, []),
    [for k, v in google_compute_region_ssl_certificate.default : v.id]
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
  network_tier          = var.network_tier_premium ? "PREMIUM" : "STANDARD"
  port_range            = join(",", local.fwd_rule_ports)
  subnetwork            = var.vpc_config.subnetwork
  labels                = var.labels
  target                = local.fwd_rule_target
  # during the preview phase you cannot change this attribute on an existing rule
  allow_global_access = var.global_access
  dynamic "service_directory_registrations" {
    for_each = var.service_directory_registration == null ? [] : [""]
    content {
      namespace = var.service_directory_registration.namespace
      service   = var.service_directory_registration.service
    }
  }
}

resource "google_compute_region_ssl_certificate" "default" {
  for_each    = var.ssl_certificates.create_configs
  project     = var.project_id
  region      = var.region
  name        = "${var.name}-${each.key}"
  certificate = each.value.certificate
  private_key = each.value.private_key
}

resource "google_compute_region_target_http_proxy" "default" {
  count       = var.protocol == "HTTPS" ? 0 : 1
  project     = var.project_id
  region      = var.region
  name        = var.name
  description = var.description
  url_map     = google_compute_region_url_map.default.id
}

resource "google_compute_region_target_https_proxy" "default" {
  count            = var.protocol == "HTTPS" ? 1 : 0
  project          = var.project_id
  region           = var.region
  name             = var.name
  description      = var.description
  ssl_certificates = local.proxy_ssl_certificates
  url_map          = google_compute_region_url_map.default.id
}

resource "google_compute_instance_group" "default" {
  for_each = var.group_configs
  project = (
    each.value.project_id == null
    ? var.project_id
    : each.value.project_id
  )
  zone        = each.value.zone
  name        = "${var.name}-${each.key}"
  description = var.description
  instances   = each.value.instances
  dynamic "named_port" {
    for_each = each.value.named_ports
    content {
      name = named_port.key
      port = named_port.value
    }
  }
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

resource "google_compute_region_network_endpoint_group" "default" {
  for_each = local.neg_regional
  project = (
    each.value.project_id == null
    ? var.project_id
    : each.value.project_id
  )
  region                = each.value.region
  name                  = "${var.name}-${each.key}"
  description           = var.description
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service  = try(each.value.target_service.name, null)
    tag      = try(each.value.target_service.tag, null)
    url_mask = each.value.target_urlmask
  }
}
