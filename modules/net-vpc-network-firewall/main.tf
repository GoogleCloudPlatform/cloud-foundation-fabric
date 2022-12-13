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
  _files = try(flatten(
    [
      for config_path in var.data_folders :
      concat(
        [
          for config_file in fileset("${path.root}/${config_path}", "**/*.yaml") :
          "${path.root}/${config_path}/${config_file}"
        ]
      )
    ]
  ), null)

  _files_rules = try(merge(
    [
      for config_file in local._files :
      try(yamldecode(file(config_file)), {})
    ]...
  ), null)

  firewall_rules = merge(try(local._files_rules, {}), try(var.firewall_rules, {}))

  rules = { for k, v in local.firewall_rules : k => {
    disabled                = try(v.disabled, false)
    description             = try(v.description, null)
    action                  = try(v.action, "allow")
    direction               = try(upper(v.direction), "INGRESS")
    priority                = try(v.priority, 1000)
    enable_logging          = try(v.enable_logging, false)
    layer4_configs          = try(v.layer4_configs, [{ protocol = "all" }])
    target_service_accounts = try(v.target_service_accounts, null)
    dest_ip_ranges          = try(v.dest_ip_ranges, null)
    src_ip_ranges           = try(v.src_ip_ranges, null)
    src_secure_tags         = try(v.src_secure_tags, null)
    target_secure_tags      = try(v.target_secure_tags, null)
    }
  }
}

resource "google_compute_network_firewall_policy" "default" {
  count       = var.deployment_scope == "global" ? 1 : 0
  name        = var.global_policy_name
  project     = var.project_id
  description = "Global network firewall policy"
}

resource "google_compute_network_firewall_policy_rule" "default" {
  for_each        = var.deployment_scope == "global" ? local.rules : {}
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.default[0].name
  rule_name       = each.key
  disabled        = each.value["disabled"]
  action          = each.value["action"]
  direction       = each.value["direction"]
  priority        = each.value["priority"]
  description     = each.value["description"]
  enable_logging  = each.value["enable_logging"]
  match {
    dynamic "src_secure_tags" {
      for_each = each.value["src_secure_tags"] == null ? [] : each.value["src_secure_tags"]
      content {
        name = "tagValues/${src_secure_tags.value}"
      }
    }

    dynamic "layer4_configs" {
      for_each = each.value["layer4_configs"]
      content {
        ip_protocol = layer4_configs.value.protocol
        ports       = try(layer4_configs.value.ports, [])
      }
    }

    dest_ip_ranges = each.value["dest_ip_ranges"]
    src_ip_ranges  = each.value["src_ip_ranges"]
  }

  target_service_accounts = each.value["target_service_accounts"]
  dynamic "target_secure_tags" {
    for_each = each.value["target_secure_tags"] == null ? [] : each.value["target_secure_tags"]
    content {
      name = "tagValues/${target_secure_tags.value}"
    }
  }
}

resource "google_compute_network_firewall_policy_association" "default" {
  count             = var.deployment_scope == "global" && var.global_network != null ? 1 : 0
  name              = "global-association"
  attachment_target = var.global_network
  firewall_policy   = google_compute_network_firewall_policy.default[0].name
  project           = var.project_id
}

resource "google_compute_region_network_firewall_policy" "default" {
  count       = var.deployment_scope == "regional" ? 1 : 0
  name        = var.regional_policy_name
  project     = var.project_id
  description = "Regional network firewall policy"
  region      = var.firewall_policy_region
}

resource "google_compute_region_network_firewall_policy_rule" "default" {
  for_each        = var.deployment_scope == "regional" ? local.rules : {}
  project         = var.project_id
  firewall_policy = google_compute_region_network_firewall_policy.default[0].name
  region          = var.firewall_policy_region
  rule_name       = each.key
  disabled        = each.value["disabled"]
  action          = each.value["action"]
  direction       = each.value["direction"]
  priority        = each.value["priority"]
  description     = each.value["description"]
  enable_logging  = each.value["enable_logging"]

  match {
    dynamic "src_secure_tags" {
      for_each = each.value["src_secure_tags"] == null ? [] : each.value["src_secure_tags"]
      content {
        name = "tagValues/${src_secure_tags.value}"
      }
    }

    dynamic "layer4_configs" {
      for_each = each.value["layer4_configs"]
      content {
        ip_protocol = layer4_configs.value.protocol
        ports       = try(layer4_configs.value.ports, [])
      }
    }

    dest_ip_ranges = each.value["dest_ip_ranges"]
    src_ip_ranges  = each.value["src_ip_ranges"]
  }

  target_service_accounts = each.value["target_service_accounts"]
  dynamic "target_secure_tags" {
    for_each = each.value["target_secure_tags"] == null ? [] : each.value["target_secure_tags"]
    content {
      name = "tagValues/${target_secure_tags.value}"
    }
  }
}

resource "google_compute_region_network_firewall_policy_association" "default" {
  count             = var.deployment_scope == "regional" && var.regional_network != null ? 1 : 0
  name              = "regional-association"
  attachment_target = var.regional_network
  firewall_policy   = google_compute_region_network_firewall_policy.default[0].name
  project           = var.project_id
  region            = var.firewall_policy_region
}