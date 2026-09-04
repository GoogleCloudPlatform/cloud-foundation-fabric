# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  has_default_rule = anytrue([for k, v in local.all_rules : v.priority == 2147483647])
  default_rule = local.has_default_rule ? {} : {
    default = {
      action             = var.default_rule_action
      priority           = 2147483647
      description        = var.default_rule_description
      preview            = false
      src_ip_ranges      = ["*"]
      expression         = null
      header_action      = null
      rate_limit_options = null
      redirect_options   = null
    }
  }
  normalized_rules = {
    for k, v in var.rules : k => {
      action      = v.action
      priority    = v.priority
      description = v.description
      preview     = v.preview
      expression = (
        v.preconfigured_waf != null
        ? "evaluatePreconfiguredWaf('${v.preconfigured_waf}')"
        : v.threat_intel_feed != null
        ? "evaluateThreatIntelligence('${v.threat_intel_feed}')"
        : v.expression
      )
      src_ip_ranges      = v.src_ip_ranges
      header_action      = v.header_action
      rate_limit_options = v.rate_limit_options
      redirect_options   = v.redirect_options
    }
  }
  all_rules = merge(local.factory_rules, local.normalized_rules)
  rules     = merge(local.default_rule, local.all_rules)
}

resource "google_compute_security_policy" "default" {
  provider    = google
  project     = var.project_id
  name        = var.name
  description = var.description
  type        = var.type
  labels      = var.labels

  dynamic "adaptive_protection_config" {
    for_each = var.adaptive_protection_config != null ? [var.adaptive_protection_config] : []
    content {
      dynamic "layer_7_ddos_defense_config" {
        for_each = adaptive_protection_config.value.layer_7_ddos_defense != null ? [adaptive_protection_config.value.layer_7_ddos_defense] : []
        content {
          enable          = layer_7_ddos_defense_config.value.enable
          rule_visibility = layer_7_ddos_defense_config.value.rule_visibility

          dynamic "threshold_configs" {
            for_each = layer_7_ddos_defense_config.value.threshold_configs != null ? layer_7_ddos_defense_config.value.threshold_configs : []
            content {
              name                                    = threshold_configs.value.name
              auto_deploy_load_threshold              = threshold_configs.value.auto_deploy_load_threshold
              auto_deploy_confidence_threshold        = threshold_configs.value.auto_deploy_confidence_threshold
              auto_deploy_impacted_baseline_threshold = threshold_configs.value.auto_deploy_impacted_baseline_threshold
              auto_deploy_expiration_sec              = threshold_configs.value.auto_deploy_expiration_sec
              detection_load_threshold                = threshold_configs.value.detection_load_threshold
              detection_absolute_qps                  = threshold_configs.value.detection_absolute_qps
              detection_relative_to_baseline_qps      = threshold_configs.value.detection_relative_to_baseline_qps

              dynamic "traffic_granularity_configs" {
                for_each = threshold_configs.value.traffic_granularity_configs != null ? threshold_configs.value.traffic_granularity_configs : []
                content {
                  type                     = traffic_granularity_configs.value.type
                  value                    = traffic_granularity_configs.value.value
                  enable_each_unique_value = traffic_granularity_configs.value.enable_each_unique_value
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "advanced_options_config" {
    for_each = var.advanced_options_config != null ? [var.advanced_options_config] : []
    content {
      json_parsing                 = advanced_options_config.value.json_parsing
      log_level                    = advanced_options_config.value.log_level
      request_body_inspection_size = advanced_options_config.value.request_body_inspection_size
      user_ip_request_headers      = advanced_options_config.value.user_ip_request_headers

      dynamic "json_custom_config" {
        for_each = advanced_options_config.value.json_custom_config != null ? [advanced_options_config.value.json_custom_config] : []
        content {
          content_types = json_custom_config.value.content_types
        }
      }
    }
  }

  dynamic "recaptcha_options_config" {
    for_each = var.recaptcha_options_config != null ? [var.recaptcha_options_config] : []
    content {
      redirect_site_key = recaptcha_options_config.value.redirect_site_key
    }
  }

  dynamic "rule" {
    for_each = local.rules
    content {
      action      = rule.value.action
      priority    = rule.value.priority
      description = rule.value.description
      preview     = rule.value.preview

      dynamic "header_action" {
        for_each = rule.value.header_action != null ? [1] : []
        content {
          dynamic "request_headers_to_adds" {
            for_each = rule.value.header_action
            content {
              header_name  = request_headers_to_adds.value.header_name
              header_value = request_headers_to_adds.value.header_value
            }
          }
        }
      }

      dynamic "match" {
        for_each = (rule.value.src_ip_ranges != null || rule.value.expression != null) ? [1] : []
        content {
          versioned_expr = rule.value.src_ip_ranges != null ? "SRC_IPS_V1" : null
          dynamic "config" {
            for_each = rule.value.src_ip_ranges != null ? [1] : []
            content {
              src_ip_ranges = rule.value.src_ip_ranges
            }
          }
          dynamic "expr" {
            for_each = rule.value.expression != null ? [1] : []
            content {
              expression = rule.value.expression
            }
          }
        }
      }

      dynamic "rate_limit_options" {
        for_each = rule.value.rate_limit_options != null ? [rule.value.rate_limit_options] : []
        content {
          ban_duration_sec    = rate_limit_options.value.ban_duration_sec
          conform_action      = rate_limit_options.value.conform_action
          enforce_on_key      = rate_limit_options.value.enforce_on_key
          enforce_on_key_name = rate_limit_options.value.enforce_on_key_name
          exceed_action       = rate_limit_options.value.exceed_action

          dynamic "ban_threshold" {
            for_each = rate_limit_options.value.ban_threshold != null ? [rate_limit_options.value.ban_threshold] : []
            content {
              count        = ban_threshold.value.count
              interval_sec = ban_threshold.value.interval_sec
            }
          }

          dynamic "rate_limit_threshold" {
            for_each = [rate_limit_options.value.rate_limit_threshold]
            content {
              count        = rate_limit_threshold.value.count
              interval_sec = rate_limit_threshold.value.interval_sec
            }
          }
        }
      }

      dynamic "redirect_options" {
        for_each = rule.value.redirect_options != null ? [rule.value.redirect_options] : []
        content {
          target = redirect_options.value.target
          type   = redirect_options.value.type
        }
      }
    }
  }
}
