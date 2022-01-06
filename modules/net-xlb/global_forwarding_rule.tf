/**
 * Copyright 2021 Google LLC
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
  # Defaults
  global_forwarding_rule_configs = {
    load_balancing_scheme = try(var.global_forwarding_rule_configs.load_balancing_scheme, "EXTERNAL")
    ip_protocol           = try(var.global_forwarding_rule_configs.ip_protocol, "TCP")
    ip_version            = try(var.global_forwarding_rule_configs.ip_version, "IPV4")
    port_range = (
      try(var.global_forwarding_rule_configs.port_range, null) == null
      ? var.https ? "443" : "80"
      : var.global_forwarding_rule_configs.port_range
    )
  }

  ip_address = (
    var.reserve_ip_address
    ? google_compute_global_address.static_ip.0.id
    : null
  )

  target = (
    var.https
    ? google_compute_target_https_proxy.https.0.id
    : google_compute_target_http_proxy.http.0.id
  )
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  provider              = google-beta
  name                  = var.name
  project               = var.project_id
  description           = "Terraform managed."
  ip_protocol           = local.global_forwarding_rule_configs.ip_protocol
  load_balancing_scheme = local.global_forwarding_rule_configs.load_balancing_scheme
  port_range            = local.global_forwarding_rule_configs.port_range
  target                = local.target
  ip_address            = local.ip_address
}
