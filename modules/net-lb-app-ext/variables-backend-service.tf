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

# tfdoc:file:description Backend services variables.

variable "backend_service_configs" {
  description = "Backend service level configuration."
  type = map(object({
    affinity_cookie_ttl_sec         = optional(number)
    compression_mode                = optional(string)
    connection_draining_timeout_sec = optional(number)
    custom_request_headers          = optional(list(string))
    custom_response_headers         = optional(list(string))
    enable_cdn                      = optional(bool)
    health_checks                   = optional(list(string), ["default"])
    log_sample_rate                 = optional(number)
    port_name                       = optional(string)
    project_id                      = optional(string)
    protocol                        = optional(string)
    security_policy                 = optional(string)
    session_affinity                = optional(string)
    timeout_sec                     = optional(number)
    backends = list(object({
      # group renamed to backend
      backend         = string
      balancing_mode  = optional(string, "UTILIZATION")
      capacity_scaler = optional(number, 1)
      description     = optional(string, "Terraform managed.")
      failover        = optional(bool, false)
      max_connections = optional(object({
        per_endpoint = optional(number)
        per_group    = optional(number)
        per_instance = optional(number)
      }))
      max_rate = optional(object({
        per_endpoint = optional(number)
        per_group    = optional(number)
        per_instance = optional(number)
      }))
      max_utilization = optional(number)
    }))
    cdn_policy = optional(object({
      cache_mode                   = optional(string)
      client_ttl                   = optional(number)
      default_ttl                  = optional(number)
      max_ttl                      = optional(number)
      negative_caching             = optional(bool)
      serve_while_stale            = optional(number)
      signed_url_cache_max_age_sec = optional(number)
      cache_key_policy = optional(object({
        include_host           = optional(bool)
        include_named_cookies  = optional(list(string))
        include_protocol       = optional(bool)
        include_query_string   = optional(bool)
        query_string_blacklist = optional(list(string))
        query_string_whitelist = optional(list(string))
      }))
      negative_caching_policy = optional(object({
        code = optional(number)
        ttl  = optional(number)
      }))
    }))
    circuit_breakers = optional(object({
      max_connections             = optional(number)
      max_pending_requests        = optional(number)
      max_requests                = optional(number)
      max_requests_per_connection = optional(number)
      max_retries                 = optional(number)
      connect_timeout = optional(object({
        seconds = number
        nanos   = optional(number)
      }))
    }))
    consistent_hash = optional(object({
      http_header_name  = optional(string)
      minimum_ring_size = optional(number)
      http_cookie = optional(object({
        name = optional(string)
        path = optional(string)
        ttl = optional(object({
          seconds = number
          nanos   = optional(number)
        }))
      }))
    }))
    iap_config = optional(object({
      oauth2_client_id            = string
      oauth2_client_secret        = string
      oauth2_client_secret_sha256 = optional(string)
    }))
    outlier_detection = optional(object({
      consecutive_errors                    = optional(number)
      consecutive_gateway_failure           = optional(number)
      enforcing_consecutive_errors          = optional(number)
      enforcing_consecutive_gateway_failure = optional(number)
      enforcing_success_rate                = optional(number)
      max_ejection_percent                  = optional(number)
      success_rate_minimum_hosts            = optional(number)
      success_rate_request_volume           = optional(number)
      success_rate_stdev_factor             = optional(number)
      base_ejection_time = optional(object({
        seconds = number
        nanos   = optional(number)
      }))
      interval = optional(object({
        seconds = number
        nanos   = optional(number)
      }))
    }))
    security_settings = optional(object({
      client_tls_policy = optional(string)
      subject_alt_names = optional(list(string))
      aws_v4_authentication = optional(object({
        access_key_id      = optional(string)
        access_key         = optional(string)
        access_key_version = optional(string)
        origin_region      = optional(string)
      }))
  })) }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for backend_service in values(var.backend_service_configs) : contains(
        [
          "NONE", "CLIENT_IP", "CLIENT_IP_NO_DESTINATION",
          "CLIENT_IP_PORT_PROTO", "CLIENT_IP_PROTO"
        ],
        coalesce(backend_service.session_affinity, "NONE")
      )
    ])
    error_message = "Invalid session affinity value."
  }
  validation {
    condition = alltrue(flatten([
      for backend_service in values(var.backend_service_configs) : [
        for backend in backend_service.backends : contains(
          ["RATE", "UTILIZATION"], coalesce(backend.balancing_mode, "UTILIZATION")
      )]
    ]))
    error_message = "When specified, balancing mode needs to be 'RATE' or 'UTILIZATION'."
  }
}
