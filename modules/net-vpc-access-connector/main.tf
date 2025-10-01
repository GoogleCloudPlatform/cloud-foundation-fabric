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
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  ctx_p = "$"

  # Network - already resolved in factory to full self-link, use directly
  # Factory resolves $vpc_ids: references to projects/PROJECT_ID/global/networks/NAME
  network_id   = lookup(local.ctx.vpc_ids, var.network_id, var.network_id)
  segments     = split("/", local.network_id)
  project_id   = local.segments[1]
  network_name = local.segments[4]
}

resource "google_vpc_access_connector" "connector" {
  count = var.connector_create ? 1 : 0

  # Core connector configuration
  project = local.project_id
  name    = var.name
  region  = var.region

  # Network configuration - can specify either network or subnet
  network = var.subnet == null ? local.network_name : null
  subnet {
    name       = var.subnet != null ? var.subnet : null
    project_id = var.subnet != null ? (var.subnet_project_id != null ? var.subnet_project_id : local.project_id) : null
  }

  # IP CIDR range for the connector
  ip_cidr_range = var.ip_cidr_range

  # Scaling configuration
  min_instances = var.min_instances
  max_instances = var.max_instances

  # Throughput configuration (alternative to min/max instances)
  min_throughput = var.min_throughput
  max_throughput = var.max_throughput

  # Machine type
  machine_type = var.machine_type
}