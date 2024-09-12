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

# tfdoc:file:description Backend service resources.

locals {
  group_ids = merge(
    {
      for k, v in google_compute_instance_group.default : k => v.id
    },
    {
      for k, v in google_compute_network_endpoint_group.default : k => v.id
    },
    {
      for k, v in google_compute_region_network_endpoint_group.psc : k => v.id
    },
    {
      for k, v in google_compute_region_network_endpoint_group.serverless : k => v.id
    }
  )
  hc_ids = {
    for k, v in google_compute_region_health_check.default : k => v.id
  }
}

# TODO(jccb): add security_policy block
# TODO(jccb): add connection_tracking_policy block

resource "google_compute_region_backend_service" "default" {
  provider = google-beta
  for_each = var.backend_service_configs
  project = (
    each.value.project_id == null
    ? var.project_id
    : each.value.project_id
  )
  name                            = "${var.name}-${each.key}"
  region                          = var.region
  description                     = var.description
  affinity_cookie_ttl_sec         = each.value.affinity_cookie_ttl_sec
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec
  enable_cdn                      = each.value.enable_cdn
  health_checks = length(each.value.health_checks) == 0 ? null : [
    for k in each.value.health_checks : lookup(local.hc_ids, k, k)
  ]
  # external regional load balancer is always EXTERNAL_MANAGER.
  # TODO(jccb): double check if this is true
  load_balancing_scheme = "EXTERNAL_MANAGED"
  #TODO(jccb): add locality_lb_policy with MAGLEV and WEIGHTED_MAGLEV when scheme EXTERNAL
  port_name = (
    each.value.port_name == null
    ? lower(each.value.protocol == null ? var.protocol : each.value.protocol)
    : each.value.port_name
  )
  protocol = (
    each.value.protocol == null ? var.protocol : each.value.protocol
  )
  session_affinity = each.value.session_affinity
  timeout_sec      = each.value.timeout_sec

  dynamic "backend" {
    for_each = { for b in coalesce(each.value.backends, []) : b.backend => b }
    content {
      group           = lookup(local.group_ids, backend.key, backend.key)
      balancing_mode  = backend.value.balancing_mode # UTILIZATION, RATE
      capacity_scaler = backend.value.capacity_scaler
      description     = backend.value.description
      max_connections = try(
        backend.value.max_connections.per_group, null
      )
      max_connections_per_endpoint = try(
        backend.value.max_connections.per_endpoint, null
      )
      max_connections_per_instance = try(
        backend.value.max_connections.per_instance, null
      )
      max_rate = try(
        backend.value.max_rate.per_group, null
      )
      max_rate_per_endpoint = try(
        backend.value.max_rate.per_endpoint, null
      )
      max_rate_per_instance = try(
        backend.value.max_rate.per_instance, null
      )
      max_utilization = backend.value.max_utilization
    }
  }

  dynamic "cdn_policy" {
    for_each = (
      each.value.cdn_policy == null ? [] : [each.value.cdn_policy]
    )
    iterator = cdn
    content {
      cache_mode                   = cdn.value.cache_mode
      client_ttl                   = cdn.value.client_ttl
      default_ttl                  = cdn.value.default_ttl
      max_ttl                      = cdn.value.max_ttl
      negative_caching             = cdn.value.negative_caching
      serve_while_stale            = cdn.value.serve_while_stale
      signed_url_cache_max_age_sec = cdn.value.signed_url_cache_max_age_sec
      dynamic "cache_key_policy" {
        for_each = (
          cdn.value.cache_key_policy == null
          ? []
          : [cdn.value.cache_key_policy]
        )
        iterator = ck
        content {
          include_host           = ck.value.include_host
          include_named_cookies  = ck.value.include_named_cookies
          include_protocol       = ck.value.include_protocol
          include_query_string   = ck.value.include_query_string
          query_string_blacklist = ck.value.query_string_blacklist
          query_string_whitelist = ck.value.query_string_whitelist
        }
      }
      dynamic "negative_caching_policy" {
        for_each = (
          cdn.value.negative_caching_policy == null
          ? []
          : [cdn.value.negative_caching_policy]
        )
        iterator = nc
        content {
          code = nc.value.code
          ttl  = nc.value.ttl
        }
      }
    }
  }

  dynamic "circuit_breakers" {
    for_each = (
      each.value.circuit_breakers == null ? [] : [each.value.circuit_breakers]
    )
    iterator = cb
    content {
      max_connections             = cb.value.max_connections
      max_pending_requests        = cb.value.max_pending_requests
      max_requests                = cb.value.max_requests
      max_requests_per_connection = cb.value.max_requests_per_connection
      max_retries                 = cb.value.max_retries
      dynamic "connect_timeout" {
        for_each = (
          cb.value.connect_timeout == null ? [] : [cb.value.connect_timeout]
        )
        content {
          seconds = connect_timeout.value.seconds
          nanos   = connect_timeout.value.nanos
        }
      }
    }
  }

  dynamic "consistent_hash" {
    for_each = (
      each.value.consistent_hash == null ? [] : [each.value.consistent_hash]
    )
    iterator = ch
    content {
      http_header_name  = ch.value.http_header_name
      minimum_ring_size = ch.value.minimum_ring_size
      dynamic "http_cookie" {
        for_each = ch.value.http_cookie == null ? [] : [ch.value.http_cookie]
        content {
          name = http_cookie.value.name
          path = http_cookie.value.path
          dynamic "ttl" {
            for_each = (
              http_cookie.value.ttl == null ? [] : [http_cookie.value.ttl]
            )
            content {
              seconds = ttl.value.seconds
              nanos   = ttl.value.nanos
            }
          }
        }
      }
    }
  }

  dynamic "iap" {
    for_each = each.value.iap_config == null ? [] : [each.value.iap_config]
    content {
      enabled                     = true
      oauth2_client_id            = iap.value.oauth2_client_id
      oauth2_client_secret        = iap.value.oauth2_client_secret
      oauth2_client_secret_sha256 = iap.value.oauth2_client_secret_sha256
    }
  }

  dynamic "log_config" {
    for_each = each.value.log_sample_rate == null ? [] : [""]
    content {
      enable      = true
      sample_rate = each.value.log_sample_rate
    }
  }

  dynamic "outlier_detection" {
    for_each = (
      each.value.outlier_detection == null ? [] : [each.value.outlier_detection]
    )
    iterator = od
    content {
      consecutive_errors                    = od.value.consecutive_errors
      consecutive_gateway_failure           = od.value.consecutive_gateway_failure
      enforcing_consecutive_errors          = od.value.enforcing_consecutive_errors
      enforcing_consecutive_gateway_failure = od.value.enforcing_consecutive_gateway_failure
      enforcing_success_rate                = od.value.enforcing_success_rate
      max_ejection_percent                  = od.value.max_ejection_percent
      success_rate_minimum_hosts            = od.value.success_rate_minimum_hosts
      success_rate_request_volume           = od.value.success_rate_request_volume
      success_rate_stdev_factor             = od.value.success_rate_stdev_factor
      dynamic "base_ejection_time" {
        for_each = (
          od.value.base_ejection_time == null ? [] : [od.value.base_ejection_time]
        )
        content {
          seconds = base_ejection_time.value.seconds
          nanos   = base_ejection_time.value.nanos
        }
      }
      dynamic "interval" {
        for_each = (
          od.value.interval == null ? [] : [od.value.interval]
        )
        content {
          seconds = interval.value.seconds
          nanos   = interval.value.nanos
        }
      }
    }
  }
}
