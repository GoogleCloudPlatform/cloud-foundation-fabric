/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description Internal range resources.

locals {
  _internal_ranges_factory_data_raw = {
    for f in try(fileset(local._internal_ranges_factory_path, "**/*.yaml"), []) :
    trimsuffix(basename(f), ".yaml") => yamldecode(file("${local._internal_ranges_factory_path}/${f}"))
  }
  _internal_ranges_factory_data = {
    for k, v in local._internal_ranges_factory_data_raw : k => merge(v, {
      name = try(v.name, k)
    })
  }
  _internal_ranges_factory_path = try(pathexpand(var.factories_config.internal_ranges_folder), null)
  _factory_internal_ranges = {
    for k, v in local._internal_ranges_factory_data :
    try(v.name, k) => {
      description         = try(v.description, null)
      ip_cidr_range       = try(v.ip_cidr_range, null)
      labels              = try(v.labels, {})
      name                = try(v.name, k)
      network             = try(v.network, local.network.id)
      usage               = v.usage
      peering             = v.peering
      prefix_length       = try(v.prefix_length, null)
      target_cidr_range   = try(v.target_cidr_range, null)
      exclude_cidr_ranges = try(v.exclude_cidr_ranges, null)
      overlaps            = try(v.overlaps, null)
      immutable           = try(v.immutable, null)
      allocation_options = !can(v.allocation_options) ? null : {
        allocation_strategy                = try(v.allocation_options.allocation_strategy, null)
        first_available_ranges_lookup_size = try(v.allocation_options.first_available_ranges_lookup_size, null)
      }
      migration = !can(v.migration) ? null : {
        source = v.migration.source
        target = v.migration.target
      }
    }
  }

  internal_ranges = merge(
    { for r in var.internal_ranges : r.name => r },
    local._factory_internal_ranges
  )

  internal_ranges_ids = {
    for k, v in google_network_connectivity_internal_range.internal_range :
    k => v.id
  }
}

resource "google_network_connectivity_internal_range" "internal_range" {
  provider = google-beta
  for_each = local.internal_ranges
  project  = var.project_id
  name     = each.value.name
  network  = local.network.id

  description         = each.value.description
  ip_cidr_range       = each.value.ip_cidr_range
  labels              = each.value.labels
  usage               = each.value.usage
  peering             = each.value.peering
  prefix_length       = each.value.prefix_length
  target_cidr_range   = each.value.target_cidr_range
  exclude_cidr_ranges = each.value.exclude_cidr_ranges
  overlaps            = each.value.overlaps
  immutable           = each.value.immutable

  dynamic "allocation_options" {
    for_each = each.value.allocation_options != null ? [""] : []
    content {
      allocation_strategy                = each.value.allocation_options.allocation_strategy
      first_available_ranges_lookup_size = each.value.allocation_options.first_available_ranges_lookup_size
    }
  }

  dynamic "migration" {
    for_each = each.value.migration != null ? [""] : []
    content {
      source = each.value.migration.source
      target = each.value.migration.target
    }
  }
}
