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
  fwd_rule_names = {
    for k, v in var.forwarding_rules_config :
    k => k == "" ? var.name : "${var.name}-${k}"
  }
  fwd_rule_target = (
    var.protocol == "HTTPS"
    ? (
      var.use_classic_version
      ? google_compute_target_https_proxy.default[0].id
      : google_compute_target_https_proxy.new[0].id
    )
    : (
      var.use_classic_version
      ? google_compute_target_http_proxy.default[0].id
      : google_compute_target_http_proxy.new[0].id
    )
  )
  proxy_ssl_certificates = concat(
    coalesce(var.ssl_certificates.certificate_ids, []),
    [for k, v in google_compute_ssl_certificate.default : v.id],
    [for k, v in google_compute_managed_ssl_certificate.default : v.id]
  )
}

moved {
  from = google_compute_global_forwarding_rule.default
  to   = google_compute_global_forwarding_rule.default[""]
}

moved {
  from = google_compute_global_forwarding_rule.default
  to   = google_compute_global_forwarding_rule.default[""]
}

resource "google_compute_global_forwarding_rule" "default" {
  provider    = google-beta
  for_each    = var.forwarding_rules_config
  project     = var.project_id
  name        = coalesce(each.value.name, local.fwd_rule_names[each.key])
  description = each.value.description
  ip_address  = each.value.address
  ip_protocol = "TCP"
  ip_version  = each.value.address != null ? null : each.value.ipv6 == true ? "IPV6" : "IPV4" # do not set if address is provided
  load_balancing_scheme = (
    var.use_classic_version ? "EXTERNAL" : "EXTERNAL_MANAGED"
  )
  port_range = join(",", (
    coalesce(each.value.ports, var.protocol == "HTTPS" ? [443] : [80])
  ))
  labels = var.labels
  target = local.fwd_rule_target
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
  name        = coalesce(each.value.name, "${var.name}-${each.key}")
  description = each.value.description
  managed {
    domains = each.value.domains
  }
}

# proxies

resource "google_compute_target_http_proxy" "default" {
  count = (
    var.protocol == "HTTP" && var.use_classic_version ? 1 : 0
  )
  project     = var.project_id
  name        = coalesce(var.https_proxy_config.name, var.name)
  description = var.http_proxy_config.description
  url_map     = google_compute_url_map.default.id
}

resource "google_compute_target_https_proxy" "default" {
  count = (
    var.protocol == "HTTPS" && var.use_classic_version ? 1 : 0
  )
  project                          = var.project_id
  name                             = coalesce(var.https_proxy_config.name, var.name)
  description                      = var.https_proxy_config.description
  certificate_map                  = var.https_proxy_config.certificate_map
  certificate_manager_certificates = var.https_proxy_config.certificate_manager_certificates
  quic_override                    = var.https_proxy_config.quic_override
  ssl_certificates                 = length(local.proxy_ssl_certificates) == 0 ? null : local.proxy_ssl_certificates
  ssl_policy                       = var.https_proxy_config.ssl_policy
  url_map                          = google_compute_url_map.default.id
  server_tls_policy                = var.https_proxy_config.mtls_policy
}

resource "google_compute_target_http_proxy" "new" {
  count = (
    var.protocol == "HTTP" && !var.use_classic_version ? 1 : 0
  )
  project     = var.project_id
  name        = coalesce(var.https_proxy_config.name, var.name)
  description = var.http_proxy_config.description
  url_map     = google_compute_url_map.default.id
}

resource "google_compute_target_https_proxy" "new" {
  count = (
    var.protocol == "HTTPS" && !var.use_classic_version ? 1 : 0
  )
  project                          = var.project_id
  name                             = coalesce(var.https_proxy_config.name, var.name)
  description                      = var.https_proxy_config.description
  certificate_map                  = var.https_proxy_config.certificate_map
  certificate_manager_certificates = var.https_proxy_config.certificate_manager_certificates
  http_keep_alive_timeout_sec      = var.https_proxy_config.http_keepalive_timeout
  quic_override                    = var.https_proxy_config.quic_override
  ssl_certificates                 = length(local.proxy_ssl_certificates) == 0 ? null : local.proxy_ssl_certificates
  ssl_policy                       = var.https_proxy_config.ssl_policy
  url_map                          = google_compute_url_map.default.id
  server_tls_policy                = var.https_proxy_config.mtls_policy
}
