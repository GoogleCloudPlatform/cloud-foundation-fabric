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
  rules = flatten([
    for file in fileset(var.config_folder, "**/*.yaml") : [
      for key, ruleset in yamldecode(file("${var.config_folder}/${file}")) :
      merge(ruleset, {
        project_id = split("/", file)[0]
        network    = split("/", file)[1]
        name       = "${key}-${split("/", file)[1]}"

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
        source_service_accounts = try(ruleset.source_service_accounts, null) == null ? null : flatten(
          [for service_account in ruleset.source_service_accounts :
            can(regex("^\\$", service_account))
            ? local.service_accounts[trimprefix(service_account, "$")]
            : [service_account]
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

  rules_allow = [for item in local.rules : item if item.action == "allow"]
  rules_deny  = [for item in local.rules : item if item.action == "deny"]

}


resource "google_compute_firewall" "rules-allow" {
  for_each    = { for rule in local.rules_allow : "${rule.network}-${rule.name}" => rule }
  project     = each.value.project_id
  name        = each.value.name
  description = each.value.description
  network     = each.value.network
  direction   = each.value.direction
  priority    = each.value.priority

  source_ranges           = try(each.value.source_ranges, each.value.direction == "INGRESS" ? [] : null)
  source_tags             = try(each.value.source_tags, null)
  source_service_accounts = try(each.value.source_service_accounts, null)

  destination_ranges      = try(each.value.destination_ranges, each.value.direction == "EGRESS" ? [] : null)
  target_tags             = try(each.value.target_tags, null)
  target_service_accounts = try(each.value.target_service_accounts, null)

  dynamic "allow" {
    for_each = { for proto, ports in try(each.value.ports, []) :
      "${proto}-${join("-", ports)}" => {
        ports    = [for port in ports : tostring(port)]
        protocol = proto
      }
    }
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "log_config" {
    for_each = (each.value.enable_logging == null) || (each.value.enable_logging == false) ? [] : [""]
    content {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "google_compute_firewall" "rules-deny" {
  for_each    = { for rule in local.rules_deny : "${rule.network}-${rule.name}" => rule }
  project     = each.value.project_id
  name        = each.value.name
  description = each.value.description
  network     = each.value.network
  direction   = each.value.direction
  priority    = each.value.priority

  source_ranges           = try(each.value.source_ranges, each.value.direction == "INGRESS" ? [] : null)
  source_tags             = try(each.value.source_tags, null)
  source_service_accounts = try(each.value.source_service_accounts, null)

  destination_ranges      = try(each.value.destination_ranges, each.value.direction == "EGRESS" ? [] : null)
  target_tags             = try(each.value.target_tags, null)
  target_service_accounts = try(each.value.target_service_accounts, null)

  dynamic "deny" {
    for_each = { for proto, ports in try(each.value.ports, []) :
      "${proto}-${join("-", ports)}" => {
        ports    = [for port in ports : tostring(port)]
        protocol = proto
      }
    }
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }

  dynamic "log_config" {
    for_each = (each.value.enable_logging == null) || (each.value.enable_logging == false) ? [] : [""]
    content {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
