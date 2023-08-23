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

locals {
  _factory_egress_rules = try(
    yamldecode(file(var.rules_factory_config.egress_rules_file_path)), {}
  )
  _factory_ingress_rules = try(
    yamldecode(file(var.rules_factory_config.ingress_rules_file_path)), {}
  )
  factory_cidrs = try(
    yamldecode(file(var.rules_factory_config.cidr_file_path)), {}
  )
  factory_egress_rules = {
    for k, v in local._factory_egress_rules : "egress/${k}" => {
      direction               = "EGRESS"
      name                    = k
      priority                = v.priority
      action                  = lookup(v, "action", "deny")
      description             = lookup(v, "description", null)
      disabled                = lookup(v, "disabled", false)
      enable_logging          = lookup(v, "enable_logging", null)
      target_service_accounts = lookup(v, "target_service_accounts", null)
      target_tags             = lookup(v, "target_tags", null)
      match = {
        address_groups       = lookup(v.match, "address_groups", null)
        fqdns                = lookup(v.match, "fqdns", null)
        region_codes         = lookup(v.match, "region_codes", null)
        threat_intelligences = lookup(v.match, "threat_intelligences", null)
        destination_ranges = (
          lookup(v.match, "destination_ranges", null) == null
          ? null
          : flatten([
            for r in v.match.destination_ranges :
            try(local.factory_cidrs[r], r)
          ])
        )
        source_ranges = (
          lookup(v.match, "source_ranges", null) == null
          ? null
          : flatten([
            for r in v.match.source_ranges :
            try(local.factory_cidrs[r], r)
          ])
        )
        source_tags = lookup(v.match, "source_tags", null)
        layer4_configs = (
          lookup(v.match, "layer4_configs", null) == null
          ? [{ protocol = "all", ports = null }]
          : [
            for c in v.match.layer4_configs :
            merge({ protocol = "all", ports = null }, c)
          ]
        )
      }
    }
  }
  factory_ingress_rules = {
    for k, v in local._factory_ingress_rules : "ingress/${k}" => {
      direction               = "INGRESS"
      name                    = k
      priority                = v.priority
      action                  = lookup(v, "action", "allow")
      description             = lookup(v, "description", null)
      disabled                = lookup(v, "disabled", false)
      enable_logging          = lookup(v, "enable_logging", null)
      target_service_accounts = lookup(v, "target_service_accounts", null)
      target_tags             = lookup(v, "target_tags", null)
      match = {
        address_groups       = lookup(v.match, "address_groups", null)
        fqdns                = lookup(v.match, "fqdns", null)
        region_codes         = lookup(v.match, "region_codes", null)
        threat_intelligences = lookup(v.match, "threat_intelligences", null)
        destination_ranges = (
          lookup(v.match, "destination_ranges", null) == null
          ? null
          : flatten([
            for r in v.match.destination_ranges :
            try(local.factory_cidrs[r], r)
          ])
        )
        source_ranges = (
          lookup(v.match, "source_ranges", null) == null
          ? null
          : flatten([
            for r in v.match.source_ranges :
            try(local.factory_cidrs[r], r)
          ])
        )
        source_tags = lookup(v.match, "source_tags", null)
        layer4_configs = (
          lookup(v.match, "layer4_configs", null) == null
          ? [{ protocol = "all", ports = null }]
          : [
            for c in v.match.layer4_configs :
            merge({ protocol = "all", ports = null }, c)
          ]
        )
      }
    }
  }
}
