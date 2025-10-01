/**
 * Copyright 2025 Google LLC
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
  _firewall_rules_data_files = merge([
    for vpc_key, vpc_config in local._vpc_raw : {
      for f in try(fileset(
        "${local._vpc_path}/${vpc_key}",
        "${try(vpc_config.factories_config.firewall_rules_folder, "firewall-rules")}/*.yaml"
      ), []) :
      # Key format: "vpc_path/file-name" (e.g., "environments/dev/allow-iap")
      "${vpc_key}/${trimsuffix(basename(f), ".yaml")}" => {
        file_path   = "${vpc_key}/${f}"
        vpc_key     = vpc_key
        environment = try(vpc_config.environment, split("/", vpc_key)[length(split("/", vpc_key)) - 1])
        rule_name   = trimsuffix(basename(f), ".yaml")
      }
    }
  ]...)

  # Process firewall rule configuration files
  _firewall_rules_data_raw = {
    for k, v in local._firewall_rules_data_files :
    k => merge(
      v,
      yamldecode(file("${local._vpc_path}/${v.file_path}"))
    )
  }

  firewall_rule_inputs = {
    for k, v in local._firewall_rules_data_raw : k => merge(v, {

      name = try(coalesce(
        local.data_defaults.overrides.firewall_rules.name,
        try(v.name, null),
        v.rule_name,  # fallback to rule_name from metadata
        local.data_defaults.defaults.firewall_rules.name
      ), null)

      network_id = try(
        coalesce(
          local.data_defaults.overrides.firewall_rules.network_id,
          # Get network_id from the VPC this rule belongs to
          v.network_id,
          local.data_defaults.defaults.firewall_rules.network_id
        ),
        null
      )

      direction = try(coalesce(
        local.data_defaults.overrides.firewall_rules.direction,
        try(v.direction, null),
        local.data_defaults.defaults.firewall_rules.direction
      ), "INGRESS")

      description = try(coalesce(
        local.data_defaults.overrides.firewall_rules.description,
        try(v.description, null),
        local.data_defaults.defaults.firewall_rules.description
      ), "Managed by net-vpc-factory")

      # priority (optional, default: 1000)
      priority = try(coalesce(
        local.data_defaults.overrides.firewall_rules.priority,
        try(v.priority, null),
        local.data_defaults.defaults.firewall_rules.priority
      ), 1000)

      # disabled (optional, default: false)
      disabled = try(coalesce(
        local.data_defaults.overrides.firewall_rules.disabled,
        try(v.disabled, null),
        local.data_defaults.defaults.firewall_rules.disabled
      ), false)

      # deny (optional, default: []) - list of deny rules
      deny = coalesce(
        local.data_defaults.overrides.firewall_rules.deny,
        try(v.deny, null),
        local.data_defaults.defaults.firewall_rules.deny,
        []
      )

      # allow (optional, default: []) - list of allow/deny rules
      allow = coalesce(
        local.data_defaults.overrides.firewall_rules.allow,
        try(v.allow, null),
        local.data_defaults.defaults.firewall_rules.allow,
        []
      )

      # source_ranges (optional, default: null)
      source_ranges = try(coalesce(
        local.data_defaults.overrides.firewall_rules.source_ranges,
        try(v.source_ranges, null),
        local.data_defaults.defaults.firewall_rules.source_ranges
      ), null)

      # source_tags (optional, default: null)
      source_tags = try(coalesce(
        local.data_defaults.overrides.firewall_rules.source_tags,
        try(v.source_tags, null),
        local.data_defaults.defaults.firewall_rules.source_tags
      ), null)

      # source_service_accounts (optional, default: null)
      source_service_accounts = try(coalesce(
        local.data_defaults.overrides.firewall_rules.source_service_accounts,
        try(v.source_service_accounts, null),
        local.data_defaults.defaults.firewall_rules.source_service_accounts
      ), null)

      # destination_ranges (optional, default: null)
      destination_ranges = try(coalesce(
        local.data_defaults.overrides.firewall_rules.destination_ranges,
        try(v.destination_ranges, null),
        local.data_defaults.defaults.firewall_rules.destination_ranges
      ), null)

      # target_tags (optional, default: null)
      target_tags = try(coalesce(
        local.data_defaults.overrides.firewall_rules.target_tags,
        try(v.target_tags, null),
        local.data_defaults.defaults.firewall_rules.target_tags
      ), null)

      # target_service_accounts (optional, default: null)
      target_service_accounts = try(coalesce(
        local.data_defaults.overrides.firewall_rules.target_service_accounts,
        try(v.target_service_accounts, null),
        local.data_defaults.defaults.firewall_rules.target_service_accounts
      ), null)

      # enable_logging (optional, default: null)
      enable_logging = try(coalesce(
        local.data_defaults.overrides.firewall_rules.enable_logging,
        try(v.enable_logging, null),
        local.data_defaults.defaults.firewall_rules.enable_logging
      ), null)

      # log_config (optional, default: null)
      log_config = try(coalesce(
        local.data_defaults.overrides.firewall_rules.log_config,
        try(v.log_config, null),
        local.data_defaults.defaults.firewall_rules.log_config
      ), null)

      # rule_create (optional, default: true)
      rule_create = try(coalesce(
        local.data_defaults.overrides.firewall_rules.rule_create,
        try(v.rule_create, null),
        local.data_defaults.defaults.firewall_rules.rule_create
      ), true)
    })
  }
}

module "firewall_rules" {
  source = "../net-vpc-firewall"

  for_each = local.firewall_rule_inputs

  name       = each.value.name
  network_id = each.value.network_id
  direction  = each.value.direction

  # Optional configuration (already processed with defaults)
  description             = each.value.description
  priority                = each.value.priority
  disabled                = each.value.disabled
  deny                    = each.value.deny
  allow                   = each.value.allow
  source_ranges           = each.value.source_ranges
  source_tags             = each.value.source_tags
  source_service_accounts = each.value.source_service_accounts
  destination_ranges      = each.value.destination_ranges
  target_tags             = each.value.target_tags
  target_service_accounts = each.value.target_service_accounts
  enable_logging          = each.value.enable_logging
  log_config              = each.value.log_config
  rule_create             = each.value.rule_create

  context = merge(local.ctx, {
    vpc_ids = merge(local.ctx.vpc_ids, local.vpc_ids)
  })

  depends_on = [ module.vpcs ]
}