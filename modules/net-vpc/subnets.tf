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

# tfdoc:file:description Subnet resources.

locals {
  _factory_data_raw = {
    for f in try(fileset(local._factory_path, "**/*.yaml"), []) :
    trimsuffix(basename(f), ".yaml") => yamldecode(file("${local._factory_path}/${f}"))
  }
  _factory_data = {
    for k, v in local._factory_data_raw : k => merge(v, {
      region_computed = lookup(local.ctx.locations, v.region, v.region)
    })
  }
  _factory_path = try(pathexpand(var.factories_config.subnets_folder), null)
  _factory_subnets = {
    for k, v in local._factory_data :
    "${v.region_computed}/${try(v.name, k)}" => {
      active                           = try(v.active, true)
      description                      = try(v.description, null)
      enable_private_access            = try(v.enable_private_access, true)
      allow_subnet_cidr_routes_overlap = try(v.allow_subnet_cidr_routes_overlap, null)
      reserved_internal_range          = try(v.reserved_internal_range, null)
      flow_logs_config = can(v.flow_logs_config) ? {
        aggregation_interval = try(v.flow_logs_config.aggregation_interval, null)
        filter_expression    = try(v.flow_logs_config.filter_expression, null)
        flow_sampling        = try(v.flow_logs_config.flow_sampling, null)
        metadata             = try(v.flow_logs_config.metadata, null)
        metadata_fields      = try(v.flow_logs_config.metadata_fields, null)
      } : null
      global        = try(v.global, false)
      ip_cidr_range = try(v.ip_cidr_range, null)
      ipv6 = !can(v.ipv6) ? null : {
        access_type = try(v.ipv6.access_type, "INTERNAL")
        ipv6_only   = try(v.ipv6.ipv6_only, false)
      }
      ip_collection = try(v.ip_collection, null)
      name          = try(v.name, k)
      region        = v.region_computed
      secondary_ip_ranges = !can(v.secondary_ip_ranges) ? null : {
        for k2, v2 in v.secondary_ip_ranges :
        k2 => {
          ip_cidr_range           = try(v2.ip_cidr_range, null)
          reserved_internal_range = try(v2.reserved_internal_range, null)
        }
      }
      iam = try(v.iam, {})
      iam_bindings = !can(v.iam_bindings) ? {} : {
        for k2, v2 in v.iam_bindings :
        k2 => {
          role    = v2.role
          members = v2.members
          condition = !can(v2.condition) ? null : {
            expression  = v2.condition.expression
            title       = v2.condition.title
            description = try(v2.condition.description, null)
          }
        }
      }
      iam_bindings_additive = !can(v.iam_bindings_additive) ? {} : {
        for k2, v2 in v.iam_bindings_additive :
        k2 => {
          member = v2.member
          role   = v2.role
          condition = !can(v2.condition) ? null : {
            expression  = v2.condition.expression
            title       = v2.condition.title
            description = try(v2.condition.description, null)
          }
        }
      }
      _is_regular    = !try(v.psc == true, false) && !try(v.proxy_only == true, false)
      _is_psc        = try(v.psc == true, false)
      _is_proxy_only = try(v.proxy_only == true, false)
    }
  }
  _iam_subnets = concat(
    var.subnets, var.subnets_psc, var.subnets_proxy_only, values(local._factory_subnets)
  )
  all_subnets = merge(
    { for k, v in google_compute_subnetwork.subnetwork : k => v },
    { for k, v in google_compute_subnetwork.proxy_only : k => v },
    { for k, v in google_compute_subnetwork.psc : k => v }
  )
  subnet_iam = flatten(concat(
    [
      for s in local._iam_subnets : [
        for role, members in s.iam : {
          role    = lookup(local.ctx.custom_roles, role, role)
          members = members
          subnet  = "${lookup(local.ctx.locations, s.region, s.region)}/${s.name}"
        }
      ]
    ],
  ))
  subnet_iam_bindings = merge([
    for s in local._iam_subnets : {
      for key, data in s.iam_bindings :
      key => {
        role      = lookup(local.ctx.custom_roles, data.role, data.role)
        subnet    = "${lookup(local.ctx.locations, s.region, s.region)}/${s.name}"
        members   = data.members
        condition = data.condition
      }
    }
  ]...)
  # note: all additive bindings share a single namespace for the key.
  # In other words, if you have multiple additive bindings with the
  # same name, only one will be used
  subnet_iam_bindings_additive = merge([
    for s in local._iam_subnets : {
      for key, data in s.iam_bindings_additive :
      key => {
        role      = lookup(local.ctx.custom_roles, data.role, data.role)
        subnet    = "${lookup(local.ctx.locations, s.region, s.region)}/${s.name}"
        member    = data.member
        condition = data.condition
      }
    }
  ]...)
  subnets = merge(
    {
      for s in var.subnets :
      "${lookup(local.ctx.locations, s.region, s.region)}/${s.name}" => s
    },
    { for k, v in local._factory_subnets : k => v if v._is_regular }
  )
  subnets_proxy_only = merge(
    {
      for s in var.subnets_proxy_only :
      "${lookup(local.ctx.locations, s.region, s.region)}/${s.name}" => s
    },
    { for k, v in local._factory_subnets : k => v if v._is_proxy_only },
  )
  subnets_private_nat = merge(
    {
      for s in var.subnets_private_nat :
      "${lookup(local.ctx.locations, s.region, s.region)}/${s.name}" => s
    },
    # { for k, v in local._factory_subnets : k => v if v._is_proxy_only },
  )
  subnets_psc = merge(
    {
      for s in var.subnets_psc :
      "${lookup(local.ctx.locations, s.region, s.region)}/${s.name}" => s
    },
    { for k, v in local._factory_subnets : k => v if v._is_psc }
  )
}

resource "google_compute_subnetwork" "subnetwork" {
  provider = google-beta
  for_each = local.subnets
  project  = local.project_id
  network  = local.network.name
  name     = each.value.name
  region = lookup(
    local.ctx.locations, each.value.region, each.value.region
  )
  ip_cidr_range = (
    try(each.value.ipv6.ipv6_only, false)
    ? null
    : try(local.ctx.cidr_ranges[each.value.ip_cidr_range], each.value.ip_cidr_range)
  )
  allow_subnet_cidr_routes_overlap = each.value.allow_subnet_cidr_routes_overlap
  reserved_internal_range = (
    each.value.reserved_internal_range != null
    ? "networkconnectivity.googleapis.com/${try(local.internal_ranges_ids[each.value.reserved_internal_range], each.value.reserved_internal_range)}"
    : null
  )
  description = (
    # Set description to an empty string (eg "") to create subnet without a description.
    each.value.description == null
    ? "Terraform-managed."
    : each.value.description
  )
  private_ip_google_access = each.value.enable_private_access
  stack_type = (
    try(each.value.ipv6, null) != null
    ? (
      try(each.value.ipv6.ipv6_only, false)
      ? "IPV6_ONLY"
      : "IPV4_IPV6"
    )
    : null
  )
  ipv6_access_type = (
    try(each.value.ipv6, null) != null ? each.value.ipv6.access_type : null
  )
  private_ipv6_google_access       = try(each.value.ipv6.enable_private_access, null)
  ip_collection                    = each.value.ip_collection
  send_secondary_ip_range_if_empty = true

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ip_ranges == null ? {} : each.value.secondary_ip_ranges
    content {
      range_name = secondary_ip_range.key
      ip_cidr_range = try(
        local.ctx.cidr_ranges[secondary_ip_range.value.ip_cidr_range],
        secondary_ip_range.value.ip_cidr_range,
        local.ctx.cidr_ranges[secondary_ip_range.value],
        secondary_ip_range.value
      )
      reserved_internal_range = (
        try(secondary_ip_range.value.reserved_internal_range, null) != null
        ? "networkconnectivity.googleapis.com/${try(local.internal_ranges_ids[secondary_ip_range.value.reserved_internal_range], secondary_ip_range.value.reserved_internal_range)}"
        : null
      )
    }
  }
  dynamic "log_config" {
    for_each = each.value.flow_logs_config != null ? [""] : []
    content {
      aggregation_interval = each.value.flow_logs_config.aggregation_interval
      filter_expr          = each.value.flow_logs_config.filter_expression
      flow_sampling        = each.value.flow_logs_config.flow_sampling
      metadata             = each.value.flow_logs_config.metadata
      metadata_fields = (
        each.value.flow_logs_config.metadata == "CUSTOM_METADATA"
        ? each.value.flow_logs_config.metadata_fields
        : null
      )
    }
  }
}

resource "google_compute_subnetwork" "proxy_only" {
  for_each = local.subnets_proxy_only
  project  = local.project_id
  network  = local.network.name
  name     = each.value.name
  region = lookup(
    local.ctx.locations, each.value.region, each.value.region
  )
  ip_cidr_range = lookup(
    local.ctx.cidr_ranges, each.value.ip_cidr_range, each.value.ip_cidr_range
  )
  description = (
    # Set description to an empty string (eg "") to create subnet without a description.
    each.value.description == null
    ? "Terraform-managed proxy-only subnet for Regional HTTPS, Internal HTTPS or Cross-Regional HTTPS Internal LB."
    : each.value.description
  )
  purpose = each.value.global ? "GLOBAL_MANAGED_PROXY" : "REGIONAL_MANAGED_PROXY"
  role    = each.value.active ? "ACTIVE" : "BACKUP"
}

resource "google_compute_subnetwork" "private_nat" {
  for_each = local.subnets_private_nat
  project  = local.project_id
  network  = local.network.name
  name     = each.value.name
  region = lookup(
    local.ctx.locations, each.value.region, each.value.region
  )
  ip_cidr_range = lookup(
    local.ctx.cidr_ranges, each.value.ip_cidr_range, each.value.ip_cidr_range
  )
  description = (
    # Set description to an empty string (eg "") to create subnet without a description.
    each.value.description == null
    ? "Terraform-managed private NAT subnet."
    : each.value.description
  )
  purpose = "PRIVATE_NAT"
}

resource "google_compute_subnetwork" "psc" {
  for_each = local.subnets_psc
  project  = local.project_id
  network  = local.network.name
  name     = each.value.name
  region = lookup(
    local.ctx.locations, each.value.region, each.value.region
  )
  ip_cidr_range = lookup(
    local.ctx.cidr_ranges, each.value.ip_cidr_range, each.value.ip_cidr_range
  )
  description = (
    # Set description to an empty string (eg "") to create subnet without a description.
    each.value.description == null
    ? "Terraform-managed subnet for Private Service Connect (PSC NAT)."
    : each.value.description
  )
  purpose = "PRIVATE_SERVICE_CONNECT"
}


resource "google_compute_subnetwork_iam_binding" "authoritative" {
  for_each = {
    for binding in local.subnet_iam :
    "${binding.subnet}.${binding.role}" => binding
  }
  project    = local.project_id
  subnetwork = local.all_subnets[each.value.subnet].name
  region     = local.all_subnets[each.value.subnet].region
  role       = each.value.role
  members = [
    for m in each.value.members : lookup(local.ctx.iam_principals, m, m)
  ]
}

resource "google_compute_subnetwork_iam_binding" "bindings" {
  for_each   = local.subnet_iam_bindings
  project    = local.project_id
  subnetwork = local.all_subnets[each.value.subnet].name
  region     = local.all_subnets[each.value.subnet].region
  role       = each.value.role
  members = [
    for m in each.value.members : lookup(local.ctx.iam_principals, m, m)
  ]
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_compute_subnetwork_iam_member" "bindings" {
  for_each   = local.subnet_iam_bindings_additive
  project    = local.project_id
  subnetwork = local.all_subnets[each.value.subnet].name
  region     = local.all_subnets[each.value.subnet].region
  role       = each.value.role
  member = lookup(
    local.ctx.iam_principals, each.value.member, each.value.member
  )
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression = templatestring(
        each.value.condition.expression, var.context.condition_vars
      )
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_compute_network_attachment" "default" {
  provider    = google-beta
  for_each    = var.network_attachments
  project     = local.project_id
  region      = google_compute_subnetwork.subnetwork[each.value.subnet].region
  name        = each.key
  description = each.value.description
  connection_preference = (
    each.value.automatic_connection ? "ACCEPT_AUTOMATIC" : "ACCEPT_MANUAL"
  )
  subnetworks = [
    google_compute_subnetwork.subnetwork[each.value.subnet].self_link
  ]
  producer_accept_lists = each.value.producer_accept_lists
  producer_reject_lists = each.value.producer_reject_lists
}
