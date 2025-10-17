/**
 * Copyright 2025 Google LLC
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
  _nva_path  = try(pathexpand(var.factories_config.nvas), null)
  _nva_files = try(fileset(local._nva_path, "**/*.yaml"), [])
  _nva_configs = [
    for f in local._nva_files : merge(
      yamldecode(file("${coalesce(local._nva_path, "-")}/${f}")),
      { filename = replace(f, ".yaml", "") }
    )
  ]
  ctx_nva = {
    ilb_addresses = {
      for k, v in module.ilb : k => v.forwarding_rule_addresses[""]
    }
  }
  nva_configs = {
    for k, v in local._nva_configs : try(v.name, k) => merge(v, {
      attachments = [for a in try(v.attachments, []) : merge(a, {
        routes     = try(a.routes, [])
        create_ilb = try(a.create_ilb, true)
      })]
    })
  }
  nva_instances = merge(flatten([
    for nva_key, nva_def in local.nva_configs : [
      for group_key, group_value in nva_def.instance_groups : [
        for i in range(try(group_value.auto_create_instances, 0)) : {
          "${nva_def.name}-${group_key}-${i}" = {
            group_zone = group_key
            zone       = "${nva_def.region}-${group_key}"
            project_id = nva_def.project_id
            image = try(
              nva_def.image, "projects/debian-cloud/global/images/family/debian-12"
            )
            instance_type = try(
              nva_def.instance_type, "e2-standard-4"
            )
            metadata = coalesce(
              try(nva_def.metadata, null),
              {
                user-data = templatefile(
                  "${path.module}/assets/nva-startup-script.yaml.tpl",
                  { nva_nics_config = nva_def.attachments }
                )
              }
            )
            attachments = nva_def.attachments
            tags        = try(nva_def.tags, ["nva"])
            options     = try(nva_def.options, null)
          }
        }
      ]
    ]
  ])...)
  nva_instance_groups = merge([
    for nva_def in local.nva_configs : {
      for group_key, group_value in try(nva_def.instance_groups, {}) :
      "${nva_def.name}-${group_key}" => {
        nva_config = nva_def.name
        zone_key   = group_key
        name       = "nva-${nva_def.name}-${group_key}"
        project_id = nva_def.project_id
        zone       = "${nva_def.region}-${group_key}"
        network    = try(nva_def.attachments[0].network, null)
        instances = toset(concat(
          [
            for i in range(try(group_value.auto_create_instances, 0)) :
            module.nva-instance["${nva_def.name}-${group_key}-${i}"].self_link
          ],
          flatten([
            for v in try(group_value.attach_instances, {}) : values(v)
          ])
        ))
      }
    }
  ]...)
  nva_ilbs = merge(flatten([
    for nva_def in local.nva_configs : [
      for i, attachment in nva_def.attachments : {
        "${replace(attachment.network, "$networks:", "")}/${nva_def.name}" = {
          name       = "ilb-${nva_def.name}-${i}"
          nva_config = nva_def.name
          project_id = nva_def.project_id
          region     = nva_def.region
          vpc_config = {
            network    = attachment.network
            subnetwork = attachment.subnet
          }
          health_check = try(nva_def.health_check, null)
        }
      } if attachment.create_ilb == true
    ]
  ])...)
}

module "nva-instance" {
  for_each       = local.nva_instances
  source         = "../../../modules/compute-vm"
  project_id     = each.value.project_id
  name           = "nva-${each.key}"
  zone           = each.value.zone
  instance_type  = each.value.instance_type
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
    initialize_params = {
      image                  = each.value.image
      google-logging-enabled = true
      type                   = "pd-ssd"
      size                   = 10 # TODO: make configurable?
    }
  }
  metadata = each.value.metadata
  context = {
    project_ids = local.ctx_projects.project_ids
    vpcs        = local.ctx_vpcs.self_links
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
  zone = each.value.zone
  name = each.value.name
  #network    = lookup(local.ctx_vpcs.self_links, replace(each.value.network, "$networks:", ""), each.value.network)
  instances  = each.value.instances
  depends_on = [module.nva-instance]
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
  health_check_config = each.value.health_check
  context = {
    project_ids = local.ctx_projects.project_ids
    vpcs        = local.ctx_vpcs.self_links
    subnets     = local.ctx_vpcs.subnets_by_vpc
  }
  depends_on = [module.nva-instance]
}
