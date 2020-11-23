/**
 * Copyright 2020 Google LLC
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
  iam_additive_pairs = flatten([
    for role, members in var.iam_additive : [
      for member in members : { role = role, member = member }
    ]
  ])
  iam_additive_member_pairs = flatten([
    for member, roles in var.iam_additive_members : [
      for role in roles : { role = role, member = member }
    ]
  ])
  iam_additive = {
    for pair in concat(local.iam_additive_pairs, local.iam_additive_member_pairs) :
    "${pair.role}-${pair.member}" => pair
  }
  extended_rules = flatten([
    for policy, rules in var.firewall_policies : [
      for rule_name, rule in rules :
      merge(rule, { policy = policy, name = rule_name })
    ]
  ])
  rules_map = {
    for rule in local.extended_rules :
    "${rule.policy}-${rule.name}" => rule
  }
}

resource "google_organization_iam_custom_role" "roles" {
  for_each    = var.custom_roles
  org_id      = var.org_id
  role_id     = each.key
  title       = "Custom role ${each.key}"
  description = "Terraform-managed"
  permissions = each.value
}

resource "google_organization_iam_binding" "authoritative" {
  for_each = var.iam
  org_id   = var.org_id
  role     = each.key
  members  = each.value
}

resource "google_organization_iam_member" "additive" {
  for_each = (
    length(var.iam_additive) + length(var.iam_additive_members) > 0
    ? local.iam_additive
    : {}
  )
  org_id = var.org_id
  role   = each.value.role
  member = each.value.member
}

resource "google_organization_iam_audit_config" "config" {
  for_each = var.iam_audit_config
  org_id   = var.org_id
  service  = each.key
  dynamic audit_log_config {
    for_each = each.value
    iterator = config
    content {
      log_type         = config.key
      exempted_members = config.value
    }
  }
}

resource "google_organization_policy" "boolean" {
  for_each   = var.policy_boolean
  org_id     = var.org_id
  constraint = each.key

  dynamic boolean_policy {
    for_each = each.value == null ? [] : [each.value]
    iterator = policy
    content {
      enforced = policy.value
    }
  }

  dynamic restore_policy {
    for_each = each.value == null ? [""] : []
    content {
      default = true
    }
  }
}

resource "google_organization_policy" "list" {
  for_each   = var.policy_list
  org_id     = var.org_id
  constraint = each.key

  dynamic list_policy {
    for_each = each.value.status == null ? [] : [each.value]
    iterator = policy
    content {
      inherit_from_parent = policy.value.inherit_from_parent
      suggested_value     = policy.value.suggested_value
      dynamic allow {
        for_each = policy.value.status ? [""] : []
        content {
          values = (
            try(length(policy.value.values) > 0, false)
            ? policy.value.values
            : null
          )
          all = (
            try(length(policy.value.values) > 0, false)
            ? null
            : true
          )
        }
      }
      dynamic deny {
        for_each = policy.value.status ? [] : [""]
        content {
          values = (
            try(length(policy.value.values) > 0, false)
            ? policy.value.values
            : null
          )
          all = (
            try(length(policy.value.values) > 0, false)
            ? null
            : true
          )
        }
      }
    }
  }

  dynamic restore_policy {
    for_each = each.value.status == null ? [true] : []
    content {
      default = true
    }
  }
}

resource "google_compute_organization_security_policy" "policy" {
  provider = google-beta
  for_each = var.firewall_policies

  display_name = each.key
  parent       = "organizations/${var.org_id}"
}

resource "google_compute_organization_security_policy_rule" "rule" {
  provider = google-beta
  for_each = local.rules_map

  policy_id               = google_compute_organization_security_policy.policy[each.value.policy].id
  action                  = each.value.action
  direction               = each.value.direction
  priority                = each.value.priority
  target_resources        = each.value.target_resources
  target_service_accounts = each.value.target_service_accounts
  enable_logging          = each.value.logging
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
}

resource "google_compute_organization_security_policy_association" "attachment" {
  provider      = google-beta
  for_each      = var.firewall_policy_attachments
  name          = "organizations/${var.org_id}-${each.key}"
  attachment_id = "organizations/${var.org_id}"
  policy_id     = each.value
}
