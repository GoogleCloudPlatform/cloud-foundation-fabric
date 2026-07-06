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
  # Context definition
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
  }
  ctx_p = "$"

  # Resolved variables
  project_id = lookup(local.ctx.project_ids, var.project_id, var.project_id)

  vpc_config = {
    network     = lookup(local.ctx.networks, var.vpc_config.network, var.vpc_config.network)
    subnetworks = { for k, v in var.vpc_config.subnetworks : k => lookup(local.ctx.subnets, v, v) }
  }

  addresses = var.addresses == null ? null : {
    for k, v in var.addresses : k => lookup(local.ctx.addresses, v, v)
  }

  service_attachment = var.service_attachment == null ? null : merge(var.service_attachment, {
    nat_subnets = {
      for k, v in var.service_attachment.nat_subnets : k => [
        for s in v : lookup(local.ctx.subnets, s, s)
      ]
    }
  })

  _neg_configs = {
    for k, v in var.neg_configs : k => {
      project_id = (
        v.project_id == null
        ? null
        : lookup(local.ctx.project_ids, v.project_id, v.project_id)
      )
      cloudrun = (
        v.cloudrun == null
        ? null
        : {
          region         = lookup(local.ctx.locations, v.cloudrun.region, v.cloudrun.region)
          target_service = v.cloudrun.target_service
          target_urlmask = v.cloudrun.target_urlmask
        }
      )
      gce = (
        v.gce == null
        ? null
        : {
          endpoints = v.gce.endpoints
          network = (
            v.gce.network == null
            ? null
            : lookup(local.ctx.networks, v.gce.network, v.gce.network)
          )
          subnetwork = (
            v.gce.subnetwork == null
            ? null
            : lookup(local.ctx.subnets, v.gce.subnetwork, v.gce.subnetwork)
          )
          zone = lookup(local.ctx.locations, v.gce.zone, v.gce.zone)
        }
      )
      hybrid = (
        v.hybrid == null
        ? null
        : {
          endpoints = v.hybrid.endpoints
          network = (
            v.hybrid.network == null
            ? null
            : lookup(local.ctx.networks, v.hybrid.network, v.hybrid.network)
          )
          zone = lookup(local.ctx.locations, v.hybrid.zone, v.hybrid.zone)
        }
      )
      psc = (
        v.psc == null
        ? null
        : {
          region         = lookup(local.ctx.locations, v.psc.region, v.psc.region)
          target_service = v.psc.target_service
          network = (
            v.psc.network == null
            ? null
            : lookup(local.ctx.networks, v.psc.network, v.psc.network)
          )
          subnetwork = (
            v.psc.subnetwork == null
            ? null
            : lookup(local.ctx.subnets, v.psc.subnetwork, v.psc.subnetwork)
          )
        }
      )
    }
  }

  backend_service_configs = {
    for k, v in var.backend_service_configs : k => merge(v, {
      project_id = (
        v.project_id == null
        ? null
        : lookup(local.ctx.project_ids, v.project_id, v.project_id)
      )
    })
  }

  group_configs = {
    for k, v in var.group_configs : k => merge(v, {
      project_id = (
        v.project_id == null
        ? null
        : lookup(local.ctx.project_ids, v.project_id, v.project_id)
      )
      zone = lookup(local.ctx.locations, v.zone, v.zone)
    })
  }

  health_check_configs = {
    for k, v in var.health_check_configs : k => merge(v, {
      project_id = (
        v.project_id == null
        ? null
        : lookup(local.ctx.project_ids, v.project_id, v.project_id)
      )
    })
  }

  # we need keys in the endpoint type to address issue #1055
  _neg_endpoints = flatten([
    for k, v in local.neg_zonal : [
      for kk, vv in v.endpoints : merge(vv, {
        key        = "${k}-${kk}"
        neg        = k
        zone       = v.zone
        ip_address = try(local.ctx.addresses[vv.ip_address], vv.ip_address)
      })
    ]
  ])
  fwd_rule_ports = (
    var.protocol == "HTTPS" ? [443] : coalesce(var.ports, [80])
  )
  fwd_rule_target = (
    var.protocol == "HTTPS"
    ? google_compute_target_https_proxy.default[0].id
    : google_compute_target_http_proxy.default[0].id
  )
  neg_endpoints = {
    for v in local._neg_endpoints : (v.key) => v
  }
  neg_regional = {
    for k, v in local._neg_configs :
    k => merge(v.cloudrun, { project_id = v.project_id }) if v.cloudrun != null
  }
  neg_zonal = {
    # we need to rebuild new objects as we cannot merge different types
    for k, v in local._neg_configs : k => {
      endpoints  = v.gce != null ? v.gce.endpoints : v.hybrid.endpoints
      network    = v.gce != null ? v.gce.network : v.hybrid.network
      project_id = v.project_id
      subnetwork = v.gce != null ? v.gce.subnetwork : null
      type       = v.gce != null ? "GCE_VM_IP_PORT" : "NON_GCP_PRIVATE_IP_PORT"
      zone       = v.gce != null ? v.gce.zone : v.hybrid.zone
    } if v.gce != null || v.hybrid != null
  }
  neg_regional_psc = {
    for k, v in local._neg_configs :
    k => v if v.psc != null
  }
}


resource "google_compute_global_forwarding_rule" "forwarding_rules" {
  for_each              = local.vpc_config.subnetworks
  provider              = google-beta
  project               = local.project_id
  name                  = "${var.name}-${each.key}"
  description           = var.description
  ip_address            = try(local.addresses[each.key], null)
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = local.vpc_config.network
  port_range            = join(",", local.fwd_rule_ports)
  subnetwork            = local.vpc_config.subnetworks[each.key]
  labels                = var.labels
  target                = local.fwd_rule_target
  # during the preview phase you cannot change this attribute on an existing rule
  dynamic "service_directory_registrations" {
    for_each = var.service_directory_registration == null ? [] : [""]
    content {
      namespace                = var.service_directory_registration.namespace
      service_directory_region = var.service_directory_registration.service_directory_region
    }
  }
}

resource "google_compute_target_http_proxy" "default" {
  count                       = var.protocol == "HTTPS" ? 0 : 1
  project                     = local.project_id
  name                        = coalesce(var.http_proxy_config.name, var.name)
  description                 = var.http_proxy_config.description
  http_keep_alive_timeout_sec = var.http_proxy_config.http_keepalive_timeout
  url_map                     = google_compute_url_map.default.id
}

resource "google_compute_target_https_proxy" "default" {
  count                            = var.protocol == "HTTPS" ? 1 : 0
  project                          = local.project_id
  name                             = coalesce(var.https_proxy_config.name, var.name)
  description                      = var.https_proxy_config.description
  certificate_manager_certificates = var.https_proxy_config.certificate_manager_certificates
  http_keep_alive_timeout_sec      = var.https_proxy_config.http_keepalive_timeout
  quic_override                    = var.https_proxy_config.quic_override
  ssl_policy                       = var.https_proxy_config.ssl_policy
  server_tls_policy                = var.https_proxy_config.server_tls_policy
  url_map                          = google_compute_url_map.default.id
}

resource "google_compute_service_attachment" "default" {
  for_each       = local.service_attachment == null ? {} : google_compute_global_forwarding_rule.forwarding_rules
  project        = local.project_id
  region         = each.key
  name           = each.value.name
  description    = local.service_attachment.description
  target_service = each.value.id
  nat_subnets    = local.service_attachment.nat_subnets[each.key]
  connection_preference = (
    local.service_attachment.automatic_connection
    ? "ACCEPT_AUTOMATIC"
    : "ACCEPT_MANUAL"
  )
  consumer_reject_lists = local.service_attachment.consumer_reject_lists
  domain_names = (
    local.service_attachment.domain_name == null
    ? null
    : [local.service_attachment.domain_name[each.key]]
  )
  enable_proxy_protocol = local.service_attachment.enable_proxy_protocol
  reconcile_connections = local.service_attachment.reconcile_connections
  dynamic "consumer_accept_lists" {
    for_each = local.service_attachment.consumer_accept_lists
    iterator = accept
    content {
      project_id_or_num = accept.key
      connection_limit  = accept.value
    }
  }
}

resource "google_compute_network_endpoint_group" "default" {
  for_each = local.neg_zonal
  project = (
    each.value.project_id == null
    ? local.project_id
    : each.value.project_id
  )
  zone = each.value.zone
  name = "${var.name}-${each.key}"
  # re-enable once provider properly supports this
  # default_port = each.value.default_port
  description           = var.description
  network_endpoint_type = each.value.type
  network = (
    each.value.network != null ? each.value.network : local.vpc_config.network
  )
  subnetwork = (
    each.value.type == "NON_GCP_PRIVATE_IP_PORT"
    ? null
    : coalesce(each.value.subnetwork, local.vpc_config.subnetworks[substr(each.value.zone, 0, length(each.value.zone) - 2)])
  )
}

resource "google_compute_network_endpoint" "default" {
  for_each = local.neg_endpoints
  project = (
    google_compute_network_endpoint_group.default[each.value.neg].project
  )
  network_endpoint_group = (
    google_compute_network_endpoint_group.default[each.value.neg].name
  )
  instance   = try(each.value.instance, null)
  ip_address = each.value.ip_address
  port       = each.value.port
  zone       = each.value.zone
}

resource "google_compute_region_network_endpoint_group" "default" {
  for_each = local.neg_regional
  project = (
    each.value.project_id == null
    ? local.project_id
    : each.value.project_id
  )
  region                = each.value.region
  name                  = "${var.name}-${each.key}"
  description           = var.description
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service  = try(each.value.target_service.name, null)
    tag      = try(each.value.target_service.tag, null)
    url_mask = each.value.target_urlmask
  }
}

resource "google_compute_region_network_endpoint_group" "psc" {
  for_each = local.neg_regional_psc
  project  = local.project_id
  region   = each.value.psc.region
  name     = "${var.name}-${each.key}"
  //description           = coalesce(each.value.description, var.description)
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = each.value.psc.target_service
  network               = each.value.psc.network
  subnetwork            = each.value.psc.subnetwork
  lifecycle {
    # ignore until https://github.com/hashicorp/terraform-provider-google/issues/20576 is fixed
    ignore_changes = [psc_data]
  }
}
