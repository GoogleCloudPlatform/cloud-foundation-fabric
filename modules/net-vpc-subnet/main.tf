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
  segments = split("/", local.network_id)
  project_id   = local.segments[1]
  network_name = local.segments[4]
  # Region - use directly
}


data "google_compute_subnetwork" "subnet" {
  project       = local.project_id

  name          = google_compute_subnetwork.subnet[0].name
  region        = var.region
}

resource "google_compute_subnetwork" "subnet" {
  count = var.subnet_create ? 1 : 0

  # Core subnet configuration
  project       = local.project_id
  name          = var.name
  region        = var.region
  network       = local.network_id
  ip_cidr_range = var.ip_cidr_range

  # Optional configuration
  description                               = var.description
  private_ip_google_access                  = var.private_ip_google_access
  private_ipv6_google_access                = var.private_ipv6_google_access
  purpose                                   = var.purpose
  role                 = var.role
  stack_type           = var.stack_type
  ipv6_access_type     = var.ipv6_access_type
  external_ipv6_prefix = var.external_ipv6_prefix

  # Secondary IP ranges for GKE, etc.
  dynamic "secondary_ip_range" {
    for_each = var.secondary_ip_ranges
    content {
      range_name    = secondary_ip_range.key
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  # Flow logs configuration
  dynamic "log_config" {
    for_each = var.log_config != null ? [var.log_config] : []
    content {
      aggregation_interval = log_config.value.aggregation_interval
      flow_sampling        = log_config.value.flow_sampling
      metadata             = log_config.value.metadata
      metadata_fields      = log_config.value.metadata_fields
      filter_expr          = log_config.value.filter_expr
    }
  }
}