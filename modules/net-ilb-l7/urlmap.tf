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

# tfdoc:file:description URL map resources.

locals {
  backend_ids = {
    for k, v in google_compute_region_backend_service.default : k => v.id
  }
}

resource "google_compute_region_url_map" "default" {
  provider    = google-beta
  project     = var.project_id
  region      = var.region
  name        = var.name
  description = var.description
  default_service = (
    var.urlmap_config.default_service == null ? null : lookup(
      local.backend_ids,
      var.urlmap_config.default_service,
      var.urlmap_config.default_service
    )
  )

  dynamic "default_url_redirect" {
    for_each = (
      var.urlmap_config.default_url_redirect == null
      ? []
      : [var.urlmap_config.default_url_redirect]
    )
    iterator = r
    content {
      host_redirect          = r.value.host
      https_redirect         = r.value.https
      path_redirect          = r.value.path
      prefix_redirect        = r.value.prefix
      redirect_response_code = r.value.response_code
      strip_query            = r.value.strip_query
    }
  }

  dynamic "host_rule" {
    for_each = coalesce(var.urlmap_config.host_rules, [])
    iterator = r
    content {
      hosts        = r.value.hosts
      path_matcher = r.value.path_matcher
      description  = r.value.description
    }
  }

  dynamic "path_matcher" {
    for_each = coalesce(var.urlmap_config.path_matchers, {})
    iterator = m
    content {
      default_service = m.value.default_service == null ? null : lookup(
        local.backend_ids, m.value.default_service, m.value.default_service
      )
      description = m.value.description
      name        = m.key
      dynamic "default_url_redirect" {
        for_each = (
          m.value.default_url_redirect == null
          ? []
          : [m.value.default_url_redirect]
        )
        content {
          host_redirect          = default_url_redirect.value.host
          https_redirect         = default_url_redirect.value.https
          path_redirect          = default_url_redirect.value.path
          prefix_redirect        = default_url_redirect.value.prefix
          redirect_response_code = default_url_redirect.value.response_code
          strip_query            = default_url_redirect.value.strip_query
        }
      }
      dynamic "path_rule" {
        for_each = toset(coalesce(m.value.path_rules, []))
        content {
          paths = path_rule.value.paths
          service = path_rule.value.service == null ? null : lookup(
            local.backend_ids,
            path_rule.value.service,
            path_rule.value.service
          )
          dynamic "route_action" {
            for_each = (
              path_rule.value.route_action == null
              ? []
              : [path_rule.value.route_action]
            )
            content {
              dynamic "cors_policy" {
                for_each = (
                  route_action.value.cors_policy == null
                  ? []
                  : [route_action.value.cors_policy]
                )
                content {
                  allow_credentials    = cors_policy.value.allow_credentials
                  allow_headers        = cors_policy.value.allow_headers
                  allow_methods        = cors_policy.value.allow_methods
                  allow_origin_regexes = cors_policy.value.allow_origin_regexes
                  allow_origins        = cors_policy.value.allow_origins
                  disabled             = cors_policy.value.disabled
                  expose_headers       = cors_policy.value.expose_headers
                  max_age              = cors_policy.value.max_age
                }
              }
              dynamic "fault_injection_policy" {
                for_each = (
                  route_action.value.fault_injection_policy == null
                  ? []
                  : [route_action.value.fault_injection_policy]
                )
                content {
                  dynamic "abort" {
                    for_each = (
                      fault_injection_policy.value.abort == null
                      ? []
                      : [fault_injection_policy.value.abort]
                    )
                    content {
                      http_status = abort.value.status
                      percentage  = abort.value.percentage
                    }
                  }
                  dynamic "delay" {
                    for_each = (
                      fault_injection_policy.value.delay == null
                      ? []
                      : [fault_injection_policy.value.delay]
                    )
                    content {
                      percentage = delay.value.percentage
                      fixed_delay {
                        nanos   = delay.value.fixed.nanos
                        seconds = delay.value.fixed.seconds
                      }
                    }
                  }
                }
              }
              dynamic "request_mirror_policy" {
                for_each = (
                  route_action.value.request_mirror_backend == null
                  ? []
                  : [""]
                )
                content {
                  backend_service = lookup(
                    local.backend_ids,
                    route_action.value.request_mirror_backend,
                    route_action.value.request_mirror_backend
                  )
                }
              }
              dynamic "retry_policy" {
                for_each = (
                  route_action.value.retry_policy == null
                  ? []
                  : [route_action.value.retry_policy]
                )
                content {
                  num_retries      = retry_policy.value.num_retries
                  retry_conditions = retry_policy.value.retry_conditions
                  dynamic "per_try_timeout" {
                    for_each = (
                      retry_policy.value.per_try_timeout == null
                      ? []
                      : [retry_policy.value.per_try_timeout]
                    )
                    content {
                      nanos   = per_try_timeout.value.nanos
                      seconds = per_try_timeout.value.seconds
                    }
                  }
                }
              }
              dynamic "timeout" {
                for_each = (
                  route_action.value.timeout == null
                  ? []
                  : [route_action.value.timeout]
                )
                content {
                  nanos   = timeout.value.nanos
                  seconds = timeout.value.seconds
                }
              }
              dynamic "url_rewrite" {
                for_each = (
                  route_action.value.url_rewrite == null
                  ? []
                  : [route_action.value.url_rewrite]
                )
                content {
                  host_rewrite        = url_rewrite.value.host
                  path_prefix_rewrite = url_rewrite.value.path_prefix
                }
              }
              dynamic "weighted_backend_services" {
                for_each = coalesce(
                  route_action.value.weighted_backend_services, {}
                )
                iterator = service
                content {
                  backend_service = lookup(
                    local.backend_ids, service.key, service.key
                  )
                  weight = service.value.weight
                  dynamic "header_action" {
                    for_each = (
                      service.value.header_action == null
                      ? []
                      : [service.value.header_action]
                    )
                    iterator = h
                    content {
                      request_headers_to_remove  = h.value.request_remove
                      response_headers_to_remove = h.value.response_remove
                      dynamic "request_headers_to_add" {
                        for_each = coalesce(h.value.request_add, {})
                        content {
                          header_name  = request_headers_to_add.key
                          header_value = request_headers_to_add.value.value
                          replace      = request_headers_to_add.value.replace
                        }
                      }
                      dynamic "response_headers_to_add" {
                        for_each = coalesce(h.value.response_add, {})
                        content {
                          header_name  = response_headers_to_add.key
                          header_value = response_headers_to_add.value.value
                          replace      = response_headers_to_add.value.replace
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          dynamic "url_redirect" {
            for_each = (
              path_rule.value.url_redirect == null
              ? []
              : [path_rule.value.url_redirect]
            )
            content {
              host_redirect          = url_redirect.value.host
              https_redirect         = url_redirect.value.https
              path_redirect          = url_redirect.value.path
              prefix_redirect        = url_redirect.value.prefix
              redirect_response_code = url_redirect.value.response_code
              strip_query            = url_redirect.value.strip_query
            }
          }
        }
      }
      dynamic "route_rules" {
        for_each = toset(coalesce(m.value.route_rules, []))
        content {
          priority = route_rules.value.priority
          service = route_rules.value.service == null ? null : lookup(
            local.backend_ids,
            route_rules.value.service,
            route_rules.value.service
          )
          dynamic "header_action" {
            for_each = (
              route_rules.value.header_action == null
              ? []
              : [route_rules.value.header_action]
            )
            iterator = h
            content {
              request_headers_to_remove  = h.value.request_remove
              response_headers_to_remove = h.value.response_remove
              dynamic "request_headers_to_add" {
                for_each = coalesce(h.value.request_add, {})
                content {
                  header_name  = request_headers_to_add.key
                  header_value = request_headers_to_add.value.value
                  replace      = request_headers_to_add.value.replace
                }
              }
              dynamic "response_headers_to_add" {
                for_each = coalesce(h.value.response_add, {})
                content {
                  header_name  = response_headers_to_add.key
                  header_value = response_headers_to_add.value.value
                  replace      = response_headers_to_add.value.replace
                }
              }
            }
          }
          dynamic "match_rules" {
            for_each = toset(coalesce(route_rules.value.match_rules, []))
            content {
              ignore_case = match_rules.value.ignore_case
              full_path_match = (
                try(match_rules.value.path.type, null) == "full"
                ? match_rules.value.path.value
                : null
              )
              prefix_match = (
                try(match_rules.value.path.type, null) == "prefix"
                ? match_rules.value.path.value
                : null
              )
              regex_match = (
                try(match_rules.value.path.type, null) == "regex"
                ? match_rules.value.path.value
                : null
              )
              dynamic "header_matches" {
                for_each = toset(coalesce(match_rules.value.headers, []))
                iterator = h
                content {
                  header_name   = h.value.name
                  exact_match   = h.value.type == "exact" ? h.value.value : null
                  invert_match  = h.value.invert_match
                  prefix_match  = h.value.type == "prefix" ? h.value.value : null
                  present_match = h.value.type == "present" ? h.value.value : null
                  regex_match   = h.value.type == "regex" ? h.value.value : null
                  suffix_match  = h.value.type == "suffix" ? h.value.value : null
                  dynamic "range_match" {
                    for_each = (
                      h.value.type != "range" || h.value.range_value == null
                      ? []
                      : [""]
                    )
                    content {
                      range_end   = h.value.range_value.end
                      range_start = h.value.range_value.start
                    }
                  }
                }
              }
              dynamic "metadata_filters" {
                for_each = toset(coalesce(match_rules.value.metadata_filters, []))
                iterator = m
                content {
                  filter_match_criteria = (
                    m.value.match_all ? "MATCH_ALL" : "MATCH_ANY"
                  )
                  dynamic "filter_labels" {
                    for_each = m.value.labels
                    content {
                      name  = filter_labels.key
                      value = filter_labels.value
                    }
                  }
                }
              }
              dynamic "query_parameter_matches" {
                for_each = toset(coalesce(match_rules.value.query_params, []))
                iterator = q
                content {
                  name = q.value.name
                  exact_match = (
                    q.value.type == "exact" ? q.value.value : null
                  )
                  present_match = (
                    q.value.type == "present" ? q.value.value : null
                  )
                  regex_match = (
                    q.value.type == "regex" ? q.value.value : null
                  )
                }
              }
            }
          }
          dynamic "route_action" {
            for_each = (
              route_rules.value.route_action == null
              ? []
              : [route_rules.value.route_action]
            )
            content {
              dynamic "cors_policy" {
                for_each = (
                  route_action.value.cors_policy == null
                  ? []
                  : [route_action.value.cors_policy]
                )
                content {
                  allow_credentials    = cors_policy.value.allow_credentials
                  allow_headers        = cors_policy.value.allow_headers
                  allow_methods        = cors_policy.value.allow_methods
                  allow_origin_regexes = cors_policy.value.allow_origin_regexes
                  allow_origins        = cors_policy.value.allow_origins
                  disabled             = cors_policy.value.disabled
                  expose_headers       = cors_policy.value.expose_headers
                  max_age              = cors_policy.value.max_age
                }
              }
              dynamic "fault_injection_policy" {
                for_each = (
                  route_action.value.fault_injection_policy == null
                  ? []
                  : [route_action.value.fault_injection_policy]
                )
                content {
                  dynamic "abort" {
                    for_each = (
                      fault_injection_policy.value.abort == null
                      ? []
                      : [fault_injection_policy.value.abort]
                    )
                    content {
                      http_status = abort.value.status
                      percentage  = abort.value.percentage
                    }
                  }
                  dynamic "delay" {
                    for_each = (
                      fault_injection_policy.value.delay == null
                      ? []
                      : [fault_injection_policy.value.delay]
                    )
                    content {
                      percentage = delay.value.percentage
                      fixed_delay {
                        nanos   = delay.value.fixed.nanos
                        seconds = delay.value.fixed.seconds
                      }
                    }
                  }
                }
              }
              dynamic "request_mirror_policy" {
                for_each = (
                  route_action.value.request_mirror_backend == null
                  ? []
                  : [""]
                )
                content {
                  backend_service = lookup(
                    local.backend_ids,
                    route_action.value.request_mirror_backend,
                    route_action.value.request_mirror_backend
                  )
                }
              }
              dynamic "retry_policy" {
                for_each = (
                  route_action.value.retry_policy == null
                  ? []
                  : [route_action.value.retry_policy]
                )
                content {
                  num_retries      = retry_policy.value.num_retries
                  retry_conditions = retry_policy.value.retry_conditions
                  dynamic "per_try_timeout" {
                    for_each = (
                      retry_policy.value.per_try_timeout == null
                      ? []
                      : [retry_policy.value.per_try_timeout]
                    )
                    content {
                      nanos   = per_try_timeout.value.nanos
                      seconds = per_try_timeout.value.seconds
                    }
                  }
                }
              }
              dynamic "timeout" {
                for_each = (
                  route_action.value.timeout == null
                  ? []
                  : [route_action.value.timeout]
                )
                content {
                  nanos   = timeout.value.nanos
                  seconds = timeout.value.seconds
                }
              }
              dynamic "url_rewrite" {
                for_each = (
                  route_action.value.url_rewrite == null
                  ? []
                  : [route_action.value.url_rewrite]
                )
                content {
                  host_rewrite        = url_rewrite.value.host
                  path_prefix_rewrite = url_rewrite.value.path_prefix
                }
              }
              dynamic "weighted_backend_services" {
                for_each = coalesce(
                  route_action.value.weighted_backend_services, {}
                )
                iterator = service
                content {
                  backend_service = lookup(
                    local.backend_ids, service.key, service.key
                  )
                  weight = service.value.weight
                  dynamic "header_action" {
                    for_each = (
                      service.value.header_action == null
                      ? []
                      : [service.value.header_action]
                    )
                    iterator = h
                    content {
                      request_headers_to_remove  = h.value.request_remove
                      response_headers_to_remove = h.value.response_remove
                      dynamic "request_headers_to_add" {
                        for_each = coalesce(h.value.request_add, {})
                        content {
                          header_name  = request_headers_to_add.key
                          header_value = request_headers_to_add.value.value
                          replace      = request_headers_to_add.value.replace
                        }
                      }
                      dynamic "response_headers_to_add" {
                        for_each = coalesce(h.value.response_add, {})
                        content {
                          header_name  = response_headers_to_add.key
                          header_value = response_headers_to_add.value.value
                          replace      = response_headers_to_add.value.replace
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          dynamic "url_redirect" {
            for_each = (
              route_rules.value.default_url_redirect == null
              ? []
              : [route_rules.value.default_url_redirect]
            )
            content {
              host_redirect          = url_redirect.value.host
              https_redirect         = url_redirect.value.https
              path_redirect          = url_redirect.value.path
              prefix_redirect        = url_redirect.value.prefix
              redirect_response_code = url_redirect.value.response_code
              strip_query            = url_redirect.value.strip_query
            }
          }
        }
      }
    }
  }

  dynamic "test" {
    for_each = toset(coalesce(var.urlmap_config.test, []))
    content {
      host        = test.value.host
      path        = test.value.path
      service     = test.value.service
      description = test.value.description
    }
  }

}
