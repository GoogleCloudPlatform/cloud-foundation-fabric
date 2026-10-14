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
      ilb_config           = try(v.ilb_config, {})
    })
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
  nva_instances = merge(flatten([
    for nva_key, nva_def in local.nva_configs : [
      for group_key, group_value in try(nva_def.ilb_config.instance_groups, {}) : [
        for i in range(try(group_value.auto_create_instances, 0)) : {
          "${nva_def.name}-${group_key}-${i}" = {
            group_zone = group_key
            zone       = "${nva_def.region}-${group_key}"
            project_id = nva_def.project_id
            image = try(
              nva_def.auto_instance_config.image,
              "projects/debian-cloud/global/images/family/debian-12"
            )
            machine_type = try(
              nva_def.auto_instance_config.instance_type, "e2-standard-4"
            )
            metadata = coalesce(
              try(nva_def.auto_instance_config.metadata, null),
              {
                user-data = templatefile(
                  "${path.module}/assets/nva-startup-script.yaml.tpl",
                  { nva_nics_config = try(nva_def.auto_instance_config.nics, []) }
                )
              }
            )
            attachments          = try(nva_def.auto_instance_config.nics, [])
            confidential_compute = try(nva_def.auto_instance_config.confidential_compute, null)
            encryption           = try(nva_def.auto_instance_config.encryption, null)
            options              = try(nva_def.auto_instance_config.options, null)
            shielded_config      = try(nva_def.auto_instance_config.shielded_config, null)
            tags                 = try(nva_def.auto_instance_config.tags, ["nva"])
          }
        }
      ]
    ]
  ])...)
  nva_instance_groups = merge([
    for nva_def in local.nva_configs : {
      for group_key, group_value in try(nva_def.ilb_config.instance_groups, {}) :
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
      }
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
