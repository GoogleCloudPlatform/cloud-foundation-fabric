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
  is_global  = var.region == null || var.region == "global"
  is_network = var.type == "CLOUD_ARMOR_NETWORK"
  region     = local.is_global ? null : var.region
  rules      = merge(local.factory_rules, var.rules)
  # rule-level consistency checks depending on policy scope and type,
  # surfaced via preconditions in the rule resources
  rule_errors = {
    for k, v in local.rules : k => (
      local.is_network && v.match != null
      ? "'match' is not supported for CLOUD_ARMOR_NETWORK policies."
      : !local.is_network && v.network_match != null
      ? "'network_match' is only supported for CLOUD_ARMOR_NETWORK policies."
      : local.is_network && v.network_match == null
      ? "'network_match' is required for CLOUD_ARMOR_NETWORK policies."
      : !local.is_network && v.match == null
      ? "'match' is required for policies not of type CLOUD_ARMOR_NETWORK."
      : (local.is_global && var.type == "CLOUD_ARMOR") ? null
      : v.action == "redirect"
      ? "'redirect' action is only supported in global CLOUD_ARMOR policies."
      : length(v.header_action) > 0
      ? "'header_action' is only supported in global CLOUD_ARMOR policies."
      : try(v.rate_limit_options.exceed_redirect_options, null) != null
      ? "'exceed_redirect_options' is only supported in global CLOUD_ARMOR policies."
      : try(v.match.recaptcha_options, null) != null
      ? "'recaptcha_options' is only supported in global CLOUD_ARMOR policies."
      : null
    )
  }
  # policy-level consistency checks, surfaced via preconditions
  # in the policy resources
  policy_errors = compact([
    local.is_global && local.is_network
    ? "CLOUD_ARMOR_NETWORK is only supported for regional policies."
    : null,
    !local.is_global && var.type == "CLOUD_ARMOR_INTERNAL_SERVICE"
    ? "CLOUD_ARMOR_INTERNAL_SERVICE is only supported for global policies."
    : null,
    !local.is_global && var.adaptive_protection_config != null
    ? "'adaptive_protection_config' is only supported for global policies."
    : null,
    !local.is_global && var.recaptcha_options_config != null
    ? "'recaptcha_options_config' is only supported for global policies."
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
  ])
}
