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

# tfdoc:file:description Subnet resources.

locals {
  _factory_data = {
    for f in try(fileset(var.data_folder, "**/*.yaml"), []) :
    trimsuffix(basename(f), ".yaml") => yamldecode(file("${var.data_folder}/${f}"))
  }
  _factory_subnets = {
    for k, v in local._factory_data : "${v.region}/${try(v.name, k)}" => {
      name                  = try(v.name, k)
      ip_cidr_range         = v.ip_cidr_range
      region                = v.region
      description           = try(v.description, null)
      enable_private_access = try(v.enable_private_access, true)
      flow_logs_config      = try(v.flow_logs, null)
      ipv6                  = try(v.ipv6, null)
      secondary_ip_ranges   = try(v.secondary_ip_ranges, null)
      iam                   = try(v.iam, [])
      iam_additive          = try(v.iam_additive, [])
      purpose               = try(v.purpose, null)
      active                = try(v.active, null)
    }
  }
  _factory_subnets_iam_additive = flatten([
    for k, v in local._factory_subnets : [
      for member in lookup(v, "iam_additive", []) : {
        member = member
        subnet = k
        role   = "roles/compute.networkUser"
      }
    ] if v.purpose == null
  ])
  _factory_subnets_iam = [
    for k, v in local._factory_subnets : {
      subnet  = k
      role    = "roles/compute.networkUser"
      members = v.iam
    } if v.purpose == null && v.iam != null
  ]
  _subnet_iam_additive_members = flatten([
    for subnet, roles in var.subnet_iam_additive : [
      for role, members in roles : [
        for member in members : {
          member = member
          role   = role
          subnet = subnet
        }
      ]
    ]
  ])
  _subnet_iam_members = flatten([
    for subnet, roles in(var.subnet_iam == null ? {} : var.subnet_iam) : [
      for role, members in roles : {
        members = members
        role    = role
        subnet  = subnet
      }
    ]
  ])
  subnet_iam_additive_members = concat(
    local._factory_subnets_iam_additive,
    local._subnet_iam_additive_members
  )
  subnet_iam_members = concat(
    [for k in local._factory_subnets_iam : k if length(k.members) > 0],
    local._subnet_iam_members
  )
  subnets = merge(
    { for s in var.subnets : "${s.region}/${s.name}" => s },
    { for k, v in local._factory_subnets : k => v if v.purpose == null }
  )
  subnets_proxy_only = merge(
    { for s in var.subnets_proxy_only : "${s.region}/${s.name}" => s },
    { for k, v in local._factory_subnets : k => v if v.purpose == "REGIONAL_MANAGED_PROXY" }
  )
  subnets_psc = merge(
    { for s in var.subnets_psc : "${s.region}/${s.name}" => s },
    { for k, v in local._factory_subnets : k => v if v.purpose == "PRIVATE_SERVICE_CONNECT" }
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
  description = (
    each.value.description == null
    ? "Terraform-managed proxy-only subnet for Regional HTTPS or Internal HTTPS LB."
    : each.value.description
  )
  purpose = "REGIONAL_MANAGED_PROXY"
  role    = each.value.active != false ? "ACTIVE" : "BACKUP"
}

resource "google_compute_subnetwork" "psc" {
  for_each      = local.subnets_psc
  project       = var.project_id
  network       = local.network.name
  name          = each.value.name
  region        = each.value.region
  ip_cidr_range = each.value.ip_cidr_range
  description = (
    each.value.description == null
    ? "Terraform-managed subnet for Private Service Connect (PSC NAT)."
    : each.value.description
  )
  purpose = "PRIVATE_SERVICE_CONNECT"
}

resource "google_compute_subnetwork_iam_binding" "binding" {
  for_each = {
    for binding in local.subnet_iam_members :
    "${binding.subnet}.${binding.role}" => binding
  }
  project    = var.project_id
  subnetwork = google_compute_subnetwork.subnetwork[each.value.subnet].name
  region     = google_compute_subnetwork.subnetwork[each.value.subnet].region
  role       = each.value.role
  members    = each.value.members
}

resource "google_compute_subnetwork_iam_member" "binding" {
  for_each = {
    for binding in local.subnet_iam_additive_members :
    "${binding.subnet}.${binding.role}.${binding.member}" => binding
  }
  project    = var.project_id
  subnetwork = google_compute_subnetwork.subnetwork[each.value.subnet].name
  region     = google_compute_subnetwork.subnetwork[each.value.subnet].region
  role       = each.value.role
  member     = each.value.member
}
