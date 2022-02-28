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
  _custom_rules = {
    for id, rule in var.custom_rules :
    id => merge(rule, {
      # make rules a map so we use it in a for_each
      rules = { for index, ports in rule.rules : index => ports }
      # lookup any named ranges references
      ranges = flatten([
        for range in rule.ranges :
        try(var.named_ranges[range], range)
      ])
    })
  }

  cidrs = try({
    for name, cidrs in yamldecode(file(var.cidr_template_file)) :
    name => cidrs
  }, {})

  _factory_rules_raw = flatten([
    for file in try(fileset(var.data_folder, "**/*.yaml"), []) : [
      for key, ruleset in yamldecode(file("${var.data_folder}/${file}")) :
      merge(ruleset, {
        name  = "${key}"
        rules = { for index, ports in ruleset.rules : index => ports }
        ranges = try(ruleset.ranges, null) == null ? null : flatten(
          [for cidr in ruleset.ranges :
            can(regex("^\\$", cidr))
            ? local.cidrs[trimprefix(cidr, "$")]
            : [cidr]
        ])
        extra_attributes = try(ruleset.extra_attributes, {})
      })
    ]
  ])

  _factory_rules = {
    for d in local._factory_rules_raw : d["name"] => d
  }

  custom_rules = merge(local._custom_rules, local._factory_rules)
}


###############################################################################
#                            rules based on IP ranges
###############################################################################

resource "google_compute_firewall" "allow-admins" {
  count         = length(var.admin_ranges) > 0 ? 1 : 0
  name          = "${var.network}-ingress-admins"
  description   = "Access from the admin subnet to all subnets"
  network       = var.network
  project       = var.project_id
  source_ranges = var.admin_ranges
  allow { protocol = "all" }
}

###############################################################################
#                              rules based on tags
###############################################################################

resource "google_compute_firewall" "allow-tag-ssh" {
  count         = length(var.ssh_source_ranges) > 0 ? 1 : 0
  name          = "${var.network}-ingress-tag-ssh"
  description   = "Allow SSH to machines with the 'ssh' tag"
  network       = var.network
  project       = var.project_id
  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "allow-tag-http" {
  count         = length(var.http_source_ranges) > 0 ? 1 : 0
  name          = "${var.network}-ingress-tag-http"
  description   = "Allow HTTP to machines with the 'http-server' tag"
  network       = var.network
  project       = var.project_id
  source_ranges = var.http_source_ranges
  target_tags   = ["http-server"]
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_firewall" "allow-tag-https" {
  count         = length(var.https_source_ranges) > 0 ? 1 : 0
  name          = "${var.network}-ingress-tag-https"
  description   = "Allow HTTPS to machines with the 'https' tag"
  network       = var.network
  project       = var.project_id
  source_ranges = var.https_source_ranges
  target_tags   = ["https-server"]
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}

################################################################################
#                                dynamic rules                                 #
################################################################################

resource "google_compute_firewall" "custom-rules" {
  # provider                = "google-beta"
  for_each    = local.custom_rules
  name        = each.key
  description = each.value.description
  direction   = each.value.direction
  network     = var.network
  project     = var.project_id
  source_ranges = (
    each.value.direction == "INGRESS"
    ? coalesce(each.value.ranges, []) == [] ? ["0.0.0.0/0"] : each.value.ranges
    : null
  )
  destination_ranges = (
    each.value.direction == "EGRESS"
    ? coalesce(each.value.ranges, []) == [] ? ["0.0.0.0/0"] : each.value.ranges
    : null
  )
  source_tags             = each.value.use_service_accounts || each.value.direction == "EGRESS" ? null : each.value.sources
  source_service_accounts = each.value.use_service_accounts && each.value.direction == "INGRESS" ? each.value.sources : null
  target_tags             = each.value.use_service_accounts ? null : each.value.targets
  target_service_accounts = each.value.use_service_accounts ? each.value.targets : null
  disabled                = lookup(each.value.extra_attributes, "disabled", false)
  priority                = lookup(each.value.extra_attributes, "priority", 1000)

  dynamic "log_config" {
    for_each = lookup(each.value.extra_attributes, "logging", null) != null ? [each.value.extra_attributes.logging] : []
    iterator = logging_config
    content {
      metadata = logging_config.value
    }
  }

  dynamic "deny" {
    for_each = each.value.action == "deny" ? each.value.rules : {}

    iterator = rule
    content {
      protocol = rule.value.protocol
      ports    = rule.value.ports
    }
  }

  dynamic "allow" {
    for_each = each.value.action == "allow" ? each.value.rules : {}

    iterator = rule
    content {
      protocol = rule.value.protocol
      ports    = rule.value.ports
    }
  }
}
