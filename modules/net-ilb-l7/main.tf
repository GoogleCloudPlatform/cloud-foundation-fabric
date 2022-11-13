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
    for k, v in var.neg_configs : [
      for vv in v.endpoints : merge(vv, { neg = k })
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
  proxy_ssl_certificates = concat(
    [for k, v in google_compute_region_ssl_certificate.default : v.id],
    [for v in var.ssl_certificates : v.self_link if v.id != null]
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
  network_tier          = var.network_tier_premium ? "PREMUIM" : "STANDARD"
  port_range            = join(",", local.fwd_rule_ports)
  subnetwork            = var.vpc_config.subnetwork
  labels                = var.labels
  target                = local.fwd_rule_target
  # service_directory_registrations
}

resource "google_compute_region_ssl_certificate" "default" {
  for_each    = { for v in var.ssl_certificates : v.name => v if v.id == null }
  project     = var.project_id
  region      = var.region
  name        = "${var.name}-${each.key}"
  certificate = try(each.value.tls_self_signed_cert, null)
  private_key = try(each.value.tls_private_key, null)
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
  for_each    = var.group_configs
  project     = var.project_id
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
  for_each              = var.neg_configs
  project               = var.project_id
  zone                  = each.value.zone
  name                  = "${var.name}-${each.key}"
  description           = var.description
  network_endpoint_type = each.value.type
  network               = try(each.value.vpc_config.network, var.vpc_config.network)
  subnetwork            = try(each.value.vpc_config.subnetwork, var.vpc_config.subnetwork)
}

resource "google_compute_network_endpoint" "default" {
  for_each = local.neg_endpoints
  project  = var.project_id
  network_endpoint_group = (
    google_compute_network_endpoint_group.default[each.value.neg].name
  )
  instance   = each.value.instance
  ip_address = each.value.ip_address
  port       = each.value.port
}

