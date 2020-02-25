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
  iam_members = var.iam_members == null ? {} : var.iam_members
  iam_pairs = var.iam_roles == null ? [] : flatten([
    for subnet, roles in var.iam_roles :
    [for role in roles : { subnet = subnet, role = role }]
  ])
  iam_keypairs = {
    for pair in local.iam_pairs :
    "${pair.subnet}-${pair.role}" => pair
  }
  log_configs = var.log_configs == null ? {} : var.log_configs
  peer_network = (
    var.peering_config == null
    ? null
    : element(reverse(split("/", var.peering_config.peer_vpc_self_link)), 0)
  )
  routes = var.routes == null ? {} : var.routes
  routes_gateway = {
    for name, data in local.routes :
    name => data if data.next_hop_type == "gateway"
  }
  routes_ilb = {
    for name, data in local.routes :
    name => data if data.next_hop_type == "ilb"
  }
  routes_instance = {
    for name, data in local.routes :
    name => data if data.next_hop_type == "instance"
  }
  routes_ip = {
    for name, data in local.routes :
    name => data if data.next_hop_type == "ip"
  }
  routes_vpn_tunnel = {
    for name, data in local.routes :
    name => data if data.next_hop_type == "vpn_tunnel"
  }
  subnet_log_configs = {
    for name, attrs in local.subnets : name => (
      lookup(var.subnet_flow_logs, name, false)
      ? [{
        for key, value in var.log_config_defaults : key => lookup(
          lookup(local.log_configs, name, {}), key, value
        )
      }]
      : []
    )
  }
  subnets = var.subnets == null ? {} : var.subnets
}

resource "google_compute_network" "network" {
  project                 = var.project_id
  name                    = var.name
  description             = var.description
  auto_create_subnetworks = var.auto_create_subnetworks
  routing_mode            = var.routing_mode
}

resource "google_compute_network_peering" "local" {
  provider             = google-beta
  count                = var.peering_config == null ? 0 : 1
  name                 = "${google_compute_network.network.name}-${local.peer_network}"
  network              = google_compute_network.network.self_link
  peer_network         = var.peering_config.peer_vpc_self_link
  export_custom_routes = var.peering_config.export_routes
  import_custom_routes = var.peering_config.import_routes
}

resource "google_compute_network_peering" "remote" {
  provider             = google-beta
  count                = var.peering_config == null ? 0 : 1
  name                 = "${local.peer_network}-${google_compute_network.network.name}"
  network              = var.peering_config.peer_vpc_self_link
  peer_network         = google_compute_network.network.self_link
  export_custom_routes = var.peering_config.import_routes
  import_custom_routes = var.peering_config.export_routes
  depends_on           = [google_compute_network_peering.local]
}

resource "google_compute_shared_vpc_host_project" "shared_vpc_host" {
  count      = var.shared_vpc_host ? 1 : 0
  project    = var.project_id
  depends_on = [google_compute_network.network]
}

resource "google_compute_shared_vpc_service_project" "service_projects" {
  for_each = (
    var.shared_vpc_host && var.shared_vpc_service_projects != null
    ? toset(var.shared_vpc_service_projects)
    : toset([])
  )
  host_project    = var.project_id
  service_project = each.value
  depends_on      = [google_compute_shared_vpc_host_project.shared_vpc_host]
}

resource "google_compute_subnetwork" "subnetwork" {
  for_each      = local.subnets
  project       = var.project_id
  network       = google_compute_network.network.name
  region        = each.value.region
  name          = "${var.name}-${each.key}"
  ip_cidr_range = each.value.ip_cidr_range
  secondary_ip_range = each.value.secondary_ip_range == null ? [] : [
    for name, range in each.value.secondary_ip_range :
    { range_name = name, ip_cidr_range = range }
  ]
  description              = lookup(var.subnet_descriptions, each.key, "Terraform-managed.")
  private_ip_google_access = lookup(var.subnet_private_access, each.key, true)
  dynamic "log_config" {
    for_each = local.subnet_log_configs[each.key]
    iterator = config
    content {
      aggregation_interval = config.value.aggregation_interval
      flow_sampling        = config.value.flow_sampling
      metadata             = config.value.metadata
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
    lookup(local.iam_members, each.value.subnet, {}), each.value.role, []
  )
}

resource "google_compute_route" "gateway" {
  for_each         = local.routes_gateway
  project          = var.project_id
  network          = google_compute_network.network.name
  name             = each.key
  description      = "Terraform-managed."
  dest_range       = each.value.dest_range
  priority         = each.value.priority
  tags             = each.value.tags
  next_hop_gateway = each.value.next_hop
}

resource "google_compute_route" "ilb" {
  for_each     = local.routes_ilb
  project      = var.project_id
  network      = google_compute_network.network.name
  name         = each.key
  description  = "Terraform-managed."
  dest_range   = each.value.dest_range
  priority     = each.value.priority
  tags         = each.value.tags
  next_hop_ilb = each.value.next_hop
}

resource "google_compute_route" "instance" {
  for_each          = local.routes_instance
  project           = var.project_id
  network           = google_compute_network.network.name
  name              = each.key
  description       = "Terraform-managed."
  dest_range        = each.value.dest_range
  priority          = each.value.priority
  tags              = each.value.tags
  next_hop_instance = each.value.next_hop
}

resource "google_compute_route" "ip" {
  for_each    = local.routes_ip
  project     = var.project_id
  network     = google_compute_network.network.name
  name        = each.key
  description = "Terraform-managed."
  dest_range  = each.value.dest_range
  priority    = each.value.priority
  tags        = each.value.tags
  next_hop_ip = each.value.next_hop
}

resource "google_compute_route" "vpn_tunnel" {
  for_each            = local.routes_vpn_tunnel
  project             = var.project_id
  network             = google_compute_network.network.name
  name                = each.key
  description         = "Terraform-managed."
  dest_range          = each.value.dest_range
  priority            = each.value.priority
  tags                = each.value.tags
  next_hop_vpn_tunnel = each.value.next_hop
}
