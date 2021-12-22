/**
 * Copyright 2021 Google LLC
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
  _factory_cidrs = try(
    yamldecode(file(var.firewall_policy_factory.cidr_file)), {}
  )
  _factory_name = (
    try(var.firewall_policy_factory.policy_name, null) == null
    ? "factory"
    : var.firewall_policy_factory.policy_name
  )
  _factory_rules = try(
    yamldecode(file(var.firewall_policy_factory.rules_file)), {}
  )
  _factory_rules_parsed = {
    for name, rule in local._factory_rules : name => merge(rule, {
      ranges = flatten([
        for r in(rule.ranges == null ? [] : rule.ranges) :
        lookup(local._factory_cidrs, trimprefix(r, "$"), r)
      ])
    })
  }
  _merged_rules = flatten([
    for policy, rules in local.firewall_policies : [
      for name, rule in rules : merge(rule, {
        policy = policy
        name   = name
      })
    ]
  ])
  firewall_policies = merge(var.firewall_policies, (
    length(local._factory_rules) == 0
    ? {}
    : { (local._factory_name) = local._factory_rules_parsed }
  ))
  firewall_rules = {
    for r in local._merged_rules : "${r.policy}-${r.name}" => r
  }
}

resource "google_compute_organization_security_policy" "policy" {
  provider     = google-beta
  for_each     = local.firewall_policies
  display_name = each.key
  parent       = var.organization_id
  depends_on = [
    google_organization_iam_audit_config.config,
    google_organization_iam_binding.authoritative,
    google_organization_iam_custom_role.roles,
    google_organization_iam_member.additive,
    google_organization_iam_policy.authoritative,
  ]
}

resource "google_compute_organization_security_policy_rule" "rule" {
  provider                = google-beta
  for_each                = local.firewall_rules
  policy_id               = google_compute_organization_security_policy.policy[each.value.policy].id
  action                  = each.value.action
  direction               = each.value.direction
  priority                = try(each.value.priority, null)
  target_resources        = try(each.value.target_resources, null)
  target_service_accounts = try(each.value.target_service_accounts, null)
  enable_logging          = try(each.value.logging, null)
  # preview                 = each.value.preview
  match {
    description = each.value.description
    config {
      src_ip_ranges  = each.value.direction == "INGRESS" ? each.value.ranges : null
      dest_ip_ranges = each.value.direction == "EGRESS" ? each.value.ranges : null
      dynamic "layer4_config" {
        for_each = each.value.ports
        iterator = port
        content {
          ip_protocol = port.key
          ports       = port.value
        }
      }
    }
  }
  # TODO: remove once provider issues is fixed
  # https://github.com/hashicorp/terraform-provider-google/issues/7790
  lifecycle {
    ignore_changes = [match.0.description]
  }
}

resource "google_compute_organization_security_policy_association" "attachment" {
  provider      = google-beta
  for_each      = var.firewall_policy_attachments
  name          = "${var.organization_id}-${each.key}"
  attachment_id = var.organization_id
  policy_id     = each.value
}

