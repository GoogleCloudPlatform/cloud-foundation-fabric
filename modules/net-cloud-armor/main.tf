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

locals {
  is_backend        = var.type == "CLOUD_ARMOR"
  is_global         = var.region == null || var.region == "global"
  is_global_backend = local.is_global && local.is_backend
  is_l7             = !local.is_network
  is_network        = var.type == "CLOUD_ARMOR_NETWORK"
  region            = local.is_global ? null : var.region
  rules             = merge(local.factory_rules, var.rules)
  # rule-level consistency checks, evaluated on the merged rule set so
  # that factory rules are covered too, and surfaced via preconditions
  # in the rule resources; the first failing check wins
  _rule_errors = {
    for k, v in local.rules : k => compact([
      # checks that do not depend on scope or type
      v.priority == 2147483647
      ? "Priority 2147483647 is reserved for the default rule, use the 'default_rule_config' variable instead."
      : null,
      v.match != null && v.network_match != null
      ? "Rules cannot specify both 'match' and 'network_match'."
      : null,
      v.match != null && (v.match.src_ip_ranges == null) == (v.match.expression == null)
      ? "Rule match must specify exactly one of 'src_ip_ranges' or 'expression'."
      : null,
      length(coalesce(try(v.match.src_ip_ranges, null), [])) > 10
      ? "Rule match 'src_ip_ranges' supports at most 10 ranges, split them across multiple rules."
      : null,
      try(v.match.recaptcha_options, null) != null && try(v.match.expression, null) == null
      ? "'recaptcha_options' requires a match 'expression' evaluating reCAPTCHA tokens."
      : null,
      contains(["throttle", "rate_based_ban"], v.action) != (v.rate_limit_options != null)
      ? "Rate limit options must be set if and only if action is 'throttle' or 'rate_based_ban'."
      : null,
      (v.action == "redirect") != (v.redirect_options != null)
      ? "Redirect options must be set if and only if action is 'redirect'."
      : null,
      v.action != "rate_based_ban" && (
        try(v.rate_limit_options.ban_duration_sec, null) != null
        || try(v.rate_limit_options.ban_threshold, null) != null
      )
      ? "'ban_duration_sec' and 'ban_threshold' are only supported with the 'rate_based_ban' action."
      : null,
      (
        try(v.rate_limit_options.enforce_on_key, null) != null
        && length(try(v.rate_limit_options.enforce_on_key_configs, [])) > 0
      )
      ? "Rate limit options cannot specify both 'enforce_on_key' and 'enforce_on_key_configs'."
      : null,
      (
        try(v.rate_limit_options.exceed_action, null) == "redirect"
      ) != (try(v.rate_limit_options.exceed_redirect_options, null) != null)
      ? "'exceed_redirect_options' must be set if and only if 'exceed_action' is 'redirect'."
      : null,
      # checks depending on policy type
      local.is_network && v.match != null
      ? "'match' is not supported for CLOUD_ARMOR_NETWORK policies."
      : null,
      local.is_network && v.network_match == null
      ? "'network_match' is required for CLOUD_ARMOR_NETWORK policies."
      : null,
      local.is_l7 && v.network_match != null
      ? "'network_match' is only supported for CLOUD_ARMOR_NETWORK policies."
      : null,
      local.is_l7 && v.match == null
      ? "'match' is required for policies not of type CLOUD_ARMOR_NETWORK."
      : null,
      !local.is_backend && !can(regex("^(allow|deny(\\(\\d+\\))?)$", v.action))
      ? "Only the 'allow' and 'deny' actions are supported for ${var.type} policies."
      : null,
      local.is_network && can(regex("^deny\\(", v.action))
      ? "'deny' cannot specify a status code for CLOUD_ARMOR_NETWORK policies."
      : null,
      !local.is_backend && v.preconfigured_waf_config != null
      ? "'preconfigured_waf_config' is only supported for CLOUD_ARMOR policies."
      : null,
      # checks depending on policy scope
      !local.is_global_backend && v.action == "redirect"
      ? "'redirect' action is only supported in global CLOUD_ARMOR policies."
      : null,
      !local.is_global_backend && length(v.header_action) > 0
      ? "'header_action' is only supported in global CLOUD_ARMOR policies."
      : null,
      !local.is_global_backend && try(v.rate_limit_options.exceed_redirect_options, null) != null
      ? "'exceed_redirect_options' is only supported in global CLOUD_ARMOR policies."
      : null,
      !local.is_global_backend && try(v.match.recaptcha_options, null) != null
      ? "'recaptcha_options' is only supported in global CLOUD_ARMOR policies."
      : null,
    ])
  }
  rule_errors = {
    for k, v in local._rule_errors : k => try(v[0], null)
  }
  # policy-level consistency checks, surfaced via preconditions
  # in the policy resources
  _rule_priorities = [for k, v in local.rules : v.priority]
  policy_errors = compact([
    local.is_global && local.is_network
    ? "CLOUD_ARMOR_NETWORK is only supported for regional policies."
    : null,
    !local.is_global && var.type == "CLOUD_ARMOR_INTERNAL_SERVICE"
    ? "CLOUD_ARMOR_INTERNAL_SERVICE is only supported for global policies."
    : null,
    !local.is_global && var.type == "CLOUD_ARMOR_EDGE"
    ? "CLOUD_ARMOR_EDGE is only supported for global policies."
    : null,
    !local.is_global_backend && var.adaptive_protection_config != null
    ? "'adaptive_protection_config' is only supported for global CLOUD_ARMOR policies."
    : null,
    !local.is_global_backend && var.recaptcha_options_config != null
    ? "'recaptcha_options_config' is only supported for global CLOUD_ARMOR policies."
    : null,
    !local.is_global && length(var.labels) > 0
    ? "'labels' are only supported for global policies."
    : null,
    !local.is_global && try(var.advanced_options_config.request_body_inspection_size, null) != null
    ? "'request_body_inspection_size' is only supported for global policies."
    : null,
    !local.is_network && var.ddos_protection != null
    ? "'ddos_protection' is only supported for CLOUD_ARMOR_NETWORK policies."
    : null,
    !local.is_network && length(var.user_defined_fields) > 0
    ? "'user_defined_fields' are only supported for CLOUD_ARMOR_NETWORK policies."
    : null,
    var.ddos_protection != null && length(local.rules) > 0
    ? "Policies enabling 'ddos_protection' cannot define custom rules, use a separate CLOUD_ARMOR_NETWORK policy."
    : null,
    length(distinct(local._rule_priorities)) != length(local._rule_priorities)
    ? "Rule priorities must be unique across the 'rules' variable and factory rules."
    : null,
  ])
}
