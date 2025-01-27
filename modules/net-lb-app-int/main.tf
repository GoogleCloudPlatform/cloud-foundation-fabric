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
  # we need keys in the endpoint type to address issue #1055
  _neg_endpoints = flatten([
    for k, v in local.neg_zonal : [
      for kk, vv in v.endpoints : merge(vv, {
        key = "${k}-${kk}", neg = k, zone = v.zone
      })
    ]
  ])
  fwd_rule_ports = (
    var.protocol == "HTTPS" ? [443] : coalesce(var.ports, [80])
  )
  fwd_rule_target = (
    var.protocol == "HTTPS"
    ? google_compute_region_target_https_proxy.default[0].id
    : google_compute_region_target_http_proxy.default[0].id
  )
  neg_endpoints = {
    for v in local._neg_endpoints : (v.key) => v
  }
  neg_regional = {
    for k, v in var.neg_configs :
    k => merge(v.cloudrun, { project_id = v.project_id }) if v.cloudrun != null
  }
  neg_zonal = {
    # we need to rebuild new objects as we cannot merge different types
    for k, v in var.neg_configs : k => {
      endpoints  = v.gce != null ? v.gce.endpoints : v.hybrid.endpoints
      network    = v.gce != null ? v.gce.network : v.hybrid.network
      project_id = v.project_id
      subnetwork = v.gce != null ? v.gce.subnetwork : null
      type       = v.gce != null ? "GCE_VM_IP_PORT" : "NON_GCP_PRIVATE_IP_PORT"
      zone       = v.gce != null ? v.gce.zone : v.hybrid.zone
    } if v.gce != null || v.hybrid != null
  }
  neg_regional_psc = {
    for k, v in var.neg_configs :
    k => v if v.psc != null
  }
  proxy_ssl_certificates = concat(
    coalesce(var.ssl_certificates.certificate_ids, []),
    [for k, v in google_compute_region_ssl_certificate.default : v.id]
  )
}

resource "google_compute_forwarding_rule" "default" {
  provider              = google-beta
  project               = var.project_id
  region                = var.region
  name                  = var.name
  description           = var.description
  ip_address            = var.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = var.vpc_config.network
  network_tier          = var.network_tier_premium ? "PREMIUM" : "STANDARD"
  port_range            = join(",", local.fwd_rule_ports)
  subnetwork            = var.vpc_config.subnetwork
  labels                = var.labels
  target                = local.fwd_rule_target
  # during the preview phase you cannot change this attribute on an existing rule
  allow_global_access = var.global_access
  dynamic "service_directory_registrations" {
    for_each = var.service_directory_registration == null ? [] : [""]
    content {
      namespace = var.service_directory_registration.namespace
      service   = var.service_directory_registration.service
    }
  }
}

resource "google_compute_region_ssl_certificate" "default" {
  for_each    = var.ssl_certificates.create_configs
  project     = var.project_id
  region      = var.region
  name        = "${var.name}-${each.key}"
  certificate = each.value.certificate
  private_key = each.value.private_key

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_target_http_proxy" "default" {
  count       = var.protocol == "HTTPS" ? 0 : 1
  project     = var.project_id
  region      = var.region
  name        = var.name
  description = var.description
  url_map     = google_compute_region_url_map.default.id
}

resource "google_compute_region_target_https_proxy" "default" {
  count                            = var.protocol == "HTTPS" ? 1 : 0
  project                          = var.project_id
  region                           = var.region
  name                             = var.name
  description                      = var.description
  ssl_certificates                 = length(local.proxy_ssl_certificates) == 0 ? null : local.proxy_ssl_certificates
  ssl_policy                       = var.https_proxy_config.ssl_policy
  url_map                          = google_compute_region_url_map.default.id
  certificate_manager_certificates = var.https_proxy_config.certificate_manager_certificates
}

resource "google_compute_service_attachment" "default" {
  count          = var.service_attachment == null ? 0 : 1
  project        = var.project_id
  region         = var.region
  name           = var.name
  description    = var.description
  target_service = google_compute_forwarding_rule.default.id
  nat_subnets    = var.service_attachment.nat_subnets
  connection_preference = (
    var.service_attachment.automatic_connection
    ? "ACCEPT_AUTOMATIC"
    : "ACCEPT_MANUAL"
  )
  consumer_reject_lists = var.service_attachment.consumer_reject_lists
  domain_names = (
    var.service_attachment.domain_name == null
    ? null
    : [var.service_attachment.domain_name]
  )
  enable_proxy_protocol = var.service_attachment.enable_proxy_protocol
  reconcile_connections = var.service_attachment.reconcile_connections
  dynamic "consumer_accept_lists" {
    for_each = var.service_attachment.consumer_accept_lists
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
    ? var.project_id
    : each.value.project_id
  )
  zone = each.value.zone
  name = "${var.name}-${each.key}"
  # re-enable once provider properly supports this
  # default_port = each.value.default_port
  description           = var.description
  network_endpoint_type = each.value.type
  network = (
    each.value.network != null ? each.value.network : var.vpc_config.network
  )
  subnetwork = (
    each.value.type == "NON_GCP_PRIVATE_IP_PORT"
    ? null
    : coalesce(each.value.subnetwork, var.vpc_config.subnetwork)
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
    ? var.project_id
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
  project  = var.project_id
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

locals {
  _neg_endpoints_internet = flatten([
    for k, v in local.neg_internet : [
      for kk, vv in v.internet.endpoints : merge(vv, {
        key = "${k}-${kk}", neg = k, region = v.internet.region, use_fqdn = v.internet.use_fqdn
      })
    ]
  ])
  neg_endpoints_internet = {
    for v in local._neg_endpoints_internet : (v.key) => v
  }
  neg_internet = {
    for k, v in var.neg_configs :
    k => v if v.internet != null
  }
}

resource "google_compute_region_network_endpoint_group" "internet" {
  for_each = local.neg_internet
  project  = var.project_id
  name     = "${var.name}-${each.key}"
  region   = each.value.internet.region
  # re-enable once provider properly supports this
  # default_port = each.value.default_port
  description = coalesce(each.value.description, var.description)
  network_endpoint_type = (
    each.value.internet.use_fqdn ? "INTERNET_FQDN_PORT" : "INTERNET_IP_PORT"
  )
  network = var.vpc_config.network
}

resource "google_compute_region_network_endpoint" "internet" {
  for_each = local.neg_endpoints_internet
  project = (
    google_compute_region_network_endpoint_group.internet[each.value.neg].project
  )
  region = each.value.region
  region_network_endpoint_group = (
    google_compute_region_network_endpoint_group.internet[each.value.neg].name
  )
  fqdn       = each.value.use_fqdn ? each.value.destination : null
  ip_address = each.value.use_fqdn ? null : each.value.destination
  port       = each.value.port
}
