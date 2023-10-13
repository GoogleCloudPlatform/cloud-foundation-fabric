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
  trust_config_name = "trust-config-${var.name}"
  mtls_policy_name  = "mtls-policy-${var.name}"
}

data "google_project" "project" {
  project_id = var.project_id
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
  count             = var.protocol == "HTTPS" ? 1 : 0
  project           = var.project_id
  name              = var.name
  description       = var.description
  certificate_map   = var.https_proxy_config.certificate_map
  quic_override     = var.https_proxy_config.quic_override
  ssl_certificates  = local.proxy_ssl_certificates
  ssl_policy        = var.https_proxy_config.ssl_policy
  url_map           = google_compute_url_map.default.id
  server_tls_policy = google_network_security_server_tls_policy.default.0.id
}

resource "google_certificate_manager_trust_config" "default" {
  count    = var.protocol == "HTTPS" && var.mtls_policy_config.create_mtls_resources ? 1 : 0
  provider = google-beta
  project  = var.project_id
  name = (
    var.mtls_policy_config.trust_config_name != null
    ? var.mtls_policy_config.trust_config_name
    : local.trust_config_name
  )
  description = var.description
  location    = var.mtls_policy_config.trust_config_location
  trust_stores {
    dynamic "trust_anchors" {
      for_each = var.mtls_policy_config.trust_anchors_pem_certificates

      content {
        pem_certificate = trimspace(trust_anchors.value)
      }
    }
    dynamic "intermediate_cas" {
      for_each = var.mtls_policy_config.intermediate_cas_pem_certificates

      content {
        pem_certificate = trimspace(intermediate_cas.value)
      }
    }
  }

  labels = var.labels
}


resource "google_network_security_server_tls_policy" "default" {
  count    = var.protocol == "HTTPS" && var.mtls_policy_config.create_mtls_resources ? 1 : 0
  provider = google-beta
  project  = var.project_id
  name = (
    var.mtls_policy_config.policy_name != null
    ? var.mtls_policy_config.policy_name
    : local.mtls_policy_name
  )
  description = var.description
  location    = var.mtls_policy_config.server_tls_policy_location
  allow_open  = "false" # To be kept as false for external HTTPS Load Balancer. The field only applies for Traffic Director policies.
  mtls_policy {
    client_validation_mode         = var.mtls_policy_config.client_validation_mode
    client_validation_trust_config = "projects/${data.google_project.project.number}/locations/${var.mtls_policy_config.trust_config_location}/trustConfigs/${google_certificate_manager_trust_config.default.0.name}"
  } # A required field for HTTP Load Balancers if mTLS is to be enforced. Defines a mechanism to provision peer validation certificates for peer to peer authentication i.e. mTLS.
}
