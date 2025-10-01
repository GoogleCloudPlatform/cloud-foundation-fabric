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
  _addresses_data_files = merge([
    for vpc_key, vpc_config in local._vpc_raw : {
      for f in try(fileset(
        "${local._vpc_path}/${vpc_key}",
        "${try(vpc_config.factories_config.address_folder, "addresses")}/*.yaml"
      ), []) :
      "${vpc_key}/${trimsuffix(basename(f), ".yaml")}" => {
        file_path    = "${vpc_key}/${f}"
        vpc_key      = vpc_key
        environment  = try(vpc_config.environment, split("/", vpc_key)[length(split("/", vpc_key)) - 1])
        address_name = trimsuffix(basename(f), ".yaml")
      }
    }
  ]...)

  _addresses_data_raw = {
    for k, v in local._addresses_data_files : k => merge(
      yamldecode(file("${local._vpc_path}/${v.file_path}")),
      {
        vpc_key      = v.vpc_key
        environment  = v.environment
        address_name = v.address_name
      }
    )
  }


  address_inputs = {
    for k, v in local._addresses_data_raw : k => merge(v, {
      # name - required
      name = try(
        coalesce(
          local.data_defaults.overrides.addresses.name,
          try(v.name, null),
          local.data_defaults.defaults.addresses.name
        ),
        v.address_name
      )

      # project_id - resolve from VPC config
      project_id = try(
        coalesce(
          local.data_defaults.overrides.addresses.project_id,
          try(v.project_id, null),
          local.data_defaults.defaults.addresses.project_id
        ),
        null
      )

      # address_type
      address_type = try(
        coalesce(
          local.data_defaults.overrides.addresses.address_type,
          try(v.address_type, null),
          local.data_defaults.defaults.addresses.address_type
        ),
        "INTERNAL"
      )

      # address
      address = try(
        coalesce(
          local.data_defaults.overrides.addresses.address,
          try(v.address, null),
          local.data_defaults.defaults.addresses.address
        ),
        null
      )

      # region
      region = try(
        coalesce(
          local.data_defaults.overrides.addresses.region,
          try(v.region, null),
          local.data_defaults.defaults.addresses.region
        ),
        null
      )

      # description
      description = try(
        coalesce(
          local.data_defaults.overrides.addresses.description,
          try(v.description, null),
          local.data_defaults.defaults.addresses.description
        ),
        "Terraform managed."
      )

      # subnet_id - resolve $subnet_ids: references
      vpc_subnet_id = try(
        coalesce(
          local.data_defaults.overrides.addresses.vpc_subnet_id,
          v.vpc_subnet_id,
          local.data_defaults.defaults.addresses.vpc_subnet_id
        ),
        null
      )

      # network - resolve $vpc_ids: references
      vpc_id = try(
        coalesce(
          local.data_defaults.overrides.addresses.vpc_id,
          try(v.vpc_id, null),
          local.data_defaults.defaults.addresses.vpc_id
        ),
        null
      )

      # purpose
      purpose = try(
        coalesce(
          local.data_defaults.overrides.addresses.purpose,
          try(v.purpose, null),
          local.data_defaults.defaults.addresses.purpose
        ),
        null
      )

      # prefix_length
      prefix_length = try(
        coalesce(
          local.data_defaults.overrides.addresses.prefix_length,
          try(v.prefix_length, null),
          local.data_defaults.defaults.addresses.prefix_length
        ),
        null
      )

      # ipv6
      ipv6 = try(
        coalesce(
          local.data_defaults.overrides.addresses.ipv6,
          try(v.ipv6, null),
          local.data_defaults.defaults.addresses.ipv6
        ),
        null
      )

      # labels
      labels = try(
        coalesce(
          local.data_defaults.overrides.addresses.labels,
          try(v.labels, null),
          local.data_defaults.defaults.addresses.labels
        ),
        {}
      )

      # tier
      tier = try(
        coalesce(
          local.data_defaults.overrides.addresses.tier,
          try(v.tier, null),
          local.data_defaults.defaults.addresses.tier
        ),
        "PREMIUM"
      )

      # address_create
      address_create = try(
        coalesce(
          local.data_defaults.overrides.addresses.address_create,
          try(v.address_create, null),
          local.data_defaults.defaults.addresses.address_create
        ),
        true
      )

      # service_attachment
      service_attachment = try(
        coalesce(
          local.data_defaults.overrides.addresses.service_attachment,
          try(v.service_attachment, null),
          local.data_defaults.defaults.addresses.service_attachment
        ),
        null
      )

    })
  }
}

module "addresses" {
  source   = "../net-address"
  for_each = local.address_inputs

  context = merge(local.ctx, {
    vpc_subnet_ids = merge(local.ctx.vpc_subnet_ids, local.vpc_subnet_ids)
    vpc_ids = merge(local.ctx.vpc_ids, local.vpc_ids)
    project_ids = local.ctx.project_ids
  })

  # Core address configuration
  name         = each.value.name
  address_type = each.value.address_type
  address      = each.value.address
  region       = each.value.region
  description  = each.value.description

  # Network and subnet references
  project_id = each.value.project_id
  vpc_id  = each.value.vpc_id
  vpc_subnet_id = each.value.vpc_subnet_id

  # Purpose and prefix
  purpose       = each.value.purpose
  prefix_length = each.value.prefix_length

  # IPv6 configuration
  ipv6 = each.value.ipv6

  # Labels and tier
  labels = each.value.labels
  tier   = each.value.tier

  # PSC configuration
  service_attachment = each.value.service_attachment

  # Control
  address_create = each.value.address_create

  depends_on = [ module.vpcs ]
}