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

# tfdoc:file:description NVA factory

locals {
  _nva_files = try(fileset(local.paths.nvas, "**/*.yaml"), [])
  _nva_configs = [
    for f in local._nva_files : merge(
      yamldecode(file("${coalesce(local.paths.nvas, "-")}/${f}")),
      { filename = replace(f, ".yaml", "") }
    )
  ]
  ctx_nva = {
    ilb_addresses = {
      for k, v in module.ilb : k => v.forwarding_rule_addresses[""]
    }
  }
  ctx_nva_instances = {
    # instance self links keyed by instance key, e.g. `primary-b-0`
    self_links = {
      for k, v in module.nva-instance : k => v.self_link
    }
    # instance NIC addresses keyed by `instance key/vpc key`
    addresses = merge([
      for k, v in local.nva_instances : {
        for i, nic in v.attachments :
        "${k}/${trimprefix(nic.network, "$networks:")}" =>
        module.nva-instance[k].internal_ips[i]
      }
    ]...)
  }
  # defaults that keep ILB sandwich connection tracking tables consistent
  # across all load balancers fronting the same NVAs; the idle timeout is
  # left to the API default (600s) so idle connections survive rebalancing
  nva_conntrack_defaults = {
    persist_conn_on_unhealthy = "NEVER_PERSIST"
    track_per_session         = false
  }
  nva_configs = {
    for k, v in local._nva_configs : try(v.name, k) => merge(v, {
      auto_instance_config = try(v.auto_instance_config, {})
      bgp_config           = try(v.bgp_config, null)
      ilb_config           = try(v.ilb_config, {})
      # instance groups are shared by the ILB and RA modes
      instance_groups = coalesce(
        try(v.ilb_config.instance_groups, null),
        try(v.instance_groups, null),
        {}
      )
      ncc_ra_config = try(v.ncc_ra_config, {})
      region = lookup(
        local.ctx.locations, trimprefix(v.region, "$locations:"), v.region
      )
    })
  }
  # auto created instance keys mapped to their NVA
  _nva_instance_keys = merge([
    for nva_key, nva_def in local.nva_configs : {
      for k in flatten([
        for group_key, group_value in nva_def.instance_groups : [
          for n in range(try(group_value.auto_create_instances, 0)) :
          "${nva_def.name}-${group_key}-${n}"
        ]
      ]) : k => { nva_key = nva_key }
    }
  ]...)
  # BGP neighbors for instances running the guest BGP daemon: every router
  # interface whose router peers with the instance, either via the `nva`
  # fan-out or via an explicit $nva_instances: peer, matched to the instance
  # NIC attached to the router's VPC
  _nva_bgp_neighbors = {
    for inst_key, inst in local._nva_instance_keys : inst_key => distinct(flatten([
      for router_key, router_config in local.router_configs : [
        for peer_key, peer_config in try(router_config.peers, {}) : {
          router   = router_config.name
          asn      = router_config.asn
          ip       = try(router_config.interfaces[peer_config.interface].ip_address, null)
          password = try(peer_config.md5_authentication_key.key, null)
          nic_index = try(index(
            [
              for nic in try(local.nva_configs[inst.nva_key].auto_instance_config.nics, []) :
              trimprefix(nic.network, "$networks:")
            ],
            router_config.vpc_self_link
          ), null)
          } if(
          try(peer_config.nva, null) == inst.nva_key ||
          try(peer_config.router_appliance_instance, null) == "$nva_instances:${inst_key}" ||
          startswith(try(peer_config.address, ""), "$nva_addresses:${inst_key}/")
        )
      ]
    ])) if local.nva_configs[inst.nva_key].bgp_config != null
  }
  # rendered FRR configuration per instance, exposed as its own metadata key
  # so that it can be inspected and reloaded without recreating the instance
  _nva_frr_configs = {
    for inst_key, inst in local._nva_instance_keys : inst_key => templatefile(
      "${path.module}/assets/frr.conf.tpl",
      {
        hostname        = "nva-${inst_key}"
        nva_nics_config = try(local.nva_configs[inst.nva_key].auto_instance_config.nics, [])
        bgp = merge(
          {
            asn       = local.nva_configs[inst.nva_key].bgp_config.asn
            keepalive = 20
            holdtime  = 60
          },
          local.nva_configs[inst.nva_key].bgp_config,
          {
            neighbors = [
              for n in local._nva_bgp_neighbors[inst_key] : n
              if n.ip != null && n.nic_index != null
            ]
          }
        )
      }
    ) if local.nva_configs[inst.nva_key].bgp_config != null
  }
  # one health check per NVA, shared by all its ILBs
  nva_health_checks = {
    for k, v in local.nva_configs : k => merge(
      {
        check_interval_sec  = null
        healthy_threshold   = null
        timeout_sec         = null
        unhealthy_threshold = null
      },
      # fall back to the net-lb-int default when no health check is set
      try(
        coalesce(v.ilb_config.health_check),
        { tcp = { port_specification = "USE_SERVING_PORT" } }
      ),
      { project_id = v.project_id }
    ) if length(try(v.ilb_config.forwarding_rules, [])) > 0
  }
  nva_instances = {
    for inst_key, inst in local._nva_instance_keys : inst_key => {
      nva_config = inst.nva_key
      group_zone = split("-", trimprefix(inst_key, "${inst.nva_key}-"))[0]
      zone = format(
        "%s-%s", local.nva_configs[inst.nva_key].region,
        split("-", trimprefix(inst_key, "${inst.nva_key}-"))[0]
      )
      project_id = local.nva_configs[inst.nva_key].project_id
      # the BGP template runs FRR in a container, so it needs COS
      image = try(
        local.nva_configs[inst.nva_key].auto_instance_config.image,
        local.nva_configs[inst.nva_key].bgp_config == null
        ? "projects/debian-cloud/global/images/family/debian-12"
        : "projects/cos-cloud/global/images/family/cos-stable"
      )
      machine_type = try(
        local.nva_configs[inst.nva_key].auto_instance_config.instance_type,
        "e2-standard-4"
      )
      metadata = merge(
        local.nva_configs[inst.nva_key].bgp_config == null
        ? {
          user-data = templatefile(
            "${path.module}/assets/nva-startup-script.yaml.tpl",
            {
              nva_nics_config = try(
                local.nva_configs[inst.nva_key].auto_instance_config.nics, []
              )
            }
          )
        }
        : {
          user-data = templatefile(
            "${path.module}/assets/nva-startup-script-frr.yaml.tpl",
            {
              nva_nics_config = try(
                local.nva_configs[inst.nva_key].auto_instance_config.nics, []
              )
              frr_image = try(
                local.nva_configs[inst.nva_key].bgp_config.frr_image,
                "quay.io/frrouting/frr:10.2.1"
              )
            }
          )
          nva-frr-config = local._nva_frr_configs[inst_key]
        },
        coalesce(try(local.nva_configs[inst.nva_key].auto_instance_config.metadata, null), {})
      )
      attachments = try(
        local.nva_configs[inst.nva_key].auto_instance_config.nics, []
      )
      confidential_compute = try(
        local.nva_configs[inst.nva_key].auto_instance_config.confidential_compute, null
      )
      encryption = try(
        local.nva_configs[inst.nva_key].auto_instance_config.encryption, null
      )
      options = try(
        local.nva_configs[inst.nva_key].auto_instance_config.options, null
      )
      shielded_config = try(
        local.nva_configs[inst.nva_key].auto_instance_config.shielded_config, null
      )
      tags = try(
        local.nva_configs[inst.nva_key].auto_instance_config.tags, ["nva"]
      )
    }
  }
  nva_instance_groups = merge([
    for nva_def in local.nva_configs : {
      for group_key, group_value in nva_def.instance_groups :
      "${nva_def.name}-${group_key}" => {
        nva_config = nva_def.name
        zone_key   = group_key
        name       = "nva-${nva_def.name}-${group_key}"
        project_id = nva_def.project_id
        zone       = "${nva_def.region}-${group_key}"
        network    = try(nva_def.auto_instance_config.nics[0].network, null)
        instances = toset(concat(
          [
            for i in range(try(group_value.auto_create_instances, 0)) :
            module.nva-instance["${nva_def.name}-${group_key}-${i}"].self_link
          ],
          flatten([
            for v in try(group_value.attach_instances, {}) : values(v)
          ])
        ))
        # instance groups are only needed as ILB backends
      } if length(try(nva_def.ilb_config.forwarding_rules, [])) > 0
    }
  ]...)
  nva_ilbs = merge(flatten([
    for nva_def in local.nva_configs : [
      for i, attachment in try(nva_def.ilb_config.forwarding_rules, []) : {
        "${replace(attachment.network, "$networks:", "")}/${nva_def.name}" = {
          name       = "ilb-${nva_def.name}-${i}"
          nva_config = nva_def.name
          project_id = nva_def.project_id
          region     = nva_def.region
          vpc_config = {
            network    = attachment.network
            subnetwork = attachment.subnet
          }
          connection_tracking = merge(
            local.nva_conntrack_defaults,
            try(nva_def.ilb_config.connection_tracking, {})
          )
          session_affinity = try(nva_def.ilb_config.session_affinity, "NONE")
        }
      }
    ]
  ])...)
  # one NCC router appliance spoke per NVA and VPC, containing all auto
  # created instances (via the NIC attached to that VPC) plus any explicit
  # instances listed in the spoke configuration; instance keys are used by
  # the routers factory to fan out BGP peers
  _nva_ra_spoke_keys = flatten([
    for nva_def in local.nva_configs : [
      for spoke in try(nva_def.ncc_ra_config.spokes, []) :
      "${trimprefix(spoke.network, "$networks:")}/${nva_def.name}"
    ]
  ])
  nva_ra_spokes = merge(flatten([
    for nva_def in local.nva_configs : [
      for spoke in try(nva_def.ncc_ra_config.spokes, []) : {
        "${trimprefix(spoke.network, "$networks:")}/${nva_def.name}" = {
          name = replace(
            "ra-${trimprefix(spoke.network, "$networks:")}/${nva_def.name}",
            "/", "-"
          )
          nva_config                 = nva_def.name
          network_key                = trimprefix(spoke.network, "$networks:")
          project_id                 = nva_def.project_id
          region                     = nva_def.region
          hub                        = spoke.hub
          group                      = try(spoke.group, null)
          description                = try(spoke.description, "Terraform-managed.")
          labels                     = try(spoke.labels, {})
          site_to_site_data_transfer = try(spoke.site_to_site_data_transfer, true)
          include_import_ranges      = try(spoke.include_import_ranges, ["ALL_IPV4_RANGES"])
          exclude_import_ranges      = try(spoke.exclude_import_ranges, null)
          instances = concat(
            [
              for k, v in local.nva_instances : {
                key = k
                vm  = local.ctx_nva_instances.self_links[k]
                ip = lookup(
                  local.ctx_nva_instances.addresses,
                  "${k}/${trimprefix(spoke.network, "$networks:")}",
                  null
                )
              } if v.nva_config == nva_def.name
            ],
            [
              for v in try(spoke.instances, []) : {
                key = try(v.name, element(split("/", v.vm), length(split("/", v.vm)) - 1))
                vm = lookup(
                  local.ctx_nva_instances.self_links,
                  trimprefix(v.vm, "$nva_instances:"), v.vm
                )
                ip = lookup(
                  local.ctx_nva_instances.addresses,
                  trimprefix(v.ip, "$nva_addresses:"), v.ip
                )
              }
            ]
          )
        }
      }
    ]
  ])...)
}

module "nva-instance" {
  for_each       = local.nva_instances
  source         = "../../../modules/compute-vm"
  project_id     = each.value.project_id
  name           = "nva-${each.key}"
  zone           = each.value.zone
  machine_type   = each.value.machine_type
  tags           = each.value.tags
  can_ip_forward = true
  network_interfaces = [for k, v in each.value.attachments :
    {
      network    = v.network
      subnetwork = v.subnet
      nat        = false
      addresses  = null
    }
  ]
  boot_disk = {
    source = {
      image = each.value.image
    }
    initialize_params = {
      type = "pd-ssd"
      size = 10 # TODO: make configurable?
    }
  }
  metadata = merge(
    each.value.metadata,
    { google-logging-enabled = true }
  )
  encryption           = each.value.encryption
  shielded_config      = each.value.shielded_config
  confidential_compute = each.value.confidential_compute
  context = {
    kms_keys    = local.ctx.kms_keys
    locations   = local.ctx.locations
    networks    = local.ctx_vpcs.self_links
    project_ids = local.ctx_projects.project_ids
    subnets     = local.ctx_vpcs.subnets_by_vpc
  }
}

resource "google_compute_instance_group" "nva" {
  for_each = local.nva_instance_groups
  project = lookup(
    local.ctx_projects.project_ids,
    replace(each.value.project_id, "$project_ids:", ""),
    each.value.project_id
  )
  zone       = each.value.zone
  name       = each.value.name
  instances  = each.value.instances
  depends_on = [module.nva-instance]
}

resource "google_compute_health_check" "nva" {
  for_each = local.nva_health_checks
  project = lookup(
    local.ctx_projects.project_ids,
    replace(each.value.project_id, "$project_ids:", ""),
    each.value.project_id
  )
  name                = "nva-${each.key}"
  description         = "Shared health check for all ILBs of NVA ${each.key}."
  check_interval_sec  = each.value.check_interval_sec
  healthy_threshold   = each.value.healthy_threshold
  timeout_sec         = each.value.timeout_sec
  unhealthy_threshold = each.value.unhealthy_threshold
  dynamic "grpc_health_check" {
    for_each = try(each.value.grpc, null) == null ? [] : [each.value.grpc]
    iterator = hc
    content {
      port               = try(hc.value.port, null)
      port_name          = try(hc.value.port_name, null)
      port_specification = try(hc.value.port_specification, null)
      grpc_service_name  = try(hc.value.service_name, null)
    }
  }
  dynamic "http_health_check" {
    for_each = try(each.value.http, null) == null ? [] : [each.value.http]
    iterator = hc
    content {
      host               = try(hc.value.host, null)
      port               = try(hc.value.port, null)
      port_name          = try(hc.value.port_name, null)
      port_specification = try(hc.value.port_specification, null)
      proxy_header       = try(hc.value.proxy_header, null)
      request_path       = try(hc.value.request_path, null)
      response           = try(hc.value.response, null)
    }
  }
  dynamic "http2_health_check" {
    for_each = try(each.value.http2, null) == null ? [] : [each.value.http2]
    iterator = hc
    content {
      host               = try(hc.value.host, null)
      port               = try(hc.value.port, null)
      port_name          = try(hc.value.port_name, null)
      port_specification = try(hc.value.port_specification, null)
      proxy_header       = try(hc.value.proxy_header, null)
      request_path       = try(hc.value.request_path, null)
      response           = try(hc.value.response, null)
    }
  }
  dynamic "https_health_check" {
    for_each = try(each.value.https, null) == null ? [] : [each.value.https]
    iterator = hc
    content {
      host               = try(hc.value.host, null)
      port               = try(hc.value.port, null)
      port_name          = try(hc.value.port_name, null)
      port_specification = try(hc.value.port_specification, null)
      proxy_header       = try(hc.value.proxy_header, null)
      request_path       = try(hc.value.request_path, null)
      response           = try(hc.value.response, null)
    }
  }
  dynamic "ssl_health_check" {
    for_each = try(each.value.ssl, null) == null ? [] : [each.value.ssl]
    iterator = hc
    content {
      port               = try(hc.value.port, null)
      port_name          = try(hc.value.port_name, null)
      port_specification = try(hc.value.port_specification, null)
      proxy_header       = try(hc.value.proxy_header, null)
      request            = try(hc.value.request, null)
      response           = try(hc.value.response, null)
    }
  }
  dynamic "tcp_health_check" {
    for_each = try(each.value.tcp, null) == null ? [] : [each.value.tcp]
    iterator = hc
    content {
      port               = try(hc.value.port, null)
      port_name          = try(hc.value.port_name, null)
      port_specification = try(hc.value.port_specification, null)
      proxy_header       = try(hc.value.proxy_header, null)
      request            = try(hc.value.request, null)
      response           = try(hc.value.response, null)
    }
  }
  dynamic "log_config" {
    for_each = try(each.value.enable_logging, false) == true ? [""] : []
    content {
      enable = true
    }
  }
}

module "ilb" {
  source     = "../../../modules/net-lb-int"
  for_each   = local.nva_ilbs
  project_id = each.value.project_id
  region     = each.value.region
  name       = replace("ilb-${each.key}", "/", "-")
  vpc_config = each.value.vpc_config
  backends = [
    for k, v in local.nva_instance_groups : {
      group = google_compute_instance_group.nva[k].id
    } if v.nva_config == each.value.nva_config
  ]
  backend_service_config = {
    connection_tracking = each.value.connection_tracking
    session_affinity    = each.value.session_affinity
  }
  # all ILBs of the same NVA share one health check, so that backend health
  # is evaluated identically on every leg of the sandwich
  health_check        = google_compute_health_check.nva[each.value.nva_config].id
  health_check_config = null
  context = {
    project_ids = local.ctx_projects.project_ids
    networks    = local.ctx_vpcs.self_links
    subnets     = local.ctx_vpcs.subnets_by_vpc
  }
  depends_on = [module.nva-instance]
}

# instances cannot be deleted while referenced by a router appliance spoke
# (HTTP 412), so a change in the instance set replaces the spoke, which makes
# Terraform destroy the spoke before the instances and recreate it after them
resource "terraform_data" "nva_ra_instances" {
  for_each = local.nva_ra_spokes
  input    = [for i in each.value.instances : i.vm]
}

resource "google_network_connectivity_spoke" "router_appliances" {
  for_each = local.nva_ra_spokes
  project = lookup(
    local.ctx_projects.project_ids,
    replace(each.value.project_id, "$project_ids:", ""),
    each.value.project_id
  )
  name = each.value.name
  location = lookup(
    local.ctx.locations,
    replace(each.value.region, "$locations:", ""),
    each.value.region
  )
  description = each.value.description
  labels      = each.value.labels
  hub = lookup(
    local.ctx_ncc_hubs,
    replace(each.value.hub, "$ncc_hubs:", ""),
    each.value.hub
  )
  group = each.value.group == null ? null : lookup(
    local.ctx_ncc_groups,
    replace(each.value.group, "$ncc_groups:", ""),
    each.value.group
  )
  linked_router_appliance_instances {
    dynamic "instances" {
      for_each = each.value.instances
      content {
        ip_address      = instances.value.ip
        virtual_machine = instances.value.vm
      }
    }
    site_to_site_data_transfer = each.value.site_to_site_data_transfer
    include_import_ranges      = each.value.include_import_ranges
    exclude_import_ranges      = each.value.exclude_import_ranges
  }
  lifecycle {
    replace_triggered_by = [terraform_data.nva_ra_instances[each.key]]
    precondition {
      condition     = length(each.value.instances) > 0
      error_message = "Router appliance spoke ${each.key} has no instances: NVA ${each.value.nva_config} creates none and lists none in ncc_ra_config.spokes[].instances."
    }
    precondition {
      condition     = alltrue([for i in each.value.instances : i.ip != null])
      error_message = "NVA ${each.value.nva_config} has no NIC attached to VPC ${each.value.network_key}."
    }
    precondition {
      condition     = length(local._nva_ra_spoke_keys) == length(distinct(local._nva_ra_spoke_keys))
      error_message = "An NVA defines more than one router appliance spoke for the same VPC."
    }
    precondition {
      # an ILB forwarding rule and a router appliance spoke in the same VPC
      # would create two competing next hops for the same NVA
      condition     = !contains(keys(local.nva_ilbs), each.key)
      error_message = "NVA ${each.value.nva_config} has both an ILB forwarding rule and a router appliance spoke in VPC ${each.value.network_key}."
    }
  }
  depends_on = [google_network_connectivity_hub.default, module.nva-instance]
}
