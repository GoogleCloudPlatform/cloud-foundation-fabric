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

# tfdoc:file:description Subnet resources.

locals {
  _factory_data = {
    for f in try(fileset(var.factories_config.subnets_folder, "**/*.yaml"), []) :
    trimsuffix(basename(f), ".yaml") => yamldecode(file("${var.factories_config.subnets_folder}/${f}"))
  }
  _factory_subnets = {
    for k, v in local._factory_data :
    "${v.region}/${try(v.name, k)}" => {
      active                = try(v.active, true)
      description           = try(v.description, null)
      enable_private_access = try(v.enable_private_access, true)
      flow_logs_config = can(v.flow_logs_config) ? {
        aggregation_interval = try(v.flow_logs_config.aggregation_interval, null)
        filter_expression    = try(v.flow_logs_config.filter_expression, null)
        flow_sampling        = try(v.flow_logs_config.flow_sampling, null)
        metadata             = try(v.flow_logs_config.metadata, null)
        metadata_fields      = try(v.flow_logs_config.metadata_fields, null)
      } : null
      global        = try(v.global, false)
      ip_cidr_range = v.ip_cidr_range
      ipv6 = !can(v.ipv6) ? null : {
        access_type = try(v.ipv6.access_type, "INTERNAL")
      }
      name                = try(v.name, k)
      region              = v.region
      secondary_ip_ranges = try(v.secondary_ip_ranges, null)
      iam                 = try(v.iam, {})
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

  all_subnets = merge(
    { for k, v in google_compute_subnetwork.subnetwork : k => v },
    { for k, v in google_compute_subnetwork.proxy_only : k => v },
    { for k, v in google_compute_subnetwork.psc : k => v }
  )
  subnet_iam = flatten(concat(
    [
      for s in concat(var.subnets, var.subnets_psc, var.subnets_proxy_only, values(local._factory_subnets)) : [
        for role, members in s.iam :
        {
          role    = role
          members = members
          subnet  = "${s.region}/${s.name}"
        }
      ]
    ],
  ))
  subnet_iam_bindings = merge([
    for s in concat(var.subnets, var.subnets_psc, var.subnets_proxy_only, values(local._factory_subnets)) : {
      for key, data in s.iam_bindings :
      key => {
        role      = data.role
        subnet    = "${s.region}/${s.name}"
        members   = data.members
        condition = data.condition
      }
    }
  ]...)
  # note: all additive bindings share a single namespace for the key.
  # In other words, if you have multiple additive bindings with the
  # same name, only one will be used
  subnet_iam_bindings_additive = merge([
    for s in concat(var.subnets, var.subnets_psc, var.subnets_proxy_only, values(local._factory_subnets)) : {
      for key, data in s.iam_bindings_additive :
      key => {
        role      = data.role
        subnet    = "${s.region}/${s.name}"
        member    = data.member
        condition = data.condition
      }
    }
  ]...)
  subnets = merge(
    { for s in var.subnets : "${s.region}/${s.name}" => s },
    { for k, v in local._factory_subnets : k => v if v._is_regular }
  )
  subnets_proxy_only = merge(
    { for s in var.subnets_proxy_only : "${s.region}/${s.name}" => s },
    { for k, v in local._factory_subnets : k => v if v._is_proxy_only },
  )
  subnets_psc = merge(
    { for s in var.subnets_psc : "${s.region}/${s.name}" => s },
    { for k, v in local._factory_subnets : k => v if v._is_psc }
  )
}

resource "google_compute_subnetwork" "subnetwork" {
  for_each      = local.subnets
  project       = var.project_id
  network       = local.network.name
  name          = each.value.name
  region        = each.value.region
  ip_cidr_range = each.value.ip_cidr_range
  description = (
    each.value.description == null
    ? "Terraform-managed."
    : each.value.description
  )
  private_ip_google_access = each.value.enable_private_access
  secondary_ip_range = each.value.secondary_ip_ranges == null ? [] : [
    for name, range in each.value.secondary_ip_ranges :
    { range_name = name, ip_cidr_range = range }
  ]
  stack_type = (
    try(each.value.ipv6, null) != null ? "IPV4_IPV6" : null
  )
  ipv6_access_type = (
    try(each.value.ipv6, null) != null ? each.value.ipv6.access_type : null
  )
  # private_ipv6_google_access = try(each.value.ipv6.enable_private_access, null)
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
  for_each      = local.subnets_proxy_only
  project       = var.project_id
  network       = local.network.name
  name          = each.value.name
  region        = each.value.region
  ip_cidr_range = each.value.ip_cidr_range
  description = coalesce(
    each.value.description,
    "Terraform-managed proxy-only subnet for Regional HTTPS, Internal HTTPS or Cross-Regional HTTPS Internal LB."
  )
  purpose = each.value.global ? "GLOBAL_MANAGED_PROXY" : "REGIONAL_MANAGED_PROXY"
  role    = each.value.active ? "ACTIVE" : "BACKUP"
}

resource "google_compute_subnetwork" "psc" {
  for_each      = local.subnets_psc
  project       = var.project_id
  network       = local.network.name
  name          = each.value.name
  region        = each.value.region
  ip_cidr_range = each.value.ip_cidr_range
  description = coalesce(
    each.value.description,
    "Terraform-managed subnet for Private Service Connect (PSC NAT)."
  )
  purpose = "PRIVATE_SERVICE_CONNECT"
}


resource "google_compute_subnetwork_iam_binding" "authoritative" {
  for_each = {
    for binding in local.subnet_iam :
    "${binding.subnet}.${binding.role}" => binding
  }
  project    = var.project_id
  subnetwork = local.all_subnets[each.value.subnet].name
  region     = local.all_subnets[each.value.subnet].region
  role       = each.value.role
  members    = each.value.members
}

resource "google_compute_subnetwork_iam_binding" "bindings" {
  for_each   = local.subnet_iam_bindings
  project    = var.project_id
  subnetwork = local.all_subnets[each.value.subnet].name
  region     = local.all_subnets[each.value.subnet].region
  role       = each.value.role
  members    = each.value.members
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}

resource "google_compute_subnetwork_iam_member" "bindings" {
  for_each   = local.subnet_iam_bindings_additive
  project    = var.project_id
  subnetwork = local.all_subnets[each.value.subnet].name
  region     = local.all_subnets[each.value.subnet].region
  role       = each.value.role
  member     = each.value.member
  dynamic "condition" {
    for_each = each.value.condition == null ? [] : [""]
    content {
      expression  = each.value.condition.expression
      title       = each.value.condition.title
      description = each.value.condition.description
    }
  }
}
