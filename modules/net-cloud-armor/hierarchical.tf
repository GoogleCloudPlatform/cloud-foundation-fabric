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

# tfdoc:file:description Hierarchical security policy, rules and associations.

locals {
  # project numbers in context are bare numbers, targets and exclusions
  # resolve them the same way
  attachments = {
    for k, v in var.attachments : k => {
      id = try(
        "projects/${local.ctx.project_numbers[v.id]}",
        lookup(local.ctx.folder_ids, v.id, v.id)
      )
      excluded_folders = [
        for f in v.excluded_folders : lookup(local.ctx.folder_ids, f, f)
      ]
      excluded_projects = [
        for p in v.excluded_projects : try(
          "projects/${local.ctx.project_numbers[p]}", p
        )
      ]
    }
  }
}

resource "google_compute_organization_security_policy" "hierarchical" {
  count       = local.is_hierarchical ? 1 : 0
  parent      = local.parent_id
  short_name  = var.name
  description = var.description
  type        = var.type

  dynamic "advanced_options_config" {
    for_each = var.advanced_options_config == null ? [] : [""]
    content {
      json_parsing                 = var.advanced_options_config.json_parsing
      log_level                    = var.advanced_options_config.log_level
      request_body_inspection_size = var.advanced_options_config.request_body_inspection_size
      user_ip_request_headers      = var.advanced_options_config.user_ip_request_headers
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

  lifecycle {
    precondition {
      condition     = length(local.policy_errors) == 0
      error_message = join(" ", local.policy_errors)
    }
  }
}

# the API creates a 'goto_next' default rule at priority 2147483647, which
# the module leaves untouched

resource "google_compute_organization_security_policy_rule" "hierarchical" {
  # Terraform's type system barfs in the condition if we use the locals map
  for_each    = toset(local.is_hierarchical ? keys(local.rules) : [])
  policy_id   = google_compute_organization_security_policy.hierarchical[0].id
  priority    = local.rules[each.key].priority
  action      = local.rules[each.key].action
  description = local.rules[each.key].description
  preview     = local.rules[each.key].preview

  dynamic "match" {
    for_each = (
      local.rules[each.key].match == null
      ? []
      : [local.rules[each.key].match]
    )
    content {
      # expression rules use an empty versioned_expr, as in the provider samples
      versioned_expr = match.value.src_ip_ranges == null ? "" : "SRC_IPS_V1"
      dynamic "config" {
        for_each = match.value.src_ip_ranges == null ? [] : [""]
        content {
          src_ip_ranges = local.rule_ranges[each.key].match_src
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

  dynamic "header_action" {
    for_each = length(local.rules[each.key].header_action) == 0 ? [] : [""]
    content {
      dynamic "request_headers_to_adds" {
        for_each = local.rules[each.key].header_action
        content {
          header_name  = request_headers_to_adds.key
          header_value = request_headers_to_adds.value
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

  dynamic "redirect_options" {
    for_each = (
      local.rules[each.key].redirect_options == null
      ? []
      : [local.rules[each.key].redirect_options]
    )
    content {
      type   = redirect_options.value.type
      target = redirect_options.value.target
    }
  }

  lifecycle {
    precondition {
      condition     = local.rule_errors[each.key] == null
      error_message = "Rule '${each.key}': ${coalesce(local.rule_errors[each.key], "-")}"
    }
  }
}

resource "google_compute_organization_security_policy_association" "hierarchical" {
  for_each          = local.is_hierarchical ? local.attachments : {}
  name              = "${var.name}-${each.key}"
  attachment_id     = each.value.id
  policy_id         = google_compute_organization_security_policy.hierarchical[0].id
  excluded_folders  = each.value.excluded_folders
  excluded_projects = each.value.excluded_projects
  # attach once rules are in place, so that inheriting projects never see
  # a partially configured policy
  depends_on = [google_compute_organization_security_policy_rule.hierarchical]
}
