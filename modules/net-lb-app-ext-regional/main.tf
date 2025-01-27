/**
 * Copyright 2024 Google LLC
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
    ? google_compute_region_target_https_proxy.default[0].id
    : google_compute_region_target_http_proxy.default[0].id
  )
  proxy_ssl_certificates = concat(
    coalesce(var.ssl_certificates.certificate_ids, []),
    [for k, v in google_compute_region_ssl_certificate.default : v.id],
  )
}

resource "google_compute_forwarding_rule" "default" {
  provider    = google-beta
  project     = var.project_id
  name        = var.name
  region      = var.region
  description = var.description
  ip_address  = var.address
  ip_protocol = "TCP"
  # external regional load balancer is always EXTERNAL_MANAGER.
  # TODO(jccb): double check if this is true
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = join(",", local.fwd_rule_ports)
  labels                = var.labels
  target                = local.fwd_rule_target
  network               = var.vpc
  # external regional app lb only supports standard tier
  network_tier = "STANDARD"
}

# certificates

resource "google_compute_region_ssl_certificate" "default" {
  for_each    = var.ssl_certificates.create_configs
  project     = var.project_id
  name        = "${var.name}-${each.key}"
  region      = var.region
  certificate = trimspace(each.value.certificate)
  private_key = trimspace(each.value.private_key)
  lifecycle {
    create_before_destroy = true
  }
}

# proxies

resource "google_compute_region_target_http_proxy" "default" {
  count       = var.protocol == "HTTPS" ? 0 : 1
  project     = var.project_id
  region      = var.region
  name        = var.name
  description = var.description
  url_map     = google_compute_region_url_map.default.id
}

resource "google_compute_region_target_https_proxy" "default" {
  count                            = var.protocol == "HTTPS" ? 1 : 0
  project                          = var.project_id
  name                             = var.name
  region                           = var.region
  description                      = var.description
  certificate_manager_certificates = var.https_proxy_config.certificate_manager_certificates
  ssl_certificates                 = length(local.proxy_ssl_certificates) == 0 ? null : local.proxy_ssl_certificates
  ssl_policy                       = var.https_proxy_config.ssl_policy
  url_map                          = google_compute_region_url_map.default.id
}
