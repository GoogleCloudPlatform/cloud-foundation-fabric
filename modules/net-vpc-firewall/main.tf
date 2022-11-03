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

locals {
  # define list of rule files
  _factory_rule_files = [
    for f in try(fileset(var.factories_config.rules_folder, "**/*.yaml"), []) :
    "${var.factories_config.rules_folder}/${f}"
  ]
  # decode rule files and account for optional attributes
  _factory_rule_list = flatten([
    for f in local._factory_rule_files : [
      for name, rule in yamldecode(file(f)) : {
        name                 = name
        rules                = rule.rules
        description          = try(rule.description, null)
        disabled             = try(rule.disabled, null)
        enable_logging       = try(rule.enable_logging, null)
        is_egress            = try(rule.is_egress, false)
        is_deny              = try(rule.is_deny, false)
        priority             = try(rule.priority, 1000)
        ranges               = try(rule.ranges, null)
        sources              = try(rule.sources, null)
        targets              = try(rule.targets, null)
        use_service_accounts = try(rule.use_service_accounts, false)
      }
    ]
  ])
  _factory_rules = {
    for r in local._factory_rule_list : r.name => r
  }
  _named_ranges = merge(
    var.named_ranges,
    try(yamldecode(file(var.factories_config.cidr_tpl_file)), {})
  )
  # convert rules data to resource format and replace range template variables
  rules = {
    for name, rule in merge(local._factory_rules, var.custom_rules) :
    name => merge(rule, {
      action    = rule.is_deny == true ? "DENY" : "ALLOW"
      direction = rule.is_egress == true ? "EGRESS" : "INGRESS"
      rules     = { for k, v in rule.rules : k => v }
      ranges = flatten([
        for range in rule.ranges :
        try(local._named_ranges[range], range)
      ])
    })
  }
}

resource "google_compute_firewall" "custom-rules" {
  for_each    = local.rules
  project     = var.project_id
  network     = var.network
  name        = each.key
  description = each.value.description
  direction   = each.value.direction
  source_ranges = (
    each.value.direction == "INGRESS"
    ? (
      coalesce(each.value.ranges, []) == []
      ? ["0.0.0.0/0"]
      : each.value.ranges
    ) : null
  )
  destination_ranges = (
    each.value.direction == "EGRESS"
    ? (
      coalesce(each.value.ranges, []) == []
      ? ["0.0.0.0/0"]
      : each.value.ranges
    ) : null
  )
  source_tags = (
    each.value.use_service_accounts || each.value.direction == "EGRESS"
    ? null
    : each.value.sources
  )
  source_service_accounts = (
    each.value.use_service_accounts && each.value.direction == "INGRESS"
    ? each.value.sources
    : null
  )
  target_tags = (
    each.value.use_service_accounts ? null : each.value.targets
  )
  target_service_accounts = (
    each.value.use_service_accounts ? each.value.targets : null
  )
  disabled = each.value.disabled == true
  priority = each.value.priority

  dynamic "log_config" {
    for_each = each.value.enable_logging == null ? [] : [""]
    content {
      metadata = (
        try(each.value.enable_logging.include_metadata, null) == true
        ? "INCLUDE_ALL_METADATA"
        : "EXCLUDE_ALL_METADATA"
      )
    }
  }

  dynamic "deny" {
    for_each = each.value.action == "DENY" ? each.value.rules : {}
    iterator = rule
    content {
      protocol = rule.value.protocol
      ports    = rule.value.ports
    }
  }

  dynamic "allow" {
    for_each = each.value.action == "ALLOW" ? each.value.rules : {}
    iterator = rule
    content {
      protocol = rule.value.protocol
      ports    = rule.value.ports
    }
  }
}
