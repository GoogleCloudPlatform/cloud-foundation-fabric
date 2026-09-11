/**
 * Copyright 2026 Google LLC
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

# tfdoc:file:description Regional security policy and rules.

resource "google_compute_region_security_policy" "regional" {
  count       = local.is_global ? 0 : 1
  project     = var.project_id
  region      = local.region
  name        = var.name
  description = var.description
  type        = var.type

  dynamic "advanced_options_config" {
    for_each = var.advanced_options_config == null ? [] : [""]
    content {
      json_parsing            = var.advanced_options_config.json_parsing
      log_level               = var.advanced_options_config.log_level
      user_ip_request_headers = var.advanced_options_config.user_ip_request_headers
      dynamic "json_custom_config" {
        for_each = (
          var.advanced_options_config.json_custom_content_types == null
          ? []
          : [""]
        )
        content {
          content_types = var.advanced_options_config.json_custom_content_types
        }
      }
    }
  }

  dynamic "ddos_protection_config" {
    for_each = var.ddos_protection == null ? [] : [""]
    content {
      ddos_protection = var.ddos_protection
    }
  }

  dynamic "user_defined_fields" {
    for_each = var.user_defined_fields
    content {
      name   = user_defined_fields.key
      base   = user_defined_fields.value.base
      offset = user_defined_fields.value.offset
      size   = user_defined_fields.value.size
      mask   = user_defined_fields.value.mask
    }
  }

  lifecycle {
    precondition {
      condition     = length(local.policy_errors) == 0
      error_message = join(" ", local.policy_errors)
    }
  }
}

resource "google_compute_region_security_policy_rule" "regional_default" {
  count           = local.is_global ? 0 : 1
  project         = var.project_id
  region          = local.region
  security_policy = google_compute_region_security_policy.regional[0].name
  priority        = 2147483647
  action          = var.default_rule_config.action
  description     = var.default_rule_config.description
  preview         = var.default_rule_config.preview

  dynamic "match" {
    for_each = local.is_network ? [] : [""]
    content {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  dynamic "network_match" {
    for_each = local.is_network ? [""] : []
    content {
      src_ip_ranges = ["*"]
    }
  }
}

resource "google_compute_region_security_policy_rule" "regional" {
  # Terraform's type system barfs in the condition if we use the locals map
  for_each        = toset(local.is_global ? [] : keys(local.rules))
  project         = var.project_id
  region          = local.region
  security_policy = google_compute_region_security_policy.regional[0].name
  priority        = local.rules[each.key].priority
  action          = local.rules[each.key].action
  description     = local.rules[each.key].description
  preview         = local.rules[each.key].preview

  dynamic "match" {
    for_each = (
      local.rules[each.key].match == null
      ? []
      : [local.rules[each.key].match]
    )
    content {
      versioned_expr = match.value.src_ip_ranges == null ? null : "SRC_IPS_V1"
      dynamic "config" {
        for_each = match.value.src_ip_ranges == null ? [] : [""]
        content {
          src_ip_ranges = match.value.src_ip_ranges
        }
      }
      dynamic "expr" {
        for_each = match.value.expression == null ? [] : [""]
        content {
          expression = match.value.expression
        }
      }
    }
  }

  dynamic "network_match" {
    for_each = (
      local.rules[each.key].network_match == null
      ? []
      : [local.rules[each.key].network_match]
    )
    iterator = nm
    content {
      dest_ip_ranges   = nm.value.dest_ip_ranges
      dest_ports       = nm.value.dest_ports
      ip_protocols     = nm.value.ip_protocols
      src_asns         = nm.value.src_asns
      src_ip_ranges    = nm.value.src_ip_ranges
      src_ports        = nm.value.src_ports
      src_region_codes = nm.value.src_region_codes
      dynamic "user_defined_fields" {
        for_each = nm.value.user_defined_fields
        content {
          name   = user_defined_fields.key
          values = user_defined_fields.value
        }
      }
    }
  }

  dynamic "preconfigured_waf_config" {
    for_each = (
      local.rules[each.key].preconfigured_waf_config == null
      ? []
      : [local.rules[each.key].preconfigured_waf_config]
    )
    iterator = waf
    content {
      dynamic "exclusion" {
        for_each = waf.value.exclusions
        content {
          target_rule_set = exclusion.value.target_rule_set
          target_rule_ids = exclusion.value.target_rule_ids
          dynamic "request_cookie" {
            for_each = exclusion.value.request_cookies
            content {
              operator = request_cookie.value.operator
              value    = request_cookie.value.value
            }
          }
          dynamic "request_header" {
            for_each = exclusion.value.request_headers
            content {
              operator = request_header.value.operator
              value    = request_header.value.value
            }
          }
          dynamic "request_query_param" {
            for_each = exclusion.value.request_query_params
            content {
              operator = request_query_param.value.operator
              value    = request_query_param.value.value
            }
          }
          dynamic "request_uri" {
            for_each = exclusion.value.request_uris
            content {
              operator = request_uri.value.operator
              value    = request_uri.value.value
            }
          }
        }
      }
    }
  }

  dynamic "rate_limit_options" {
    for_each = (
      local.rules[each.key].rate_limit_options == null
      ? []
      : [local.rules[each.key].rate_limit_options]
    )
    iterator = rl
    content {
      conform_action   = "allow"
      exceed_action    = rl.value.exceed_action
      ban_duration_sec = rl.value.ban_duration_sec
      enforce_on_key = (
        length(rl.value.enforce_on_key_configs) > 0
        ? ""
        : rl.value.enforce_on_key
      )
      enforce_on_key_name = rl.value.enforce_on_key_name
      rate_limit_threshold {
        count        = rl.value.rate_limit_threshold.count
        interval_sec = rl.value.rate_limit_threshold.interval_sec
      }
      dynamic "ban_threshold" {
        for_each = rl.value.ban_threshold == null ? [] : [rl.value.ban_threshold]
        content {
          count        = ban_threshold.value.count
          interval_sec = ban_threshold.value.interval_sec
        }
      }
      dynamic "enforce_on_key_configs" {
        for_each = rl.value.enforce_on_key_configs
        content {
          enforce_on_key_type = enforce_on_key_configs.value.type
          enforce_on_key_name = enforce_on_key_configs.value.name
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = local.rule_errors[each.key] == null
      error_message = "Rule '${each.key}': ${coalesce(local.rule_errors[each.key], "-")}"
    }
  }
}
