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
  _iam    = var.iam == null ? {} : var.iam
  _routes = var.routes == null ? {} : var.routes
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
  network = (
    var.vpc_create
    ? try(google_compute_network.network.0, null)
    : try(data.google_compute_network.network.0, null)
  )
  peer_network = (
    var.peering_config == null
    ? null
    : element(reverse(split("/", var.peering_config.peer_vpc_self_link)), 0)
  )
  psa_ranges = {
    for k, v in coalesce(var.psa_ranges, {}) : k => {
      address       = split("/", v)[0]
      name          = k
      prefix_length = split("/", v)[1]
    }
  }
  routes = {
    gateway    = { for k, v in local._routes : k => v if v.next_hop_type == "gateway" }
    ilb        = { for k, v in local._routes : k => v if v.next_hop_type == "ilb" }
    instance   = { for k, v in local._routes : k => v if v.next_hop_type == "instance" }
    ip         = { for k, v in local._routes : k => v if v.next_hop_type == "ip" }
    vpn_tunnel = { for k, v in local._routes : k => v if v.next_hop_type == "vpn_tunnel" }
  }
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
  subnets_l7ilb = {
    for subnet in var.subnets_l7ilb :
    "${subnet.region}/${subnet.name}" => subnet
  }
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
  provider   = google-beta
  count      = var.shared_vpc_host ? 1 : 0
  project    = var.project_id
  depends_on = [local.network]
}

resource "google_compute_shared_vpc_service_project" "service_projects" {
  provider = google-beta
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

resource "google_compute_subnetwork" "l7ilb" {
  provider      = google-beta
  for_each      = local.subnets_l7ilb
  project       = var.project_id
  network       = local.network.name
  region        = each.value.region
  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
  role = (
    each.value.active || each.value.active == null ? "ACTIVE" : "BACKUP"
  )
  description = lookup(
    local.subnet_descriptions,
    "${each.value.region}/${each.value.name}",
    "Terraform-managed."
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

resource "google_compute_route" "gateway" {
  for_each         = local.routes.gateway
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
  for_each     = local.routes.ilb
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
  for_each          = local.routes.instance
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
  for_each    = local.routes.ip
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
  for_each            = local.routes.vpn_tunnel
  project             = var.project_id
  network             = local.network.name
  name                = "${var.name}-${each.key}"
  description         = "Terraform-managed."
  dest_range          = each.value.dest_range
  priority            = each.value.priority
  tags                = each.value.tags
  next_hop_vpn_tunnel = each.value.next_hop
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
    for_each = toset(var.dns_policy.outbound == null ? [] : [""])
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

resource "google_compute_global_address" "psa_ranges" {
  for_each      = local.psa_ranges
  project       = var.project_id
  name          = "${var.name}-psa-${each.key}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = each.value.address
  prefix_length = each.value.prefix_length
  network       = local.network.id
}

resource "google_service_networking_connection" "psa_connection" {
  for_each = toset(local.psa_ranges == {} ? [] : [""])
  network  = local.network.id
  service  = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    for k, v in google_compute_global_address.psa_ranges : v.name
  ]
}
