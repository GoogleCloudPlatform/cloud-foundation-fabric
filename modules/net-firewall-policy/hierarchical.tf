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

resource "google_compute_firewall_policy" "hierarchical" {
  count       = local.use_hierarchical ? 1 : 0
  parent      = lookup(local.ctx.folder_ids, var.parent_id, var.parent_id)
  short_name  = var.name
  description = var.description
}

resource "google_compute_firewall_policy_association" "hierarchical" {
  for_each          = local.use_hierarchical ? var.attachments : {}
  name              = "${var.name}-${each.key}"
  attachment_target = lookup(local.ctx.folder_ids, each.value, each.value)
  firewall_policy   = google_compute_firewall_policy.hierarchical[0].name
}

resource "google_compute_firewall_policy_rule" "hierarchical" {
  # Terraform's type system barfs in the condition if we use the locals map
  for_each        = local.use_hierarchical ? local.rules : {}
  firewall_policy = google_compute_firewall_policy.hierarchical[0].name
  action          = each.value.action
  description     = each.value.description
  direction       = each.value.direction
  disabled        = each.value.disabled
  enable_logging  = each.value.enable_logging
  priority        = each.value.priority
  target_resources = (
    each.value.target_resources == null ? null : [
      for n in each.value.target_resources :
      lookup(local.ctx.networks, n, n)
    ]
  )
  target_service_accounts = (
    each.value.target_service_accounts == null ? null : [
      for n in each.value.target_service_accounts :
      lookup(local.ctx.iam_principals, n, n)
    ]
  )
  tls_inspect = each.value.tls_inspect
  security_profile_group = try(
    var.security_profile_group_ids[each.value.security_profile_group],
    each.value.security_profile_group
  )
  match {
    dest_ip_ranges = (
      each.value.match.destination_ranges == null ? null : [
        for r in each.value.match.destination_ranges :
        lookup(local.ctx.cidr_ranges, r, r)
      ]
    )
    src_ip_ranges = (
      each.value.match.source_ranges == null ? null : [
        for r in each.value.match.source_ranges :
        lookup(local.ctx.cidr_ranges, r, r)
      ]
    )
    dest_address_groups = (
      each.value.direction == "EGRESS"
      ? each.value.match.address_groups
      : null
    )
    dest_fqdns = (
      each.value.direction == "EGRESS"
      ? each.value.match.fqdns
      : null
    )
    dest_region_codes = (
      each.value.direction == "EGRESS"
      ? each.value.match.region_codes
      : null
    )
    dest_threat_intelligences = (
      each.value.direction == "EGRESS"
      ? each.value.match.threat_intelligences
      : null
    )
    src_address_groups = (
      each.value.direction == "INGRESS"
      ? each.value.match.address_groups
      : null
    )
    src_fqdns = (
      each.value.direction == "INGRESS"
      ? each.value.match.fqdns
      : null
    )
    src_region_codes = (
      each.value.direction == "INGRESS"
      ? each.value.match.region_codes
      : null
    )
    src_threat_intelligences = (
      each.value.direction == "INGRESS"
      ? each.value.match.threat_intelligences
      : null
    )
    dynamic "layer4_configs" {
      for_each = each.value.match.layer4_configs
      content {
        ip_protocol = layer4_configs.value.protocol
        ports       = layer4_configs.value.ports
      }
    }
  }
}
