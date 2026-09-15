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

# tfdoc:file:description Rules factory.

locals {
  _factory_rules = coalesce(
    try(
      yamldecode(file(pathexpand(var.factories_config.rules_file_path))),
    {}), tomap({})
  )
  _factory_waf_exclusions = {
    for k, v in local._factory_rules : k => [
      for e in try(v.preconfigured_waf_config.exclusions, []) : {
        target_rule_set = e.target_rule_set
        target_rule_ids = lookup(e, "target_rule_ids", null)
        request_cookies = [
          for f in lookup(e, "request_cookies", []) : {
            operator = f.operator
            value    = lookup(f, "value", null)
          }
        ]
        request_headers = [
          for f in lookup(e, "request_headers", []) : {
            operator = f.operator
            value    = lookup(f, "value", null)
          }
        ]
        request_query_params = [
          for f in lookup(e, "request_query_params", []) : {
            operator = f.operator
            value    = lookup(f, "value", null)
          }
        ]
        request_uris = [
          for f in lookup(e, "request_uris", []) : {
            operator = f.operator
            value    = lookup(f, "value", null)
          }
        ]
      }
    ]
  }
  factory_rules = {
    for k, v in local._factory_rules : k => {
      priority    = v.priority
      action      = v.action
      description = lookup(v, "description", null)
      preview     = lookup(v, "preview", false)
      match = lookup(v, "match", null) == null ? null : {
        src_ip_ranges = lookup(v.match, "src_ip_ranges", null)
        expression    = lookup(v.match, "expression", null)
        recaptcha_options = (
          lookup(v.match, "recaptcha_options", null) == null ? null : {
            action_token_site_keys = lookup(
              v.match.recaptcha_options, "action_token_site_keys", null
            )
            session_token_site_keys = lookup(
              v.match.recaptcha_options, "session_token_site_keys", null
            )
          }
        )
      }
      network_match = lookup(v, "network_match", null) == null ? null : {
        dest_ip_ranges      = lookup(v.network_match, "dest_ip_ranges", null)
        dest_ports          = lookup(v.network_match, "dest_ports", null)
        ip_protocols        = lookup(v.network_match, "ip_protocols", null)
        src_asns            = lookup(v.network_match, "src_asns", null)
        src_ip_ranges       = lookup(v.network_match, "src_ip_ranges", null)
        src_ports           = lookup(v.network_match, "src_ports", null)
        src_region_codes    = lookup(v.network_match, "src_region_codes", null)
        user_defined_fields = lookup(v.network_match, "user_defined_fields", {})
      }
      header_action = lookup(v, "header_action", {})
      preconfigured_waf_config = (
        lookup(v, "preconfigured_waf_config", null) == null ? null : {
          exclusions = local._factory_waf_exclusions[k]
        }
      )
      rate_limit_options = (
        lookup(v, "rate_limit_options", null) == null ? null : {
          exceed_action = v.rate_limit_options.exceed_action
          rate_limit_threshold = {
            count        = v.rate_limit_options.rate_limit_threshold.count
            interval_sec = v.rate_limit_options.rate_limit_threshold.interval_sec
          }
          ban_duration_sec = lookup(
            v.rate_limit_options, "ban_duration_sec", null
          )
          ban_threshold = (
            lookup(v.rate_limit_options, "ban_threshold", null) == null
            ? null
            : {
              count        = v.rate_limit_options.ban_threshold.count
              interval_sec = v.rate_limit_options.ban_threshold.interval_sec
            }
          )
          enforce_on_key = lookup(
            v.rate_limit_options, "enforce_on_key", null
          )
          enforce_on_key_name = lookup(
            v.rate_limit_options, "enforce_on_key_name", null
          )
          enforce_on_key_configs = [
            for c in lookup(v.rate_limit_options, "enforce_on_key_configs", []) : {
              type = c.type
              name = lookup(c, "name", null)
            }
          ]
          exceed_redirect_options = (
            lookup(v.rate_limit_options, "exceed_redirect_options", null) == null
            ? null
            : {
              type = v.rate_limit_options.exceed_redirect_options.type
              target = lookup(
                v.rate_limit_options.exceed_redirect_options, "target", null
              )
            }
          )
        }
      )
      redirect_options = lookup(v, "redirect_options", null) == null ? null : {
        type   = v.redirect_options.type
        target = lookup(v.redirect_options, "target", null)
      }
    }
  }
}
