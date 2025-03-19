/**
 * Copyright 2024 Google LLC
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
  _policy_rules_path = try(pathexpand(var.factories_config.policy_rules), null)
  _policy_rules = {
    for f in try(fileset(local._policy_rules_path, "**/*.yaml"), []) :
    basename(trimsuffix(f, ".yaml")) => yamldecode(file(
      "${local._policy_rules_path}/${f}"
    ))
  }
  policy_rules_args = {
    for k, v in local.policy_rules : k => {
      application = [
        for vv in v.matcher_args.application :
        zipmap(["context", "value"], split(":", vv))
      ]
      session = [
        for vv in v.matcher_args.session :
        zipmap(["context", "value"], split(":", vv))
      ]
    }
  }
  policy_rules_contexts = {
    secure_tag      = var.policy_rules_contexts.secure_tags
    service_account = var.policy_rules_contexts.service_accounts
    url_list = merge(var.policy_rules_contexts.url_lists, {
      for k, v in google_network_security_url_lists.default : k => v.id
    })
  }
  policy_rules = merge(var.policy_rules, {
    for k, v in local._policy_rules : k => {
      priority            = v.priority
      allow               = lookup(v, "allow", true)
      description         = lookup(v, "description", null)
      enabled             = lookup(v, "enable", true)
      application_matcher = lookup(v, "application_matcher", null)
      session_matcher     = lookup(v, "session_matcher", null)
      tls_inspect         = lookup(v, "tls_inspect", null)
      matcher_args = {
        application = try(v.matcher_args.application, [])
        session     = try(v.matcher_args.session, [])
      }
    }
  })
}

resource "google_network_security_gateway_security_policy_rule" "default" {
  for_each               = local.policy_rules
  project                = var.project_id
  location               = var.region
  description            = coalesce(each.value.description, var.description)
  enabled                = each.value.enabled
  name                   = each.key
  priority               = each.value.priority
  tls_inspection_enabled = each.value.tls_inspect
  gateway_security_policy = (
    google_network_security_gateway_security_policy.default.name
  )
  application_matcher = each.value.application_matcher == null ? null : format(
    each.value.application_matcher, [
      for v in local.policy_rules_args[each.key].application :
      lookup(local.policy_rules_contexts[v.context], v.value, v.value)
    ]...
  )
  session_matcher = each.value.session_matcher == null ? null : format(
    each.value.session_matcher, [
      for v in local.policy_rules_args[each.key].session :
      lookup(local.policy_rules_contexts[v.context], v.value, v.value)
    ]...
  )
  basic_profile = (
    each.value.allow == true
    ? "ALLOW"
    : (
      each.value.allow == false ? "DENY" : "BASIC_PROFILE_UNSPECIFIED"
    )
  )
  lifecycle {
    # add a trigger to recreate rules, if the policy is replaced
    # because it is referenced by name, this won't happen automatically, as it would, if referenced by id
    replace_triggered_by = [google_network_security_gateway_security_policy.default.id]
  }
}
