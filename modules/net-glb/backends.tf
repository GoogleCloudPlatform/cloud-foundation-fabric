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

# tfdoc:file:description Backend groups and backend buckets resources.

resource "google_compute_backend_bucket" "default" {
  for_each                = var.backend_buckets_config
  project                 = var.project_id
  name                    = "${var.name}-${each.key}"
  bucket_name             = each.value.bucket_name
  compression_mode        = each.value.compression_mode
  custom_response_headers = each.value.custom_response_headers
  description             = each.value.description
  edge_security_policy    = each.value.edge_security_policy
  enable_cdn              = each.value.enable_cdn

  dynamic "cdn_policy" {
    for_each = each.value.cdn_policy == null ? [] : [each.value.cdn_policy]
    iterator = p
    content {
      cache_mode                   = p.value.cache_mode
      client_ttl                   = p.value.client_ttl
      default_ttl                  = p.value.default_ttl
      max_ttl                      = p.value.max_ttl
      negative_caching             = p.value.negative_caching
      request_coalescing           = p.value.request_coalescing
      serve_while_stale            = p.value.serve_while_stale
      signed_url_cache_max_age_sec = p.value.signed_url_cache_max_age_sec
      dynamic "bypass_cache_on_request_headers" {
        for_each = (
          p.value.bypass_cache_on_request_headers == null
          ? []
          : [p.value.bypass_cache_on_request_headers]
        )
        iterator = h
        content {
          header_name = h.value
        }
      }
      dynamic "cache_key_policy" {
        for_each = (
          p.value.cache_key_policy == null ? [] : [p.value.cache_key_policy]
        )
        iterator = ckp
        content {
          include_http_headers   = ckp.value.include_http_headers
          query_string_whitelist = ckp.value.query_string_whitelist
        }
      }
      dynamic "negative_caching_policy" {
        for_each = (
          p.value.negative_caching_policy == null
          ? []
          : [p.value.negative_caching_policy]
        )
        iterator = ncp
        content {
          code = ncp.value.code
          ttl  = ncp.value.ttl
        }
      }
    }
  }
}

resource "google_compute_instance_group" "default" {
  for_each = var.group_configs
  project = (
    each.value.project_id == null
    ? var.project_id
    : each.value.project_id
  )
  zone        = each.value.zone
  name        = "${var.name}-${each.key}"
  description = var.description
  instances   = each.value.instances

  dynamic "named_port" {
    for_each = each.value.named_ports
    content {
      name = named_port.key
      port = named_port.value
    }
  }
}
