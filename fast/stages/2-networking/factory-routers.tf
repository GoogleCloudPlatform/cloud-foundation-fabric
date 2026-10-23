/**
 * Copyright 2026 Google LLC
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

# tfdoc:file:description Routers factory.

locals {
  ctx_routers = {
    ids   = { for k, v in google_compute_router.default : k => v.id }
    names = { for k, v in google_compute_router.default : k => v.name }
  }
  router_configs = merge(flatten([
    for vpc_key, vpc_config in local.vpcs : [
      for router_key, router_config in try(vpc_config.routers, {}) : {
        "${vpc_key}/${router_key}" = merge(router_config, {
          name              = replace("${vpc_key}/${router_key}", "/", "-")
          vpc_self_link     = vpc_key
          project_id        = vpc_config.project_id
          custom_advertise  = try(router_config.custom_advertise, {})
          advertise_mode    = try(router_config.custom_advertise != null, false) ? "CUSTOM" : "DEFAULT"
          advertised_groups = try(router_config.custom_advertise.all_subnets, false) ? ["ALL_SUBNETS"] : []
          keepalive         = try(router_config.keepalive, null)
          asn               = try(router_config.asn, null)
          route_policies    = try(router_config.route_policies, {})
        })
      }
    ]
  ])...)

  router_route_policies = merge(flatten([
    for router_key, router_config in local.router_configs : [
      for policy_key, policy_config in router_config.route_policies : {
        "${router_key}/${policy_key}" = merge(policy_config, {
          name       = policy_key
          router_key = router_key
        })
      }
    ]
  ])...)
  # Router interfaces are split in two maps so that redundant interfaces can
  # reference their primary without a self-referencing for_each. Interface
  # addresses are literal so that NVA guest BGP configuration can be rendered
  # without depending on router resources.
  _router_interfaces = merge(flatten([
    for router_key, router_config in local.router_configs : [
      for if_key, if_config in try(router_config.interfaces, {}) : {
        "${router_key}/${if_key}" = {
          name                = if_key
          router_key          = router_key
          subnet              = if_config.subnet
          ip_address          = if_config.ip_address
          redundant_interface = try(if_config.redundant_interface, null)
        }
      }
    ]
  ])...)
  router_interfaces_primary = {
    for k, v in local._router_interfaces : k => v
    if v.redundant_interface == null
  }
  router_interfaces_redundant = {
    for k, v in local._router_interfaces : k => v
    if v.redundant_interface != null
  }
  # BGP peers use the same attributes as the VPN and VLAN attachment peers;
  # a peer is either explicit (address, optionally a router appliance instance
  # via the $nva_instances: token) or fanned out via the `nva` attribute across
  # all instances of the NVA router appliance spoke in the router's VPC
  _router_peers = merge(flatten([
    for router_key, router_config in local.router_configs : [
      for peer_key, peer_config in try(router_config.peers, {}) : (
        try(peer_config.nva, null) == null
        ? {
          "${router_key}/${peer_key}" = merge(peer_config, {
            router_key = router_key
            name       = peer_key
            nva_key    = null
            address = lookup(
              local.ctx_nva_instances.addresses,
              trimprefix(try(peer_config.address, ""), "$nva_addresses:"),
              try(peer_config.address, null)
            )
            router_appliance_instance = lookup(
              local.ctx_nva_instances.self_links,
              trimprefix(
                try(peer_config.router_appliance_instance, ""), "$nva_instances:"
              ),
              try(peer_config.router_appliance_instance, null)
            )
          })
        }
        : {
          for inst in lookup(
            local.nva_ra_spokes,
            "${router_config.vpc_self_link}/${peer_config.nva}",
            { instances = [] }
          ).instances :
          "${router_key}/${peer_key}/${inst.key}" => merge(peer_config, {
            router_key                = router_key
            name                      = "${peer_key}-${inst.key}"
            nva_key                   = peer_config.nva
            address                   = inst.ip
            router_appliance_instance = inst.vm
          })
        }
      )
    ]
  ])...)
  router_peers = {
    for k, v in local._router_peers : k => merge(v, {
      advertise_mode = (
        try(v.custom_advertise, null) != null ? "CUSTOM" : "DEFAULT"
      )
      advertised_groups = (
        try(v.custom_advertise.all_subnets, false) ? ["ALL_SUBNETS"] : []
      )
      advertised_ip_ranges = try(v.custom_advertise.ip_ranges, {})
      custom_learned_priority = try(
        v.custom_learned_ip_ranges.route_priority, null
      )
      custom_learned_ranges = try(
        keys(v.custom_learned_ip_ranges.ip_ranges), []
      )
      enable                 = try(v.enable, true)
      export_policies        = try(v.export_policies, [])
      import_policies        = try(v.import_policies, [])
      md5_authentication_key = try(v.md5_authentication_key, null)
      route_priority         = try(v.route_priority, null)
    })
  }
}

resource "google_compute_router" "default" {
  for_each = local.router_configs
  name     = replace(each.key, "/", "-")
  lifecycle {
    precondition {
      condition = alltrue([
        for k, v in try(each.value.peers, {}) :
        try(v.nva, null) != null || try(v.address, null) != null
      ])
      error_message = "Router ${each.key}: peers need either `nva` or `address`."
    }
    precondition {
      condition = alltrue([
        for k, v in try(each.value.peers, {}) :
        contains(
          keys(local.nva_ra_spokes),
          "${each.value.vpc_self_link}/${try(v.nva, "")}"
        ) if try(v.nva, null) != null
      ])
      error_message = "Router ${each.key}: a peer references an NVA without a router appliance spoke in VPC ${each.value.vpc_self_link}."
    }
    precondition {
      condition = alltrue([
        for k, v in try(each.value.peers, {}) :
        contains(keys(try(each.value.interfaces, {})), v.interface)
      ])
      error_message = "Router ${each.key}: a peer references an interface that is not defined."
    }
  }
  project = lookup(
    local.ctx_projects.project_ids,
    replace(each.value.project_id, "$project_ids:", ""),
    each.value.project_id
  )
  region = lookup(
    local.ctx.locations,
    replace(each.value.region, "$locations:", ""),
    each.value.region
  )
  network = lookup(
    local.ctx_vpcs.self_links,
    each.value.vpc_self_link,
    each.value.vpc_self_link
  )
  bgp {
    advertise_mode    = each.value.advertise_mode
    advertised_groups = each.value.advertised_groups
    dynamic "advertised_ip_ranges" {
      for_each = try(each.value.custom_advertise.ip_ranges, {})
      iterator = range
      content {
        range       = range.key
        description = range.value
      }
    }
    keepalive_interval = each.value.keepalive
    asn                = each.value.asn
  }
}

resource "google_compute_router_route_policy" "default" {
  for_each = local.router_route_policies
  project  = google_compute_router.default[each.value.router_key].project
  region   = google_compute_router.default[each.value.router_key].region
  router   = google_compute_router.default[each.value.router_key].name
  name     = each.value.name
  type     = each.value.type == "IMPORT" ? "ROUTE_POLICY_TYPE_IMPORT" : each.value.type == "EXPORT" ? "ROUTE_POLICY_TYPE_EXPORT" : null

  dynamic "terms" {
    for_each = each.value.terms
    content {
      priority = terms.value.priority
      match {
        expression  = terms.value.match.expression
        title       = try(terms.value.match.title, null)
        description = try(terms.value.match.description, null)
        location    = try(terms.value.match.location, null)
      }
      dynamic "actions" {
        for_each = terms.value.actions
        content {
          expression  = actions.value.expression
          title       = try(actions.value.title, null)
          description = try(actions.value.description, null)
          location    = try(actions.value.location, null)
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = contains(["IMPORT", "EXPORT"], each.value.type)
      error_message = "Route policy type must be either 'IMPORT' or 'EXPORT'."
    }
    precondition {
      condition     = length(each.value.terms) == length(distinct([for t in each.value.terms : t.priority]))
      error_message = "Route policy term priorities must be unique."
    }
    precondition {
      condition     = alltrue([for t in each.value.terms : t.priority >= 0 && t.priority < 2147483648])
      error_message = "Route policy term priority must be between 0 (inclusive) and 2147483648 (exclusive)."
    }
  }
}

resource "google_compute_router_interface" "primary" {
  for_each = local.router_interfaces_primary
  project  = google_compute_router.default[each.value.router_key].project
  region   = google_compute_router.default[each.value.router_key].region
  router   = google_compute_router.default[each.value.router_key].name
  name     = each.value.name
  subnetwork = lookup(
    local.ctx_vpcs.subnets_by_vpc,
    replace(each.value.subnet, "$subnets:", ""),
    each.value.subnet
  )
  private_ip_address = each.value.ip_address
  depends_on         = [google_compute_router_route_policy.default]
}

resource "google_compute_router_interface" "redundant" {
  for_each = local.router_interfaces_redundant
  project  = google_compute_router.default[each.value.router_key].project
  region   = google_compute_router.default[each.value.router_key].region
  router   = google_compute_router.default[each.value.router_key].name
  name     = each.value.name
  subnetwork = lookup(
    local.ctx_vpcs.subnets_by_vpc,
    replace(each.value.subnet, "$subnets:", ""),
    each.value.subnet
  )
  private_ip_address = each.value.ip_address
  redundant_interface = google_compute_router_interface.primary[
    "${each.value.router_key}/${each.value.redundant_interface}"
  ].name
  lifecycle {
    precondition {
      condition = contains(
        keys(local.router_interfaces_primary),
        "${each.value.router_key}/${each.value.redundant_interface}"
      )
      error_message = "Interface ${each.key}: redundant_interface ${each.value.redundant_interface} is not a primary interface of the same router."
    }
  }
  depends_on = [google_compute_router_route_policy.default]
}

# instances cannot be deleted while a BGP peer references them, so a change
# of the appliance instance replaces the peer (destroyed before the instance)
resource "terraform_data" "router_peer_instances" {
  for_each = local.router_peers
  input    = each.value.router_appliance_instance
}

resource "google_compute_router_peer" "default" {
  for_each = local.router_peers
  project  = google_compute_router.default[each.value.router_key].project
  region   = google_compute_router.default[each.value.router_key].region
  router   = google_compute_router.default[each.value.router_key].name
  name     = each.value.name
  interface = try(
    google_compute_router_interface.primary[
      "${each.value.router_key}/${each.value.interface}"
    ].name,
    google_compute_router_interface.redundant[
      "${each.value.router_key}/${each.value.interface}"
    ].name
  )
  peer_asn                  = each.value.asn
  peer_ip_address           = each.value.address
  router_appliance_instance = each.value.router_appliance_instance
  advertised_route_priority = each.value.route_priority
  advertise_mode            = each.value.advertise_mode
  advertised_groups         = each.value.advertised_groups
  dynamic "advertised_ip_ranges" {
    for_each = each.value.advertised_ip_ranges
    iterator = range
    content {
      range       = range.key
      description = range.value
    }
  }
  custom_learned_route_priority = each.value.custom_learned_priority
  dynamic "custom_learned_ip_ranges" {
    for_each = each.value.custom_learned_ranges
    iterator = range
    content {
      range = range.value
    }
  }
  dynamic "md5_authentication_key" {
    for_each = each.value.md5_authentication_key == null ? [] : [""]
    content {
      name = each.value.md5_authentication_key.name
      key  = each.value.md5_authentication_key.key
    }
  }
  enable = each.value.enable
  export_policies = [
    for p in each.value.export_policies :
    google_compute_router_route_policy.default["${each.value.router_key}/${p}"].name
  ]
  import_policies = [
    for p in each.value.import_policies :
    google_compute_router_route_policy.default["${each.value.router_key}/${p}"].name
  ]
  lifecycle {
    replace_triggered_by = [terraform_data.router_peer_instances[each.key]]
    precondition {
      condition     = length(each.value.name) <= 63
      error_message = "Peer ${each.key}: name ${each.value.name} exceeds 63 characters."
    }
    precondition {
      condition = alltrue([
        for p in concat(each.value.export_policies, each.value.import_policies) :
        contains(keys(local.router_route_policies), "${each.value.router_key}/${p}")
      ])
      error_message = "Peer ${each.key}: references a route policy not defined on its router."
    }
  }
  # router appliance peers require the instance to be part of an NCC spoke
  depends_on = [google_network_connectivity_spoke.router_appliances]
}
