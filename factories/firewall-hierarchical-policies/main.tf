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
  cidrs = try({ for name, cidrs in yamldecode(file("${var.templates_folder}/cidrs.yaml")) :
    name => cidrs
  }, {})

  service_accounts = try({ for name, service_accounts in yamldecode(file("${var.templates_folder}/service_accounts.yaml")) :
    name => service_accounts
  }, {})

  org_paths = {
    for file in fileset(var.config_folder, "**/*.yaml") :
    file => split("/", file)[1] == "org.yaml"
    ? "organizations/${split("/", file)[0]}"
    : "folders/${split("-", split("/", file)[1])[0]}"
  }

  rules = flatten([
    for file in fileset(var.config_folder, "**/*.yaml") : [
      for key, ruleset in yamldecode(file("${var.config_folder}/${file}")) :
      merge(ruleset, {
        parent_id = local.org_paths[file]
        name      = "${replace(local.org_paths[file], "/", "-")}-${key}"
        source_ranges = try(ruleset.source_ranges, null) == null ? null : flatten(
          [for cidr in ruleset.source_ranges :
            can(regex("^\\$", cidr))
            ? local.cidrs[trimprefix(cidr, "$")]
            : [cidr]
        ])
        destination_ranges = try(ruleset.destination_ranges, null) == null ? null : flatten(
          [for cidr in ruleset.destination_ranges :
            can(regex("^\\$", cidr))
            ? local.cidrs[trimprefix(cidr, "$")]
            : [cidr]
        ])
        target_service_accounts = try(ruleset.target_service_accounts, null) == null ? null : flatten(
          [for service_account in ruleset.target_service_accounts :
            can(regex("^\\$", service_account))
            ? local.service_accounts[trimprefix(service_account, "$")]
            : [service_account]
        ])
      })
    ]
  ])
}

resource "google_compute_firewall_policy" "default" {
  for_each    = { for rule in local.rules : rule.parent_id => rule.name... }
  short_name  = replace("hierarchical-fw-policy-${each.key}", "/", "-")
  description = replace("hierarchical-fw-policy-${each.key}", "/", "-")
  parent      = each.key
}

resource "google_compute_firewall_policy_rule" "default" {
  for_each                = { for rule in local.rules : "${rule.parent_id}-${rule.name}" => rule }
  firewall_policy         = google_compute_firewall_policy.default[each.value.parent_id].id
  action                  = each.value.action
  direction               = each.value.direction
  priority                = each.value.priority
  target_resources        = each.value.target_resources
  target_service_accounts = each.value.target_service_accounts
  enable_logging          = try(each.value.enable_logging, false)
  # preview                 = each.value.preview
  match {
    src_ip_ranges  = each.value.direction == "INGRESS" ? each.value.source_ranges : null
    dest_ip_ranges = each.value.direction == "EGRESS" ? each.value.destination_ranges : null
    dynamic "layer4_configs" {
      for_each = each.value.ports
      iterator = port
      content {
        ip_protocol = port.key
        ports       = port.value
      }
    }
  }
}

resource "google_compute_firewall_policy_association" "default" {
  for_each          = { for rule in local.rules : rule.parent_id => rule.name... }
  name              = replace("hierarchical-fw-policy-${each.key}", "/", "-")
  attachment_target = google_compute_firewall_policy.default[each.key].parent
  firewall_policy   = google_compute_firewall_policy.default[each.key].id
}
