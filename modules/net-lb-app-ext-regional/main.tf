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
  proxy_configs = length(var.proxy_configs) > 0 ? var.proxy_configs : {
    default = {
      protocol                         = var.protocol
      address                          = var.address
      ports                            = var.ports
      certificate_manager_certificates = var.https_proxy_config.certificate_manager_certificates
      ssl_certificates                 = var.ssl_certificates
      ssl_policy                       = var.https_proxy_config.ssl_policy
    }
  }

  proxy_ssl_certificates = {
    for proxy_key, proxy_config in local.proxy_configs : proxy_key => concat(
      coalesce(proxy_config.ssl_certificates.certificate_ids, []),
      [for cert_key, cert_config in google_compute_region_ssl_certificate.default :
        cert_config.id if startswith(cert_key, "${proxy_key}-")
      ]
    ) if proxy_config.protocol == "HTTPS"
  }
}

output "test" {
  value = var.address
}

resource "google_compute_forwarding_rule" "default" {
  for_each              = local.proxy_configs
  provider              = google-beta
  project               = var.project_id
  name                  = length(local.proxy_configs) > 1 ? "${var.name}-${each.key}" : var.name
  region                = var.region
  description           = var.description
  ip_address            = coalesce(each.value.address, var.address)
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range = join(",",
    each.value.protocol == "HTTPS"
    ? (each.value.ports != null ? each.value.ports : ["443"])
    : (each.value.ports != null ? each.value.ports : ["80"])
  )
  labels = var.labels
  target = (
    each.value.protocol == "HTTPS"
    ? google_compute_region_target_https_proxy.default[each.key].id
    : google_compute_region_target_http_proxy.default[each.key].id
  )
  network      = var.vpc
  network_tier = var.network_tier_standard ? "STANDARD" : "PREMIUM"
}

resource "google_compute_region_ssl_certificate" "default" {
  for_each = merge([
    for proxy_key, proxy_config in local.proxy_configs : {
      for cert_key, cert_config in coalesce(proxy_config.ssl_certificates.create_configs, {}) :
      "${proxy_key}-${cert_key}" => {
        proxy_key   = proxy_key
        certificate = cert_config.certificate
        private_key = cert_config.private_key
      }
    } if proxy_config.protocol == "HTTPS"
  ]...)

  project     = var.project_id
  name        = "${var.name}-${each.key}"
  region      = var.region
  certificate = trimspace(each.value.certificate)
  private_key = trimspace(each.value.private_key)
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_target_http_proxy" "default" {
  for_each = {
    for k, v in local.proxy_configs : k => v if v.protocol == "HTTP"
  }
  project     = var.project_id
  region      = var.region
  name        = length(local.proxy_configs) > 1 ? "${var.name}-${each.key}" : var.name
  description = var.description
  url_map     = google_compute_region_url_map.default.id
}

resource "google_compute_region_target_https_proxy" "default" {
  for_each = {
    for k, v in local.proxy_configs : k => v if v.protocol == "HTTPS"
  }
  project                          = var.project_id
  name                             = length(local.proxy_configs) > 1 ? "${var.name}-${each.key}" : var.name
  region                           = var.region
  description                      = var.description
  certificate_manager_certificates = each.value.certificate_manager_certificates
  ssl_certificates                 = length(local.proxy_ssl_certificates[each.key]) == 0 ? null : local.proxy_ssl_certificates[each.key]
  ssl_policy                       = each.value.ssl_policy
  url_map                          = google_compute_region_url_map.default.id
}
