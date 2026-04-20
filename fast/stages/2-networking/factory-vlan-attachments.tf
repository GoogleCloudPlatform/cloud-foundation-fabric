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

# tfdoc:file:description VLAN attachments factory.

locals {
  # Discover YAML files that define VLAN attachments across all VPCs.
  # It checks each VPC's configured `vlan_attachments` factory path (defaulting to
  # `<factory_basepath>/vlan-attachments`).
  # Returns a flattened map of all discovered files keyed by `<vpc_key>-<filename>`.
  _vlan_attachments_files = try(
    merge([
      for vpc_key, vpc in local.vpcs : {
        for f in try(fileset(
          try(
            startswith(vpc.factories_config.vlan_attachments, "/") || startswith(vpc.factories_config.vlan_attachments, ".") ? vpc.factories_config.vlan_attachments :
            "${vpc.factory_basepath}/${vpc.factories_config.vlan_attachments}",
            "${vpc.factory_basepath}/vlan-attachments"
          ),
          "**/*.yaml"
        ), []) :
        "${vpc_key}-${replace(f, ".yaml", "")}" => {
          vpc_key  = vpc_key
          filename = f
          path = try(
            startswith(vpc.factories_config.vlan_attachments, "/") || startswith(vpc.factories_config.vlan_attachments, ".")
            ? "${vpc.factories_config.vlan_attachments}/${f}"
            : "${vpc.factory_basepath}/${vpc.factories_config.vlan_attachments}/${f}",
            "${vpc.factory_basepath}/vlan-attachments/${f}"
          )
        }
      }
    ]...),
    {}
  )
  # Read and decode the discovered YAML files. This step also injects VPC-level
  # inferred attributes  into each configuration, such as the `project_id` and
  # `network`, ensuring each attachment is correctly associated with its parent VPC.
  _vlan_attachments_preprocess = {
    for k, v in local._vlan_attachments_files : k => merge(
      try(yamldecode(file(v.path)), {}),
      {
        key        = k
        vpc_key    = v.vpc_key
        project_id = local.vpcs[v.vpc_key].project_id
        network    = local.vpcs[v.vpc_key].name
      }
    )
  }
  vlan_attachments = {
    for k, v in local._vlan_attachments_preprocess : k => merge(v, {
      region = try(v.region, local.vpc_defaults.region, null)
      mtu    = try(v.mtu, local.vpcs[v.vpc_key].mtu, local.vpc_defaults.mtu, 1500)
    })
  }

  _attachment_groups_files = try(
    merge([
      for vpc_key, vpc in local.vpcs : {
        for f in try(fileset(
          try(
            startswith(vpc.factories_config.attachment_groups, "/") || startswith(vpc.factories_config.attachment_groups, ".") ? vpc.factories_config.attachment_groups :
            "${vpc.factory_basepath}/${vpc.factories_config.attachment_groups}",
            "${vpc.factory_basepath}/attachment-groups"
          ),
          "**/*.yaml"
        ), []) :
        "${vpc_key}-${replace(f, ".yaml", "")}" => {
          vpc_key  = vpc_key
          filename = f
          path = try(
            startswith(vpc.factories_config.attachment_groups, "/") || startswith(vpc.factories_config.attachment_groups, ".")
            ? "${vpc.factories_config.attachment_groups}/${f}"
            : "${vpc.factory_basepath}/${vpc.factories_config.attachment_groups}/${f}",
            "${vpc.factory_basepath}/attachment-groups/${f}"
          )
        }
      }
    ]...),
    {}
  )
  _attachment_groups_preprocess = {
    for k, v in local._attachment_groups_files : k => merge(
      {
        project_id = local.vpcs[v.vpc_key].project_id
      },
      try(yamldecode(file(v.path)), {}),
      {
        key     = k
        vpc_key = v.vpc_key
      }
    )
  }
  attachment_groups = {
    for k, v in local._attachment_groups_preprocess : k => merge(v, {
      name   = try(v.name, k)
      intent = try(v.intent, { availability_sla = "NO_SLA" })
    })
  }

  ctx_attachment_groups = {
    for k, v in local.attachment_groups : "${v.vpc_key}/${v.name}" => k
  }

  ctx_vlan_attachments = {
    for k, v in local.vlan_attachments : "${v.vpc_key}/${try(v.name, k)}" => k
  }

  # Gathers all members for each attachment group. Membership can be defined
  # in two ways:
  # 1. From the VLAN attachment's config via the `attachment_group` attribute.
  # 2. From the attachment group's config via the `attachments` map.
  _attachment_groups_attachments = {
    for g_key, g_config in local.attachment_groups : g_key =>
    concat(
      [
        for a_key, a_config in local.vlan_attachments : {
          name       = try(a_config.name, a_config.key)
          attachment = module.vlan-attachments[a_key].id
        }
        if try(
          lookup(local.ctx_attachment_groups, replace(a_config.attachment_group, "$attachment_groups:", ""), a_config.attachment_group),
          null
        ) == g_key || (try(a_config.attachment_group, null) == g_config.name && a_config.vpc_key == g_config.vpc_key)
      ],
      [
        for a in values(try(g_config.attachments, {})) : {
          name = a.name
          attachment = try(
            module.vlan-attachments[lookup(local.ctx_vlan_attachments, replace(a.attachment, "$vlan_attachments:", ""), a.attachment)].id,
            a.attachment
          )
        }
      ]
    )
  }
}

module "vlan-attachments" {
  source   = "../../../modules/net-vlan-attachment"
  for_each = local.vlan_attachments

  admin_enabled                 = try(each.value.admin_enabled, true)
  bgp_peer                      = try(each.value.bgp_peer, null)
  dedicated_interconnect_config = try(each.value.dedicated_interconnect_config, null)
  description                   = try(each.value.description, "Terraform managed.")
  ipsec_gateway_ip_ranges       = try(each.value.ipsec_gateway_ip_ranges, {})
  mtu                           = each.value.mtu
  name                          = try(each.value.name, each.value.key)
  network                       = each.value.network
  partner_interconnect_config   = try(each.value.partner_interconnect_config, null)
  peer_asn                      = each.value.peer_asn
  project_id                    = try(each.value.project_id, local.project_defaults.defaults.parent)
  region                        = each.value.region
  router_config                 = each.value.router_config
  vpn_gateways_ip_range         = try(each.value.vpn_gateways_ip_range, null)

  context = {
    locations   = local.ctx.locations
    networks    = local.ctx_vpcs.self_links
    project_ids = local.ctx_projects.project_ids
    routers     = local.ctx_routers.names
  }
  depends_on = [module.vpc-factory]
}

resource "google_compute_interconnect_attachment_group" "default" {
  for_each = local.attachment_groups
  project = lookup(
    local.ctx_projects.project_ids,
    replace(each.value.project_id, "$project_ids:", ""),
    each.value.project_id
  )
  name        = each.value.name
  description = try(each.value.description, "Terraform-managed.")

  intent {
    availability_sla = try(each.value.intent.availability_sla, "NO_SLA")
  }

  dynamic "attachments" {
    for_each = local._attachment_groups_attachments[each.key]
    content {
      name       = attachments.value.name
      attachment = attachments.value.attachment
    }
  }

  depends_on = [module.vlan-attachments]
}
