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
  _factory_data = var.data_folder == null ? tomap({}) : {
    for f in fileset(var.data_folder, "**/*.yaml") :
    trimsuffix(basename(f), ".yaml") => yamldecode(file("${var.data_folder}/${f}"))
  }
  _factory_descriptions = {
    for k, v in local._factory_data :
    "${v.region}/${k}" => try(v.description, null)
  }
  _factory_iam_members = [
    for k, v in local._factory_subnets : {
      subnet = k
      role   = "roles/compute.networkUser"
      members = concat(
        formatlist("group:%s", try(v.iam_groups, [])),
        formatlist("user:%s", try(v.iam_users, [])),
        formatlist("serviceAccount:%s", try(v.iam_service_accounts, []))
      )
    }
  ]
  _factory_flow_logs = {
    for k, v in local._factory_data : "${v.region}/${k}" => merge(
      var.log_config_defaults, try(v.flow_logs, {})
    ) if try(v.flow_logs, false)
  }
  _factory_private_access = {
    for k, v in local._factory_data : "${v.region}/${k}" => try(
      v.private_ip_google_access, true
    )
  }
  _factory_subnets = {
    for k, v in local._factory_data : "${v.region}/${k}" => {
      ip_cidr_range      = v.ip_cidr_range
      name               = k
      region             = v.region
      secondary_ip_range = try(v.secondary_ip_range, {})
    }
  }
  _iam = var.iam == null ? {} : var.iam
  _subnet_flow_logs = {
    for k, v in var.subnet_flow_logs : k => merge(
      var.log_config_defaults, try(var.log_configs[k], {})
    )
  }
  _subnet_iam_members = flatten([
    for subnet, roles in local._iam : [
      for role, members in roles : {
        members = members
        role    = role
        subnet  = subnet
      }
    ]
  ])
  subnet_descriptions = merge(
    local._factory_descriptions, var.subnet_descriptions
  )
  subnet_iam_members = concat(
    local._factory_iam_members, local._subnet_iam_members
  )
  subnet_flow_logs = merge(
    local._factory_flow_logs, local._subnet_flow_logs
  )
  subnet_private_access = merge(
    local._factory_private_access, var.subnet_private_access
  )
  subnets = merge(
    { for subnet in var.subnets : "${subnet.region}/${subnet.name}" => subnet },
    local._factory_subnets
  )
  subnets_proxy_only = {
    for subnet in var.subnets_proxy_only :
    "${subnet.region}/${subnet.name}" => subnet
  }
  subnets_psc = {
    for subnet in var.subnets_psc :
    "${subnet.region}/${subnet.name}" => subnet
  }
}

resource "google_compute_subnetwork" "subnetwork" {
  for_each      = local.subnets
  project       = var.project_id
  network       = local.network.name
  region        = each.value.region
  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  secondary_ip_range = each.value.secondary_ip_range == null ? [] : [
    for name, range in each.value.secondary_ip_range :
    { range_name = name, ip_cidr_range = range }
  ]
  description = lookup(
    local.subnet_descriptions, each.key, "Terraform-managed."
  )
  private_ip_google_access = lookup(
    local.subnet_private_access, each.key, true
  )
  dynamic "log_config" {
    for_each = toset(
      try(local.subnet_flow_logs[each.key], {}) != {}
      ? [local.subnet_flow_logs[each.key]]
      : []
    )
    iterator = config
    content {
      aggregation_interval = config.value.aggregation_interval
      flow_sampling        = config.value.flow_sampling
      metadata             = config.value.metadata
    }
  }
}

resource "google_compute_subnetwork" "proxy_only" {
  for_each      = local.subnets_proxy_only
  project       = var.project_id
  network       = local.network.name
  region        = each.value.region
  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  purpose       = "REGIONAL_MANAGED_PROXY"
  role = (
    each.value.active || each.value.active == null ? "ACTIVE" : "BACKUP"
  )
  description = lookup(
    local.subnet_descriptions,
    "${each.value.region}/${each.value.name}",
    "Terraform-managed proxy-only subnet for Regional HTTPS or Internal HTTPS LB."
  )
}

resource "google_compute_subnetwork" "psc" {
  for_each      = local.subnets_psc
  project       = var.project_id
  network       = local.network.name
  region        = each.value.region
  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  purpose       = "PRIVATE_SERVICE_CONNECT"
  description = lookup(
    local.subnet_descriptions,
    "${each.value.region}/${each.value.name}",
    "Terraform-managed subnet for Private Service Connect (PSC NAT)."
  )
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
