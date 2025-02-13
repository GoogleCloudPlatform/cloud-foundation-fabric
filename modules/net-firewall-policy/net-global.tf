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

resource "google_compute_network_firewall_policy" "net-global" {
  count       = !local.use_hierarchical && !local.use_regional ? 1 : 0
  project     = var.parent_id
  name        = var.name
  description = var.description
}

resource "google_compute_network_firewall_policy_association" "net-global" {
  for_each = (
    !local.use_hierarchical && !local.use_regional ? var.attachments : {}
  )
  project           = var.parent_id
  name              = "${var.name}-${each.key}"
  attachment_target = each.value
  firewall_policy   = google_compute_network_firewall_policy.net-global[0].name
}

resource "google_compute_network_firewall_policy_rule" "net-global" {
  # Terraform's type system barfs in the condition if we use the locals map
  for_each = toset(
    !local.use_hierarchical && !local.use_regional
    ? keys(local.rules)
    : []
  )
  project                 = var.parent_id
  firewall_policy         = google_compute_network_firewall_policy.net-global[0].name
  rule_name               = local.rules[each.key].name
  action                  = local.rules[each.key].action
  description             = local.rules[each.key].description
  direction               = local.rules[each.key].direction
  disabled                = local.rules[each.key].disabled
  enable_logging          = local.rules[each.key].enable_logging
  priority                = local.rules[each.key].priority
  target_service_accounts = local.rules[each.key].target_service_accounts
  tls_inspect             = local.rules[each.key].tls_inspect
  security_profile_group = try(
    var.security_profile_group_ids[local.rules[each.key].security_profile_group],
    local.rules[each.key].security_profile_group
  )
  match {
    dest_ip_ranges = local.rules[each.key].match.destination_ranges
    src_ip_ranges  = local.rules[each.key].match.source_ranges
    dest_address_groups = (
      local.rules[each.key].direction == "EGRESS"
      ? local.rules[each.key].match.address_groups
      : null
    )
    dest_fqdns = (
      local.rules[each.key].direction == "EGRESS"
      ? local.rules[each.key].match.fqdns
      : null
    )
    dest_region_codes = (
      local.rules[each.key].direction == "EGRESS"
      ? local.rules[each.key].match.region_codes
      : null
    )
    dest_threat_intelligences = (
      local.rules[each.key].direction == "EGRESS"
      ? local.rules[each.key].match.threat_intelligences
      : null
    )
    src_address_groups = (
      local.rules[each.key].direction == "INGRESS"
      ? local.rules[each.key].match.address_groups
      : null
    )
    src_fqdns = (
      local.rules[each.key].direction == "INGRESS"
      ? local.rules[each.key].match.fqdns
      : null
    )
    src_region_codes = (
      local.rules[each.key].direction == "INGRESS"
      ? local.rules[each.key].match.region_codes
      : null
    )
    src_threat_intelligences = (
      local.rules[each.key].direction == "INGRESS"
      ? local.rules[each.key].match.threat_intelligences
      : null
    )
    dynamic "layer4_configs" {
      for_each = local.rules[each.key].match.layer4_configs
      content {
        ip_protocol = layer4_configs.value.protocol
        ports       = layer4_configs.value.ports
      }
    }
    dynamic "src_secure_tags" {
      for_each = toset(coalesce(local.rules[each.key].match.source_tags, []))
      content {
        name = src_secure_tags.key
      }
    }
  }
  dynamic "target_secure_tags" {
    for_each = toset(
      local.rules[each.key].target_tags == null
      ? []
      : local.rules[each.key].target_tags
    )
    content {
      name = target_secure_tags.value
    }
  }
}
