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
  _health_checks_configs_default = {
    type = "http"
    check = {
      port_specification = "USE_SERVING_PORT"
    }
    logging = false
  }

  # Get group backend services without health checks defined
  _backends_without_hc = [for k, v in var.backends_configs : v if v.type == "group" && try(v.health_check, null) == null]

  # If group at least one backend service without
  # hc is defined, create a default health check
  health_checks_configs = (length(local._backends_without_hc) > 0
    ? merge({
      default = local._health_checks_configs_default },
      var.health_checks_configs
    )
    : var.health_checks_configs
  )

  health_checks_http  = { for k, v in local.health_checks_configs : k => v if try(v.type, null) == "http" || try(v.type, null) == null }
  health_checks_https = { for k, v in local.health_checks_configs : k => v if try(v.type, null) == "https" }
  health_checks_tcp   = { for k, v in local.health_checks_configs : k => v if try(v.type, null) == "tcp" }
  health_checks_ssl   = { for k, v in local.health_checks_configs : k => v if try(v.type, null) == "ssl" }
  health_checks_http2 = { for k, v in local.health_checks_configs : k => v if try(v.type, null) == "http2" }
}

resource "google_compute_health_check" "health_check" {
  for_each            = { for k, v in local.health_checks_configs : k => v }
  provider            = google-beta
  name                = var.name
  project             = var.project_id
  description         = "Terraform managed."
  check_interval_sec  = try(each.value.check_interval_sec, null)
  healthy_threshold   = try(each.value.healthy_threshold, null)
  timeout_sec         = try(each.value.timeout_sec, null)
  unhealthy_threshold = try(each.value.unhealthy_threshold, null)

  dynamic "http_health_check" {
    for_each = local.health_checks_http
    iterator = http
    content {
      host               = try(http.value.check.host, null)
      port               = try(http.value.check.port, null)
      port_name          = try(http.value.check.port_name, null)
      port_specification = try(http.value.check.port_specification, "USE_SERVING_PORT")
      proxy_header       = try(http.value.check.proxy_header, null)
      request_path       = try(http.value.check.request_path, null)
      response           = try(http.value.check.response, null)
    }
  }

  dynamic "https_health_check" {
    for_each = local.health_checks_https
    iterator = https
    content {
      host               = try(https.value.check.host, null)
      port               = try(https.value.check.port, null)
      port_name          = try(https.value.check.port_name, null)
      port_specification = try(https.value.check.port_specification, "USE_SERVING_PORT")
      proxy_header       = try(https.value.check.proxy_header, null)
      request_path       = try(https.value.check.request_path, null)
      response           = try(https.value.check.response, null)
    }
  }

  dynamic "tcp_health_check" {
    for_each = local.health_checks_tcp
    iterator = tcp
    content {
      port               = try(tcp.value.check.port, null)
      port_name          = try(tcp.value.check.port_name, null)
      port_specification = try(tcp.value.check.port_specification, "USE_SERVING_PORT")
      proxy_header       = try(tcp.value.check.proxy_header, null)
      request            = try(tcp.value.check.request, null)
      response           = try(tcp.value.check.response, null)
    }
  }

  dynamic "ssl_health_check" {
    for_each = local.health_checks_ssl
    iterator = ssl
    content {
      port               = try(ssl.value.check.port, null)
      port_name          = try(ssl.value.check.port_name, null)
      port_specification = try(ssl.value.check.port_specification, "USE_SERVING_PORT")
      proxy_header       = try(ssl.value.check.proxy_header, null)
      request            = try(ssl.value.check.request, null)
      response           = try(ssl.value.check.response, null)
    }
  }

  dynamic "http2_health_check" {
    for_each = local.health_checks_http2
    iterator = http2
    content {
      host               = try(http2.value.check.host, null)
      port               = try(http2.value.check.port, null)
      port_name          = try(http2.value.check.port_name, null)
      port_specification = try(http2.value.check.port_specification, "USE_SERVING_PORT")
      proxy_header       = try(http2.value.check.proxy_header, null)
      request_path       = try(http2.value.check.request_path, null)
      response           = try(http2.value.check.response, null)
    }
  }

  dynamic "log_config" {
    for_each = try(each.value.logging, false) ? { 0 = 0 } : {}
    content {
      enable = true
    }
  }
}
