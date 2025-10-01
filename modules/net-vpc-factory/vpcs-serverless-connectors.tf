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
  _serverless_connectors_data_files = merge([
    for vpc_key, vpc_config in local._vpc_raw : {
      for f in try(fileset(
        "${local._vpc_path}/${vpc_key}",
        "${try(vpc_config.factories_config.serverless_connector_folder, "serverless-connectors")}/*.yaml"
      ), []) :
      "${vpc_key}/${trimsuffix(basename(f), ".yaml")}" => {
        file_path      = "${vpc_key}/${f}"
        vpc_key        = vpc_key
        environment    = try(vpc_config.environment, split("/", vpc_key)[length(split("/", vpc_key)) - 1])
        connector_name = trimsuffix(basename(f), ".yaml")
      }
    }
  ]...)

  _serverless_connectors_data_raw = {
    for k, v in local._serverless_connectors_data_files : k => merge(
      yamldecode(file("${local._vpc_path}/${v.file_path}")),
      {
        vpc_key        = v.vpc_key
        environment    = v.environment
        connector_name = v.connector_name
      }
    )
  }

  serverless_connector_inputs = {
    for k, v in local._serverless_connectors_data_raw : k => merge(v, {
      # name - required
      name = try(
        coalesce(
          local.data_defaults.overrides.serverless_connectors.name,
          try(v.name, null),
          local.data_defaults.defaults.serverless_connectors.name
        ),
        v.connector_name
      )

      # network_id - resolve $vpc_ids: references
      network_id = try(
        coalesce(
          local.data_defaults.overrides.serverless_connectors.network_id,
          v.network_id,
          local.data_defaults.defaults.serverless_connectors.network_id
        ),
        null
      )

      # region - required
      region = try(
        coalesce(
          local.data_defaults.overrides.serverless_connectors.region,
          try(v.region, null),
          local.data_defaults.defaults.serverless_connectors.region
        ),
        null
      )

      # ip_cidr_range
      ip_cidr_range = try(
        coalesce(
          local.data_defaults.overrides.serverless_connectors.ip_cidr_range,
          try(v.ip_cidr_range, null),
          local.data_defaults.defaults.serverless_connectors.ip_cidr_range
        ),
        null
      )

      # subnet
      subnet = try(
        coalesce(
          local.data_defaults.overrides.serverless_connectors.subnet,
          try(v.subnet, null),
          local.data_defaults.defaults.serverless_connectors.subnet
        ),
        null
      )

      # subnet_project_id
      subnet_project_id = try(
        coalesce(
          local.data_defaults.overrides.serverless_connectors.subnet_project_id,
          try(v.subnet_project_id, null),
          local.data_defaults.defaults.serverless_connectors.subnet_project_id
        ),
        null
      )

      # min_instances
      min_instances = try(
        coalesce(
          local.data_defaults.overrides.serverless_connectors.min_instances,
          try(v.min_instances, null),
          local.data_defaults.defaults.serverless_connectors.min_instances
        ),
        null
      )

      # max_instances
      max_instances = try(
        coalesce(
          local.data_defaults.overrides.serverless_connectors.max_instances,
          try(v.max_instances, null),
          local.data_defaults.defaults.serverless_connectors.max_instances
        ),
        null
      )

      # min_throughput
      min_throughput = try(
        coalesce(
          local.data_defaults.overrides.serverless_connectors.min_throughput,
          try(v.min_throughput, null),
          local.data_defaults.defaults.serverless_connectors.min_throughput
        ),
        null
      )

      # max_throughput
      max_throughput = try(
        coalesce(
          local.data_defaults.overrides.serverless_connectors.max_throughput,
          try(v.max_throughput, null),
          local.data_defaults.defaults.serverless_connectors.max_throughput
        ),
        null
      )

      # machine_type
      machine_type = try(
        coalesce(
          local.data_defaults.overrides.serverless_connectors.machine_type,
          try(v.machine_type, null),
          local.data_defaults.defaults.serverless_connectors.machine_type
        ),
        "e2-micro"
      )

      # connector_create
      connector_create = try(
        coalesce(
          local.data_defaults.overrides.serverless_connectors.connector_create,
          try(v.connector_create, null),
          local.data_defaults.defaults.serverless_connectors.connector_create
        ),
        true
      )
    })
  }
}

module "serverless_connectors" {
  source   = "../net-vpc-access-connector"
  for_each = local.serverless_connector_inputs

  context = merge(local.ctx, {
    vpc_ids = merge(local.ctx.vpc_ids, local.vpc_ids)
  })

  # Core connector configuration
  name       = each.value.name
  network_id = each.value.network_id
  region     = each.value.region

  # IP and subnet configuration
  ip_cidr_range     = each.value.ip_cidr_range
  subnet            = each.value.subnet
  subnet_project_id = each.value.subnet_project_id

  # Scaling configuration
  min_instances  = each.value.min_instances
  max_instances  = each.value.max_instances
  min_throughput = each.value.min_throughput
  max_throughput = each.value.max_throughput

  # Machine type
  machine_type = each.value.machine_type

  # Control
  connector_create = each.value.connector_create

  depends_on = [ module.vpcs ]
}