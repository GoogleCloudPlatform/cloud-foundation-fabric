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

# tfdoc:file:description URLmap variable.

variable "urlmap_config" {
  description = "The URL map configuration."
  type = object({
    description = optional(string, "Terraform managed.")
    default_custom_error_response_policy = optional(object({
      error_service = optional(string)
      error_response_rules = optional(list(object({
        match_response_codes   = optional(list(string))
        path                   = optional(string)
        override_response_code = optional(number)
      })))
    }))
    default_route_action = optional(object({
      request_mirror_backend = optional(string)
      cache_policy = optional(object({
        cache_bypass_request_header_names = optional(list(string))
        cache_mode                        = optional(string)
        client_ttl                        = optional(number)
        default_ttl                       = optional(number)
        max_ttl                           = optional(number)
        negative_caching                  = optional(bool)
        request_coalescing                = optional(bool)
        serve_while_stale                 = optional(number)
        cache_key_policy = optional(object({
          excluded_query_parameters = optional(list(string))
          include_host              = optional(bool)
          include_protocol          = optional(bool)
          include_query_string      = optional(bool)
          included_cookie_names     = optional(list(string))
          included_header_names     = optional(list(string))
          included_query_parameters = optional(list(string))
        }))
        negative_caching_policy = optional(list(object({
          code = number
          ttl  = optional(number)
        })))
      }))
      cors_policy = optional(object({
        allow_credentials    = optional(bool)
        allow_headers        = optional(list(string))
        allow_methods        = optional(list(string))
        allow_origin_regexes = optional(list(string))
        allow_origins        = optional(list(string))
        disabled             = optional(bool)
        expose_headers       = optional(list(string))
        max_age              = optional(string)
      }))
      fault_injection_policy = optional(object({
        abort = optional(object({
          percentage = number
          status     = number
        }))
        delay = optional(object({
          fixed = object({
            seconds = number
            nanos   = number
          })
          percentage = number
        }))
      }))
      retry_policy = optional(object({
        num_retries      = number
        retry_conditions = optional(list(string))
        per_try_timeout = optional(object({
          seconds = number
          nanos   = optional(number)
        }))
      }))
      timeout = optional(object({
        seconds = number
        nanos   = optional(number)
      }))
      url_rewrite = optional(object({
        host          = optional(string)
        path_prefix   = optional(string)
        path_template = optional(string)
      }))
      weighted_backend_services = optional(map(object({
        weight = number
        header_action = optional(object({
          request_add = optional(map(object({
            value   = string
            replace = optional(bool, true)
          })))
          request_remove = optional(list(string))
          response_add = optional(map(object({
            value   = string
            replace = optional(bool, true)
          })))
          response_remove = optional(list(string))
        }))
      })))
    }))
    default_service = optional(string)
    default_url_redirect = optional(object({
      host          = optional(string)
      https         = optional(bool)
      path          = optional(string)
      prefix        = optional(string)
      response_code = optional(string)
      strip_query   = optional(bool, false)
    }))
    header_action = optional(object({
      request_add = optional(map(object({
        value   = string
        replace = optional(bool, true)
      })))
      request_remove = optional(list(string))
      response_add = optional(map(object({
        value   = string
        replace = optional(bool, true)
      })))
      response_remove = optional(list(string))
    }))
    host_rules = optional(list(object({
      hosts        = list(string)
      path_matcher = string
      description  = optional(string)
    })))
    path_matchers = optional(map(object({
      description = optional(string)
      default_custom_error_response_policy = optional(object({
        error_service = optional(string)
        error_response_rules = optional(list(object({
          match_response_codes   = optional(list(string))
          path                   = optional(string)
          override_response_code = optional(number)
        })))
      }))
      default_route_action = optional(object({
        request_mirror_backend = optional(string)
        cache_policy = optional(object({
          cache_bypass_request_header_names = optional(list(string))
          cache_mode                        = optional(string)
          client_ttl                        = optional(number)
          default_ttl                       = optional(number)
          max_ttl                           = optional(number)
          negative_caching                  = optional(bool)
          request_coalescing                = optional(bool)
          serve_while_stale                 = optional(number)
          cache_key_policy = optional(object({
            excluded_query_parameters = optional(list(string))
            include_host              = optional(bool)
            include_protocol          = optional(bool)
            include_query_string      = optional(bool)
            included_cookie_names     = optional(list(string))
            included_header_names     = optional(list(string))
            included_query_parameters = optional(list(string))
          }))
          negative_caching_policy = optional(list(object({
            code = number
            ttl  = optional(number)
          })))
        }))
        cors_policy = optional(object({
          allow_credentials    = optional(bool)
          allow_headers        = optional(list(string))
          allow_methods        = optional(list(string))
          allow_origin_regexes = optional(list(string))
          allow_origins        = optional(list(string))
          disabled             = optional(bool)
          expose_headers       = optional(list(string))
          max_age              = optional(string)
        }))
        fault_injection_policy = optional(object({
          abort = optional(object({
            percentage = number
            status     = number
          }))
          delay = optional(object({
            fixed = object({
              seconds = number
              nanos   = number
            })
            percentage = number
          }))
        }))
        retry_policy = optional(object({
          num_retries      = number
          retry_conditions = optional(list(string))
          per_try_timeout = optional(object({
            seconds = number
            nanos   = optional(number)
          }))
        }))
        timeout = optional(object({
          seconds = number
          nanos   = optional(number)
        }))
        url_rewrite = optional(object({
          host        = optional(string)
          path_prefix = optional(string)
        }))
        weighted_backend_services = optional(map(object({
          weight = number
          header_action = optional(object({
            request_add = optional(map(object({
              value   = string
              replace = optional(bool, true)
            })))
            request_remove = optional(list(string))
            response_add = optional(map(object({
              value   = string
              replace = optional(bool, true)
            })))
            response_remove = optional(list(string))
          }))
        })))
      }))
      default_service = optional(string)
      default_url_redirect = optional(object({
        host          = optional(string)
        https         = optional(bool)
        path          = optional(string)
        prefix        = optional(string)
        response_code = optional(string)
        strip_query   = optional(bool)
      }))
      header_action = optional(object({
        request_add = optional(map(object({
          value   = string
          replace = optional(bool, true)
        })))
        request_remove = optional(list(string))
        response_add = optional(map(object({
          value   = string
          replace = optional(bool, true)
        })))
        response_remove = optional(list(string))
      }))
      path_rules = optional(list(object({
        paths   = list(string)
        service = optional(string)
        custom_error_response_policy = optional(object({
          error_service = optional(string)
          error_response_rules = optional(list(object({
            match_response_codes   = optional(list(string))
            path                   = optional(string)
            override_response_code = optional(number)
          })))
        }))
        route_action = optional(object({
          request_mirror_backend = optional(string)
          cache_policy = optional(object({
            cache_bypass_request_header_names = optional(list(string))
            cache_mode                        = optional(string)
            client_ttl                        = optional(number)
            default_ttl                       = optional(number)
            max_ttl                           = optional(number)
            negative_caching                  = optional(bool)
            request_coalescing                = optional(bool)
            serve_while_stale                 = optional(number)
            cache_key_policy = optional(object({
              excluded_query_parameters = optional(list(string))
              include_host              = optional(bool)
              include_protocol          = optional(bool)
              include_query_string      = optional(bool)
              included_cookie_names     = optional(list(string))
              included_header_names     = optional(list(string))
              included_query_parameters = optional(list(string))
            }))
            negative_caching_policy = optional(list(object({
              code = number
              ttl  = optional(number)
            })))
          }))
          cors_policy = optional(object({
            allow_credentials    = optional(bool)
            allow_headers        = optional(list(string))
            allow_methods        = optional(list(string))
            allow_origin_regexes = optional(list(string))
            allow_origins        = optional(list(string))
            disabled             = optional(bool)
            expose_headers       = optional(list(string))
            max_age              = optional(string)
          }))
          fault_injection_policy = optional(object({
            abort = optional(object({
              percentage = number
              status     = number
            }))
            delay = optional(object({
              fixed = object({
                seconds = number
                nanos   = number
              })
              percentage = number
            }))
          }))
          retry_policy = optional(object({
            num_retries      = number
            retry_conditions = optional(list(string))
            per_try_timeout = optional(object({
              seconds = number
              nanos   = optional(number)
            }))
          }))
          timeout = optional(object({
            seconds = number
            nanos   = optional(number)
          }))
          url_rewrite = optional(object({
            host        = optional(string)
            path_prefix = optional(string)
          }))
          weighted_backend_services = optional(map(object({
            weight = number
            header_action = optional(object({
              request_add = optional(map(object({
                value   = string
                replace = optional(bool, true)
              })))
              request_remove = optional(list(string))
              response_add = optional(map(object({
                value   = string
                replace = optional(bool, true)
              })))
              response_remove = optional(list(string))
            }))
          })))
        }))
        url_redirect = optional(object({
          host          = optional(string)
          https         = optional(bool)
          path          = optional(string)
          prefix        = optional(string)
          response_code = optional(string)
          strip_query   = optional(bool)
        }))
      })))
      route_rules = optional(list(object({
        priority = number
        service  = optional(string)
        custom_error_response_policy = optional(object({
          error_service = optional(string)
          error_response_rules = optional(list(object({
            match_response_codes   = optional(list(string))
            path                   = optional(string)
            override_response_code = optional(number)
          })))
        }))
        header_action = optional(object({
          request_add = optional(map(object({
            value   = string
            replace = optional(bool, true)
          })))
          request_remove = optional(list(string))
          response_add = optional(map(object({
            value   = string
            replace = optional(bool, true)
          })))
          response_remove = optional(list(string))
        }))
        match_rules = optional(list(object({
          ignore_case = optional(bool, false)
          headers = optional(list(object({
            name         = string
            invert_match = optional(bool, false)
            type         = optional(string, "present") # exact, prefix, suffix, regex, present, range, template
            value        = optional(string)
            range_value = optional(object({
              end   = string
              start = string
            }))
          })))
          metadata_filters = optional(list(object({
            labels    = map(string)
            match_all = bool # MATCH_ANY, MATCH_ALL
          })))
          path = optional(object({
            value = string
            type  = optional(string, "prefix") # full, prefix, regex
          }))
          query_params = optional(list(object({
            name  = string
            value = string
            type  = optional(string, "present") # exact, present, regex
          })))
        })))
        route_action = optional(object({
          request_mirror_backend = optional(string)
          cache_policy = optional(object({
            cache_bypass_request_header_names = optional(list(string))
            cache_mode                        = optional(string)
            client_ttl                        = optional(number)
            default_ttl                       = optional(number)
            max_ttl                           = optional(number)
            negative_caching                  = optional(bool)
            request_coalescing                = optional(bool)
            serve_while_stale                 = optional(number)
            cache_key_policy = optional(object({
              excluded_query_parameters = optional(list(string))
              include_host              = optional(bool)
              include_protocol          = optional(bool)
              include_query_string      = optional(bool)
              included_cookie_names     = optional(list(string))
              included_header_names     = optional(list(string))
              included_query_parameters = optional(list(string))
            }))
            negative_caching_policy = optional(list(object({
              code = number
              ttl  = optional(number)
            })))
          }))
          cors_policy = optional(object({
            allow_credentials    = optional(bool)
            allow_headers        = optional(list(string))
            allow_methods        = optional(list(string))
            allow_origin_regexes = optional(list(string))
            allow_origins        = optional(list(string))
            disabled             = optional(bool)
            expose_headers       = optional(list(string))
            max_age              = optional(string)
          }))
          fault_injection_policy = optional(object({
            abort = optional(object({
              percentage = number
              status     = number
            }))
            delay = optional(object({
              fixed = object({
                seconds = number
                nanos   = number
              })
              percentage = number
            }))
          }))
          retry_policy = optional(object({
            num_retries      = number
            retry_conditions = optional(list(string))
            per_try_timeout = optional(object({
              seconds = number
              nanos   = optional(number)
            }))
          }))
          timeout = optional(object({
            seconds = number
            nanos   = optional(number)
          }))
          url_rewrite = optional(object({
            host          = optional(string)
            path_prefix   = optional(string)
            path_template = optional(string)
          }))
          weighted_backend_services = optional(map(object({
            weight = number
            header_action = optional(object({
              request_add = optional(map(object({
                value   = string
                replace = optional(bool, true)
              })))
              request_remove = optional(list(string))
              response_add = optional(map(object({
                value   = string
                replace = optional(bool, true)
              })))
              response_remove = optional(list(string))
            }))
          })))
        }))
        url_redirect = optional(object({
          host          = optional(string)
          https         = optional(bool)
          path          = optional(string)
          prefix        = optional(string)
          response_code = optional(string)
          strip_query   = optional(bool)
        }))
      })))
    })))
    test = optional(list(object({
      host        = string
      path        = string
      service     = string
      description = optional(string)
    })))
  })
  default = {
    default_service = "default"
  }
  validation {
    condition = alltrue([
      for p in concat(
        [try(var.urlmap_config.default_route_action.cache_policy, null)],
        flatten([
          for m in values(coalesce(var.urlmap_config.path_matchers, {})) : [
            [try(m.default_route_action.cache_policy, null)],
            [
              for r in coalesce(m.path_rules, []) :
              try(r.route_action.cache_policy, null)
            ],
            [
              for r in coalesce(m.route_rules, []) :
              try(r.route_action.cache_policy, null)
            ]
          ]
        ])
        ) : contains(
        ["CACHE_ALL_STATIC", "FORCE_CACHE_ALL", "USE_ORIGIN_HEADERS"],
        p.cache_mode
      ) if try(p.cache_mode, null) != null
    ])
    error_message = "Invalid cache_policy.cache_mode, must be one of CACHE_ALL_STATIC, FORCE_CACHE_ALL, USE_ORIGIN_HEADERS."
  }
  validation {
    condition = var.use_classic_version == false || alltrue([
      for p in concat(
        [try(var.urlmap_config.default_route_action.cache_policy, null)],
        flatten([
          for m in values(coalesce(var.urlmap_config.path_matchers, {})) : [
            [try(m.default_route_action.cache_policy, null)],
            [
              for r in coalesce(m.path_rules, []) :
              try(r.route_action.cache_policy, null)
            ],
            [
              for r in coalesce(m.route_rules, []) :
              try(r.route_action.cache_policy, null)
            ]
          ]
        ])
      ) : p == null
    ])
    error_message = "Route-level cache_policy requires use_classic_version = false."
  }
}
