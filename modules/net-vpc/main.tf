/**
 * Copyright 2019 Google LLC
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
  log_configs = {
    for name, attrs in var.subnets : name => (
      lookup(var.subnet_flow_logs, name, false)
      ? [{
        for key, value in var.log_config_defaults : key => lookup(
          lookup(var.log_configs, name, {}), key, value
        )
      }]
      : []
    )
  }
  # distinct is needed to make the expanding function argument work
  iam_pairs = concat([], distinct([
    for subnet, roles in var.iam_roles :
    [for role in roles : { subnet = subnet, role = role }]
  ])...)
  iam_keypairs = {
    for pair in local.iam_pairs :
    "${pair.subnet}-${pair.role}" => pair
  }
}

resource "google_compute_network" "network" {
  project                 = var.project_id
  name                    = var.name
  description             = var.description
  auto_create_subnetworks = var.auto_create_subnetworks
  routing_mode            = var.routing_mode
}

resource "google_compute_shared_vpc_host_project" "shared_vpc_host" {
  count      = var.shared_vpc_host ? 1 : 0
  project    = var.project_id
  depends_on = [google_compute_network.network]
}

resource "google_compute_shared_vpc_service_project" "service_projects" {
  for_each        = var.shared_vpc_host ? toset(var.shared_vpc_service_projects) : toset([])
  host_project    = var.project_id
  service_project = each.value
  depends_on      = [google_compute_shared_vpc_host_project.shared_vpc_host]
}

resource "google_compute_subnetwork" "subnetwork" {
  for_each      = var.subnets
  project       = var.project_id
  network       = google_compute_network.network.name
  region        = each.value.region
  name          = each.key
  ip_cidr_range = each.value.ip_cidr_range
  secondary_ip_range = [
    for name, range in each.value.secondary_ip_range :
    { range_name = name, ip_cidr_range = range }
  ]
  description              = lookup(var.subnet_descriptions, each.key, "Terraform-managed.")
  private_ip_google_access = lookup(var.subnet_private_access, each.key, true)
  dynamic "log_config" {
    for_each = local.log_configs[each.key]
    content {
      aggregation_interval = log_config.value.aggregation_interval
      flow_sampling        = log_config.value.flow_sampling
      metadata             = log_config.value.metadata
    }
  }
}

resource "google_compute_subnetwork_iam_binding" "binding" {
  for_each   = local.iam_keypairs
  project    = var.project_id
  subnetwork = google_compute_subnetwork.subnetwork[each.value.subnet].name
  region     = google_compute_subnetwork.subnetwork[each.value.subnet].region
  role       = each.value.role
  members = lookup(
    lookup(var.iam_members, each.value.subnet, {}), each.value.role, []
  )
}
