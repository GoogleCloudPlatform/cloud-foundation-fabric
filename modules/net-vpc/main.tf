/**
 * Copyright 2021 Google LLC
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
  iam_members = var.iam == null ? {} : var.iam
  subnet_iam_members = flatten([
    for subnet, roles in local.iam_members : [
      for role, members in roles : {
        subnet  = subnet
        role    = role
        members = members
      }
    ]
  ])

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
    for name, attrs in { for s in local.subnets : format("%s/%s", s.region, s.name) => s } : name => (
      lookup(var.subnet_flow_logs, name, false)
      ? [{
        for key, value in var.log_config_defaults : key => lookup(
          lookup(local.log_configs, name, {}), key, value
        )
      }]
      : []
    )
  }
  subnets = {
    for subnet in var.subnets :
    "${subnet.region}/${subnet.name}" => subnet
  }
  network = (
    var.vpc_create
    ? try(google_compute_network.network.0, null)
    : try(data.google_compute_network.network.0, null)
  )
}

data "google_compute_network" "network" {
  count   = var.vpc_create ? 0 : 1
  project = var.project_id
  name    = var.name
}

resource "google_compute_network" "network" {
  count                           = var.vpc_create ? 1 : 0
  project                         = var.project_id
  name                            = var.name
  description                     = var.description
  auto_create_subnetworks         = var.auto_create_subnetworks
  delete_default_routes_on_create = var.delete_default_routes_on_create
  mtu                             = var.mtu
  routing_mode                    = var.routing_mode
}

resource "google_compute_network_peering" "local" {
  provider             = google-beta
  count                = var.peering_config == null ? 0 : 1
  name                 = "${var.name}-${local.peer_network}"
  network              = local.network.self_link
  peer_network         = var.peering_config.peer_vpc_self_link
  export_custom_routes = var.peering_config.export_routes
  import_custom_routes = var.peering_config.import_routes
}

resource "google_compute_network_peering" "remote" {
  provider             = google-beta
  count                = var.peering_config != null && var.peering_create_remote_end ? 1 : 0
  name                 = "${local.peer_network}-${var.name}"
  network              = var.peering_config.peer_vpc_self_link
  peer_network         = local.network.self_link
  export_custom_routes = var.peering_config.import_routes
  import_custom_routes = var.peering_config.export_routes
  depends_on           = [google_compute_network_peering.local]
}

resource "google_compute_shared_vpc_host_project" "shared_vpc_host" {
  count      = var.shared_vpc_host ? 1 : 0
  project    = var.project_id
  depends_on = [local.network]
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
  network       = local.network.name
  region        = each.value.region
  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  secondary_ip_range = each.value.secondary_ip_range == null ? [] : [
    for name, range in each.value.secondary_ip_range :
    { range_name = name, ip_cidr_range = range }
  ]
  description              = lookup(var.subnet_descriptions, "${each.value.region}/${each.value.name}", "Terraform-managed.")
  private_ip_google_access = lookup(var.subnet_private_access, "${each.value.region}/${each.value.name}", true)
  dynamic "log_config" {
    for_each = local.subnet_log_configs["${each.value.region}/${each.value.name}"]
    iterator = config
    content {
      aggregation_interval = config.value.aggregation_interval
      flow_sampling        = config.value.flow_sampling
      metadata             = config.value.metadata
    }
  }
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

resource "google_compute_route" "gateway" {
  for_each         = local.routes_gateway
  project          = var.project_id
  network          = local.network.name
  name             = "${var.name}-${each.key}"
  description      = "Terraform-managed."
  dest_range       = each.value.dest_range
  priority         = each.value.priority
  tags             = each.value.tags
  next_hop_gateway = each.value.next_hop
}

resource "google_compute_route" "ilb" {
  for_each     = local.routes_ilb
  project      = var.project_id
  network      = local.network.name
  name         = "${var.name}-${each.key}"
  description  = "Terraform-managed."
  dest_range   = each.value.dest_range
  priority     = each.value.priority
  tags         = each.value.tags
  next_hop_ilb = each.value.next_hop
}

resource "google_compute_route" "instance" {
  for_each          = local.routes_instance
  project           = var.project_id
  network           = local.network.name
  name              = "${var.name}-${each.key}"
  description       = "Terraform-managed."
  dest_range        = each.value.dest_range
  priority          = each.value.priority
  tags              = each.value.tags
  next_hop_instance = each.value.next_hop
  # not setting the instance zone will trigger a refresh
  next_hop_instance_zone = regex("zones/([^/]+)/", each.value.next_hop)[0]
}

resource "google_compute_route" "ip" {
  for_each    = local.routes_ip
  project     = var.project_id
  network     = local.network.name
  name        = "${var.name}-${each.key}"
  description = "Terraform-managed."
  dest_range  = each.value.dest_range
  priority    = each.value.priority
  tags        = each.value.tags
  next_hop_ip = each.value.next_hop
}

resource "google_compute_route" "vpn_tunnel" {
  for_each            = local.routes_vpn_tunnel
  project             = var.project_id
  network             = local.network.name
  name                = "${var.name}-${each.key}"
  description         = "Terraform-managed."
  dest_range          = each.value.dest_range
  priority            = each.value.priority
  tags                = each.value.tags
  next_hop_vpn_tunnel = each.value.next_hop
}

resource "google_compute_global_address" "psn_range" {
  count         = var.private_service_networking_range == null ? 0 : 1
  project       = var.project_id
  name          = "${var.name}-google-psn"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = split("/", var.private_service_networking_range)[0]
  prefix_length = split("/", var.private_service_networking_range)[1]
  network       = local.network.id
}

resource "google_dns_policy" "default" {
  count                     = var.dns_policy == null ? 0 : 1
  enable_inbound_forwarding = var.dns_policy.inbound
  enable_logging            = var.dns_policy.logging
  name                      = var.name
  project                   = var.project_id
  networks {
    network_url = local.network.id
  }

  dynamic "alternative_name_server_config" {
    for_each = var.dns_policy.outbound == null ? [] : [1]
    content {
      dynamic "target_name_servers" {
        for_each = toset(var.dns_policy.outbound.private_ns)
        iterator = ns
        content {
          ipv4_address    = ns.key
          forwarding_path = "private"
        }
      }
      dynamic "target_name_servers" {
        for_each = toset(var.dns_policy.outbound.public_ns)
        iterator = ns
        content {
          ipv4_address = ns.key
        }
      }
    }
  }
}

resource "google_service_networking_connection" "psn_connection" {
  count                   = var.private_service_networking_range == null ? 0 : 1
  network                 = local.network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psn_range.0.name]
}
