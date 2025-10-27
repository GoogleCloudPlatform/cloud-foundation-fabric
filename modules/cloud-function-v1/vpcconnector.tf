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
  _connector_subnet_name_ctx = (
    try(var.vpc_connector_create.subnet.name, null) == null ? false :
    contains(keys(local.ctx.subnets), var.vpc_connector_create.subnet.name)
  )
  # if you pass the subnet, you must pass only the name, not the whole id
  _connector_subnet_name = (
    local._connector_subnet_name_ctx
    ? reverse(split("/", local.ctx.subnets[var.vpc_connector_create.subnet.name]))[0]
    : try(var.vpc_connector_create.subnet.name, null)
  )
  # if project is not provided, but subnet is coming from context, use project from subnet id in context
  # and avoid lookups using null project
  _connector_subnet_project_input = try(var.vpc_connector_create.subnet.project_id, null)
  _connector_subnet_project = (
    local._connector_subnet_project_input == null
    ? (
      local._connector_subnet_name_ctx
      ? split("/", local.ctx.subnets[var.vpc_connector_create.subnet.name])[1]
      : null
    )
    : lookup(
      local.ctx.project_ids, local._connector_subnet_project_input,
      local._connector_subnet_project_input
    )
  )
}

resource "google_vpc_access_connector" "connector" {
  count   = var.vpc_connector_create != null ? 1 : 0
  project = local.project_id
  name = (
    var.vpc_connector_create.name != null
    ? var.vpc_connector_create.name
    : var.name
  )
  region = local.location
  ip_cidr_range = var.vpc_connector_create.ip_cidr_range == null ? null : lookup(
    local.ctx.cidr_ranges, var.vpc_connector_create.ip_cidr_range,
    var.vpc_connector_create.ip_cidr_range
  )
  network = var.vpc_connector_create.network == null ? null : lookup(
    local.ctx.networks, var.vpc_connector_create.network,
    var.vpc_connector_create.network
  )
  machine_type   = var.vpc_connector_create.machine_type
  max_instances  = var.vpc_connector_create.instances.max
  max_throughput = var.vpc_connector_create.throughput.max
  min_instances  = var.vpc_connector_create.instances.min
  min_throughput = var.vpc_connector_create.throughput.min
  dynamic "subnet" {
    for_each = var.vpc_connector_create.subnet.name == null ? [] : [""]
    content {
      name       = local._connector_subnet_name
      project_id = local._connector_subnet_project
    }
  }
}
