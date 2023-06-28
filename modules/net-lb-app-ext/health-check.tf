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

# tfdoc:file:description Health check resource.

resource "google_compute_health_check" "default" {
  provider = google-beta
  for_each = var.health_check_configs
  project = (
    each.value.project_id == null
    ? var.project_id
    : each.value.project_id
  )
  name                = "${var.name}-${each.key}"
  description         = each.value.description
  check_interval_sec  = each.value.check_interval_sec
  healthy_threshold   = each.value.healthy_threshold
  timeout_sec         = each.value.timeout_sec
  unhealthy_threshold = each.value.unhealthy_threshold

  dynamic "grpc_health_check" {
    for_each = try(each.value.grpc, null) != null ? [""] : []
    content {
      port               = each.value.grpc.port
      port_name          = each.value.grpc.port_name
      port_specification = each.value.grpc.port_specification
      grpc_service_name  = each.value.grpc.service_name
    }
  }

  dynamic "http_health_check" {
    for_each = try(each.value.http, null) != null ? [""] : []
    content {
      host               = each.value.http.host
      port               = each.value.http.port
      port_name          = each.value.http.port_name
      port_specification = each.value.http.port_specification
      proxy_header       = each.value.http.proxy_header
      request_path       = each.value.http.request_path
      response           = each.value.http.response
    }
  }

  dynamic "http2_health_check" {
    for_each = try(each.value.http2, null) != null ? [""] : []
    content {
      host               = each.value.http2.host
      port               = each.value.http2.port
      port_name          = each.value.http2.port_name
      port_specification = each.value.http2.port_specification
      proxy_header       = each.value.http2.proxy_header
      request_path       = each.value.http2.request_path
      response           = each.value.http2.response
    }
  }

  dynamic "https_health_check" {
    for_each = try(each.value.https, null) != null ? [""] : []
    content {
      host               = each.value.https.host
      port               = each.value.https.port
      port_name          = each.value.https.port_name
      port_specification = each.value.https.port_specification
      proxy_header       = each.value.https.proxy_header
      request_path       = each.value.https.request_path
      response           = each.value.https.response
    }
  }

  dynamic "ssl_health_check" {
    for_each = try(each.value.ssl, null) != null ? [""] : []
    content {
      port               = each.value.ssl.port
      port_name          = each.value.ssl.port_name
      port_specification = each.value.ssl.port_specification
      proxy_header       = each.value.ssl.proxy_header
      request            = each.value.ssl.request
      response           = each.value.ssl.response
    }
  }

  dynamic "tcp_health_check" {
    for_each = try(each.value.tcp, null) != null ? [""] : []
    content {
      port               = each.value.tcp.port
      port_name          = each.value.tcp.port_name
      port_specification = each.value.tcp.port_specification
      proxy_header       = each.value.tcp.proxy_header
      request            = each.value.tcp.request
      response           = each.value.tcp.response
    }
  }

  dynamic "log_config" {
    for_each = try(each.value.enable_logging, null) == true ? [""] : []
    content {
      enable = true
    }
  }
}
