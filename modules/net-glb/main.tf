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
  fwd_rule_ports = (
    var.protocol == "HTTPS" ? [443] : coalesce(var.ports, [80])
  )
  fwd_rule_target = (
    var.protocol == "HTTPS"
    ? google_compute_target_https_proxy.default.0.id
    : google_compute_target_http_proxy.default.0.id
  )
  proxy_ssl_certificates = concat(
    coalesce(var.ssl_certificates.certificate_ids, []),
    [for k, v in google_compute_ssl_certificate.default : v.id],
    [for k, v in google_compute_managed_ssl_certificate.default : v.id]
  )
}

resource "google_compute_global_forwarding_rule" "default" {
  provider    = google-beta
  project     = var.project_id
  name        = var.name
  description = var.description
  ip_address  = var.address
  ip_protocol = "TCP"
  load_balancing_scheme = (
    var.use_classic_version ? "EXTERNAL" : "EXTERNAL_MANAGED"
  )
  port_range = join(",", local.fwd_rule_ports)
  labels     = var.labels
  target     = local.fwd_rule_target
}

# certificates

resource "google_compute_ssl_certificate" "default" {
  for_each    = var.ssl_certificates.create_configs
  project     = var.project_id
  name        = "${var.name}-${each.key}"
  certificate = trimspace(each.value.certificate)
  private_key = trimspace(each.value.private_key)
}

resource "google_compute_managed_ssl_certificate" "default" {
  for_each    = var.ssl_certificates.managed_configs
  project     = var.project_id
  name        = "${var.name}-${each.key}"
  description = each.value.description
  managed {
    domains = each.value.domains
  }
  lifecycle {
    create_before_destroy = true
  }
}

# proxies

resource "google_compute_target_http_proxy" "default" {
  count       = var.protocol == "HTTPS" ? 0 : 1
  project     = var.project_id
  name        = var.name
  description = var.description
  url_map     = google_compute_url_map.default.id
}

resource "google_compute_target_https_proxy" "default" {
  count            = var.protocol == "HTTPS" ? 1 : 0
  project          = var.project_id
  name             = var.name
  description      = var.description
  certificate_map  = var.https_proxy_config.certificate_map
  quic_override    = var.https_proxy_config.quic_override
  ssl_certificates = local.proxy_ssl_certificates
  ssl_policy       = var.https_proxy_config.ssl_policy
  url_map          = google_compute_url_map.default.id
}
