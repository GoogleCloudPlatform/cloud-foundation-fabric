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
  backends_bucket = { for k, v in var.backends_configs : k => v if v.type == "bucket" }
  backends_group  = { for k, v in var.backends_configs : k => v if v.type == "group" }

  # Name of the default health check if no health checks are defined
  health_checks_default = (
    try(
      [google_compute_health_check.health_check["default"].self_link],
      null
    )
  )
}

resource "google_compute_backend_bucket" "bucket" {
  for_each                = local.backends_bucket
  name                    = var.name
  project                 = var.project_id
  description             = "Terraform managed."
  bucket_name             = try(each.value.bucket_name, null)
  enable_cdn              = try(each.value.enable_cdn, null)
  custom_response_headers = try(each.value.custom_response_headers, null)

  dynamic "cdn_policy" {
    for_each = try(each.value.cdn_policy, null) == null ? [] : [each.value.cdn_policy]
    content {
      signed_url_cache_max_age_sec = try(cdn_policy.value.signed_url_cache_max_age_sec, null)
      default_ttl                  = try(cdn_policy.value.default_ttl, null)
      max_ttl                      = try(cdn_policy.value.max_ttl, null)
      client_ttl                   = try(cdn_policy.value.client_ttl, null)
      negative_caching             = try(cdn_policy.value.negative_caching, null)
      cache_mode                   = try(cdn_policy.value.cache_mode, null)
      serve_while_stale            = try(cdn_policy.value.serve_while_stale, null)

      dynamic "negative_caching_policy" {
        for_each = try(cdn_policy.value.negative_caching_policy, null) == null ? [] : [cdn_policy.value.negative_caching_policy]
        iterator = ncp
        content {
          code = ncp.value.code
          ttl  = ncp.value.ttl
        }
      }
    }
  }
}

resource "google_compute_backend_service" "group" {
  for_each                        = local.backends_group
  name                            = var.name
  project                         = var.project_id
  description                     = "Terraform managed."
  affinity_cookie_ttl_sec         = try(each.value.affinity_cookie_ttl_sec, null)
  enable_cdn                      = try(each.value.enable_cdn, null)
  custom_request_headers          = try(each.value.custom_request_headers, null)
  custom_response_headers         = try(each.value.custom_response_headers, null)
  connection_draining_timeout_sec = try(each.value.connection_draining_timeout_sec, null)
  load_balancing_scheme           = try(each.value.load_balancing_scheme, null) # only EXTERNAL makes sense here
  locality_lb_policy              = try(each.value.locality_lb_policy, null)
  port_name                       = try(each.value.port_name, null)
  protocol                        = try(each.value.protocol, null)
  security_policy                 = try(each.value.security_policy, null)
  session_affinity                = try(each.value.session_affinity, null)
  timeout_sec                     = try(each.value.timeout_sec, null)

  # HC source_type == create -> find id in the health checks map
  # HC source_type == attach -> use id given as existing resource self_link
  # Otherwise, use the default health check (identified in locals above)
  health_checks = (
    try(each.value.health_check.source_type, null) == "create"
    # null is excluded from the list so the search won't
    # silently fail, if the element is not found in any list
    ? try([google_compute_health_check.health_check[each.value.health_check.id].self_link])
    : (
      try(each.value.health_check.source_type, null) == "attach"
      ? [each.value.health_check.id]
      : local.health_checks_default
    )
  )

  dynamic "backend" {
    for_each = try(each.value.backends, [])
    content {
      balancing_mode               = try(backend.value.balancing_mode, null)  # Can be UTILIZATION, RATE, CONNECTION
      capacity_scaler              = try(backend.value.capacity_scaler, null) # Valid range is [0.0,1.0]
      group                        = try(backend.value.group, null)           # IG or NEG FQDN address
      max_connections              = try(backend.value.max_connections, null)
      max_connections_per_instance = try(backend.value.max_connections_per_instance, null)
      max_connections_per_endpoint = try(backend.value.max_connections_per_endpoint, null)
      max_rate                     = try(backend.value.max_rate, null)
      max_rate_per_instance        = try(backend.value.max_rate_per_instance, null)
      max_rate_per_endpoint        = try(backend.value.max_rate_per_endpoint, null)
      max_utilization              = try(backend.value.max_utilization, null)
    }
  }

  dynamic "circuit_breakers" {
    for_each = try(each.value.circuit_breakers, null) == null ? [] : [each.value.circuit_breakers]
    iterator = cb
    content {
      max_requests_per_connection = try(cb.value.max_requests_per_connection, null)
      max_connections             = try(cb.value.max_connections, null)
      max_pending_requests        = try(cb.value.max_pending_requests, null)
      max_requests                = try(cb.value.max_requests, null)
      max_retries                 = try(cb.value.max_retries, null)
    }
  }

  dynamic "consistent_hash" {
    for_each = try(each.value.consistent_hash, null) == null ? [] : [each.value.consistent_hash]
    content {
      http_header_name  = try(consistent_hash.value.http_header_name, null)
      minimum_ring_size = try(consistent_hash.value.minimum_ring_size, null)

      dynamic "http_cookie" {
        for_each = try(consistent_hash.value.http_cookie, null) == null ? [] : [consistent_hash.value.http_cookie]
        content {
          name = try(http_cookie.value.name, null)
          path = try(http_cookie.value.path, null)

          dynamic "ttl" {
            for_each = try(consistent_hash.value.ttl, null) == null ? [] : [consistent_hash.value.ttl]
            content {
              seconds = try(ttl.value.seconds, null) # Must be from 0 to 315,576,000,000 inclusive
              nanos   = try(ttl.value.nanos, null)   # Must be from 0 to 999,999,999 inclusive
            }
          }
        }
      }
    }
  }

  dynamic "cdn_policy" {
    for_each = try(each.value.cdn_policy, null) == null ? [] : [each.value.cdn_policy]
    iterator = cdn_policy
    content {
      signed_url_cache_max_age_sec = try(cdn_policy.value.signed_url_cache_max_age_sec, null)
      default_ttl                  = try(cdn_policy.value.default_ttl, null)
      max_ttl                      = try(cdn_policy.value.max_ttl, null)
      client_ttl                   = try(cdn_policy.value.client_ttl, null)
      negative_caching             = try(cdn_policy.value.negative_caching, null)
      cache_mode                   = try(cdn_policy.value.cache_mode, null)
      serve_while_stale            = try(cdn_policy.value.serve_while_stale, null)

      dynamic "negative_caching_policy" {
        for_each = try(cdn_policy.value.negative_caching_policy, null) == null ? [] : [cdn_policy.value.negative_caching_policy]
        iterator = ncp
        content {
          code = try(ncp.value.code, null)
          ttl  = try(ncp.value.ttl, null)
        }
      }
    }
  }

  dynamic "iap" {
    for_each = try(each.value.iap, null) == null ? [] : [each.value.iap]
    content {
      oauth2_client_id            = try(iap.value.oauth2_client_id, null)
      oauth2_client_secret        = try(iap.value.oauth2_client_secret, null)        # sensitive
      oauth2_client_secret_sha256 = try(iap.value.oauth2_client_secret_sha256, null) # sensitive
    }
  }

  dynamic "log_config" {
    for_each = try(each.value.logging, null) == null ? [] : [each.value.logging]
    iterator = logging
    content {
      enable      = try(each.value.logging, false)
      sample_rate = try(logging.value.sample_rate, null) # must be in [0, 1]
    }
  }
}
