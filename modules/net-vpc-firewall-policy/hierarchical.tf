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

resource "google_compute_firewall_policy" "hierarchical" {
  count       = local.use_hierarchical ? 1 : 0
  parent      = var.parent_id
  short_name  = var.name
  description = var.description
}

resource "google_compute_firewall_policy_association" "hierarchical" {
  for_each          = local.use_hierarchical ? var.attachments : {}
  name              = "${var.name}-${each.key}"
  attachment_target = each.value
  firewall_policy   = google_compute_firewall_policy.hierarchical.0.name
}

resource "google_compute_firewall_policy_rule" "hierarchical-egress" {
  for_each                = local.use_hierarchical ? var.egress_rules : {}
  firewall_policy         = google_compute_firewall_policy.hierarchical.0.name
  action                  = each.value.action
  description             = each.value.description
  direction               = "EGRESS"
  disabled                = each.value.disabled
  enable_logging          = each.value.enable_logging
  priority                = each.value.priority
  target_service_accounts = each.value.target_service_accounts
  match {
    dest_ip_ranges = each.value.match.destination_ranges
    src_ip_ranges  = each.value.match.source_ranges
    dynamic "layer4_configs" {
      for_each = each.value.match.layer4_configs
      content {
        ip_protocol = layer4_configs.value.protocol
        ports       = layer4_configs.value.ports
      }
    }
  }
}

resource "google_compute_firewall_policy_rule" "hierarchical-ingress" {
  for_each                = local.use_hierarchical ? var.ingress_rules : {}
  firewall_policy         = google_compute_firewall_policy.hierarchical.0.name
  action                  = each.value.action
  description             = each.value.description
  direction               = "INGRESS"
  disabled                = each.value.disabled
  enable_logging          = each.value.enable_logging
  priority                = each.value.priority
  target_service_accounts = each.value.target_service_accounts
  match {
    dest_ip_ranges = each.value.match.destination_ranges
    src_ip_ranges  = each.value.match.source_ranges
    dynamic "layer4_configs" {
      for_each = each.value.match.layer4_configs
      content {
        ip_protocol = layer4_configs.value.protocol
        ports       = layer4_configs.value.ports
      }
    }
  }
}
