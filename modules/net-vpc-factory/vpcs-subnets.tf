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
  _subnets_data_files = merge([
    for vpc_key, vpc_config in local._vpc_raw : {
      for f in try(fileset(
        "${local._vpc_path}/${vpc_key}",
        "${try(vpc_config.factories_config.subnets_folder, "subnets")}/*.yaml"
      ), []) :
      # Key format: "vpc_path/file-name" (e.g., "environments/dev/subnet-1")
      "${vpc_key}/${trimsuffix(basename(f), ".yaml")}" => {
        file_path     = "${vpc_key}/${f}"
        vpc_key       = vpc_key
        environment   = try(vpc_config.environment, split("/", vpc_key)[length(split("/", vpc_key)) - 1])
        subnet_name   = trimsuffix(basename(f), ".yaml")
      }
    }
  ]...)

  # Process subnet configuration files
  _subnets_data_raw = {
    for k, v in local._subnets_data_files :
    k => merge(
      v,
      yamldecode(file("${local._vpc_path}/${v.file_path}"))
    )
  }

  vpc_subnet_ids = {
    for k, v in module.subnets : k => v.id
  }
  # Build VPC network IDs map for subnet network references

  subnet_inputs = {
    for k, v in local._subnets_data_raw : k => merge(v, {
      network_id = try(coalesce(
        local.data_defaults.overrides.subnets.network_id,
        try(v.network_id, null),
        local.data_defaults.defaults.subnets.network_id
      ), null)

      name = try(coalesce(
        local.data_defaults.overrides.subnets.name,
        try(v.name, null),
        local.data_defaults.defaults.subnets.name
      ), null)

      region = try(coalesce(
        local.data_defaults.overrides.subnets.region,
        try(v.region, null),
        local.data_defaults.defaults.subnets.region
      ), null)

      ip_cidr_range = try(coalesce(
        local.data_defaults.overrides.subnets.ip_cidr_range,
        try(v.ip_cidr_range, null),
        local.data_defaults.defaults.subnets.ip_cidr_range
      ), null)

      # description (optional, default: "Managed by net-vpc-subnet module")
      description = try(coalesce(
        local.data_defaults.overrides.subnets.description,
        try(v.description, null),
        local.data_defaults.defaults.subnets.description
      ), "Managed by net-vpc-factory")

      # private_ip_google_access (optional, default: true)
      private_ip_google_access = try(coalesce(
        local.data_defaults.overrides.subnets.private_ip_google_access,
        try(v.private_ip_google_access, null),
        local.data_defaults.defaults.subnets.private_ip_google_access
      ), true)

      # enable_flow_logs (optional, default: false)
      enable_flow_logs = try(coalesce(
        local.data_defaults.overrides.subnets.enable_flow_logs,
        try(v.enable_flow_logs, null),
        local.data_defaults.defaults.subnets.enable_flow_logs
      ), false)

      # log_config (optional, default: null)
      log_config = try(coalesce(
        local.data_defaults.overrides.subnets.log_config,
        try(v.log_config, null),
        local.data_defaults.defaults.subnets.log_config
      ), null)

      # purpose (optional, default: null)
      purpose = try(coalesce(
        local.data_defaults.overrides.subnets.purpose,
        try(v.purpose, null),
        local.data_defaults.defaults.subnets.purpose
      ), null)

      # role (optional, default: null)
      role = try(coalesce(
        local.data_defaults.overrides.subnets.role,
        try(v.role, null),
        local.data_defaults.defaults.subnets.role
      ), null)

      # secondary_ip_ranges (optional, default: {})
      secondary_ip_ranges = try(coalesce(
        local.data_defaults.overrides.subnets.secondary_ip_ranges,
        try(v.secondary_ip_ranges, null),
        local.data_defaults.defaults.subnets.secondary_ip_ranges
      ), {})

      # subnet_create (optional, default: true)
      subnet_create = try(coalesce(
        local.data_defaults.overrides.subnets.subnet_create,
        try(v.subnet_create, null),
        local.data_defaults.defaults.subnets.subnet_create
      ), true)

      # IAM fields (optional, default: {})
      iam = try(coalesce(
        local.data_defaults.overrides.subnets.iam,
        try(v.iam, null),
        local.data_defaults.defaults.subnets.iam
      ), {})

      iam_bindings = try(coalesce(
        local.data_defaults.overrides.subnets.iam_bindings,
        try(v.iam_bindings, null),
        local.data_defaults.defaults.subnets.iam_bindings
      ), {})

      iam_bindings_additive = try(coalesce(
        local.data_defaults.overrides.subnets.iam_bindings_additive,
        try(v.iam_bindings_additive, null),
        local.data_defaults.defaults.subnets.iam_bindings_additive
      ), {})

      iam_by_principals = try(coalesce(
        local.data_defaults.overrides.subnets.iam_by_principals,
        try(v.iam_by_principals, null),
        local.data_defaults.defaults.subnets.iam_by_principals
      ), {})

      tag_bindings  = try(coalesce(
        local.data_defaults.overrides.subnets.tag_bindings ,
        try(v.tag_bindings , null),
        local.data_defaults.defaults.subnets.tag_bindings 
      ), {})
    })
  }
}

module "subnets" {
  source = "../net-vpc-subnet"

  for_each = local.subnet_inputs

  name          = each.value.name
  region        = each.value.region
  network_id       = each.value.network_id
  ip_cidr_range = each.value.ip_cidr_range

  # Optional configuration (already processed with defaults)
  description              = each.value.description
  private_ip_google_access = each.value.private_ip_google_access
  purpose                  = each.value.purpose
  role                     = each.value.role
  subnet_create            = each.value.subnet_create

  # Secondary IP ranges
  secondary_ip_ranges = each.value.secondary_ip_ranges

  # Flow logs configuration
  log_config = each.value.log_config

  # IAM configuration
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_by_principals     = each.value.iam_by_principals
  tag_bindings                    = each.value.tag_bindings  

  context = merge(local.ctx, {
    vpc_ids = merge(local.ctx.vpc_ids, local.vpc_ids)
  })
}

