/**
 * Copyright 2023 Google LLC
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
  firewall_policy   = google_compute_network_firewall_policy.net-global.0.name
}

resource "google_compute_network_firewall_policy_rule" "net-global" {
  for_each = (
    !local.use_hierarchical && !local.use_regional ? local.rules : {}
  )
  project                 = var.parent_id
  firewall_policy         = google_compute_network_firewall_policy.net-global.0.name
  rule_name               = each.key
  action                  = each.value.action
  description             = each.value.description
  direction               = each.value.direction
  disabled                = each.value.disabled
  enable_logging          = each.value.enable_logging
  priority                = each.value.priority
  target_service_accounts = each.value.target_service_accounts
  match {
    dest_ip_ranges = each.value.match.destination_ranges
    src_ip_ranges  = each.value.match.source_ranges
    dest_address_groups = (
      each.value.direction == "EGRESS" ? each.value.match.address_groups : null
    )
    dest_fqdns = (
      each.value.direction == "EGRESS" ? each.value.match.fqdns : null
    )
    dest_region_codes = (
      each.value.direction == "EGRESS" ? each.value.match.region_codes : null
    )
    dest_threat_intelligences = (
      each.value.direction == "EGRESS" ? each.value.match.threat_intelligences : null
    )
    src_address_groups = (
      each.value.direction == "INGRESS" ? each.value.match.address_groups : null
    )
    src_fqdns = (
      each.value.direction == "INGRESS" ? each.value.match.fqdns : null
    )
    src_region_codes = (
      each.value.direction == "INGRESS" ? each.value.match.region_codes : null
    )
    src_threat_intelligences = (
      each.value.direction == "INGRESS" ? each.value.match.threat_intelligences : null
    )
    dynamic "layer4_configs" {
      for_each = each.value.match.layer4_configs
      content {
        ip_protocol = layer4_configs.value.protocol
        ports       = layer4_configs.value.ports
      }
    }
    dynamic "src_secure_tags" {
      for_each = toset(coalesce(each.value.match.source_tags, []))
      content {
        name = src_secure_tags.key
      }
    }
  }
  dynamic "target_secure_tags" {
    for_each = toset(
      each.value.target_tags == null ? [] : each.value.target_tags
    )
    content {
      name = target_secure_tags.value
    }
  }
}
