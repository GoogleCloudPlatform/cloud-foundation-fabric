/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description NEG resources.

locals {
  _neg_endpoints_zonal = flatten([
    for k, v in local.neg_zonal : [
      for kk, vv in v.endpoints : merge(vv, {
        key = "${k}-${kk}", neg = k, zone = v.zone
      })
    ]
  ])
  neg_endpoints_zonal = {
    for v in local._neg_endpoints_zonal : (v.key) => v
  }

  neg_regional_internet = {
    for k, v in var.neg_configs :
    k => merge(v, {
      # Calculate the endpoint type based on the first endpoint
      # If any endpoint has fqdn, we'll use FQDN_PORT, otherwise IP_PORT
      endpoint_type = length(v.internet.endpoints) > 0 ? (
        alltrue([
          for e_key, e in v.internet.endpoints : e.fqdn == null
        ]) ? "INTERNET_IP_PORT" : "INTERNET_FQDN_PORT"
      ) : "INTERNET_FQDN_PORT" # Default if no endpoints
    }) if v.internet != null
  }

  neg_regional_psc = {
    for k, v in var.neg_configs :
    k => v if v.psc != null
  }
  neg_regional_serverless = {
    for k, v in var.neg_configs :
    k => v if v.cloudrun != null || v.cloudfunction != null
  }
  neg_zonal = {
    # we need to rebuild new objects as we cannot merge different types
    for k, v in var.neg_configs : k => {
      description = v.description
      endpoints   = v.gce != null ? v.gce.endpoints : v.hybrid.endpoints
      network     = v.gce != null ? v.gce.network : v.hybrid.network
      subnetwork  = v.gce != null ? v.gce.subnetwork : null
      type        = v.gce != null ? "GCE_VM_IP_PORT" : "NON_GCP_PRIVATE_IP_PORT"
      zone        = v.gce != null ? v.gce.zone : v.hybrid.zone
    } if v.gce != null || v.hybrid != null
  }

  # Create a map of Internet NEG endpoints for for_each
  internet_neg_endpoints = {
    for endpoint in flatten([
      for neg_key, neg in local.neg_regional_internet : [
        for endpoint_key, endpoint in neg.internet.endpoints : {
          id            = "${neg_key}-${endpoint_key}"
          neg_key       = neg_key
          endpoint_key  = endpoint_key
          region        = neg.internet.region
          fqdn          = try(endpoint.fqdn, null)
          ip_address    = try(endpoint.ip_address, null)
          port          = endpoint.port
          endpoint_type = neg.endpoint_type
        }
      ]
    ]) : endpoint.id => endpoint
  }
}

resource "google_compute_network_endpoint_group" "default" {
  for_each = local.neg_zonal
  project  = var.project_id
  zone     = each.value.zone
  name     = "${var.name}-${each.key}"
  # re-enable once provider properly supports this
  # default_port = each.value.default_port
  description           = coalesce(each.value.description, var.description)
  network_endpoint_type = each.value.type
  network               = each.value.network
  subnetwork = (
    each.value.type == "NON_GCP_PRIVATE_IP_PORT"
    ? null
    : each.value.subnetwork
  )
}

resource "google_compute_network_endpoint" "default" {
  for_each = local.neg_endpoints_zonal
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

resource "google_compute_region_network_endpoint_group" "internet" {
  for_each              = local.neg_regional_internet
  project               = var.project_id
  region                = each.value.internet.region
  name                  = "${var.name}-${each.key}"
  description           = coalesce(each.value.description, var.description)
  network_endpoint_type = each.value.endpoint_type
  network               = each.value.internet.network
}

resource "google_compute_region_network_endpoint" "internet" {
  for_each                      = local.internet_neg_endpoints
  region                        = each.value.region
  region_network_endpoint_group = google_compute_region_network_endpoint_group.internet[each.value.neg_key].name
  # Only set fqdn if endpoint type is FQDN_PORT
  fqdn = each.value.endpoint_type == "INTERNET_FQDN_PORT" ? each.value.fqdn : null
  # Only set ip_address if endpoint type is IP_PORT
  ip_address = each.value.endpoint_type == "INTERNET_IP_PORT" ? each.value.ip_address : null
  port       = each.value.port
  project    = var.project_id
}

resource "google_compute_region_network_endpoint_group" "psc" {
  for_each              = local.neg_regional_psc
  project               = var.project_id
  region                = each.value.psc.region
  name                  = "${var.name}-${each.key}"
  description           = coalesce(each.value.description, var.description)
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = each.value.psc.target_service
  network               = each.value.psc.network
  subnetwork            = each.value.psc.subnetwork
  lifecycle {
    # ignore until https://github.com/hashicorp/terraform-provider-google/issues/20576 is fixed
    ignore_changes = [psc_data]
  }
}

resource "google_compute_region_network_endpoint_group" "serverless" {
  for_each = local.neg_regional_serverless
  project = (
    each.value.project_id == null
    ? var.project_id
    : each.value.project_id
  )
  region = try(
    each.value.cloudrun.region, each.value.cloudfunction.region, null
  )
  name                  = "${var.name}-${each.key}"
  description           = coalesce(each.value.description, var.description)
  network_endpoint_type = "SERVERLESS"
  dynamic "cloud_function" {
    for_each = each.value.cloudfunction == null ? [] : [""]
    content {
      function = each.value.cloudfunction.target_function
      url_mask = each.value.cloudfunction.target_urlmask
    }
  }
  dynamic "cloud_run" {
    for_each = each.value.cloudrun == null ? [] : [""]
    content {
      service  = try(each.value.cloudrun.target_service.name, null)
      tag      = try(each.value.cloudrun.target_service.tag, null)
      url_mask = each.value.cloudrun.target_urlmask
    }
  }
}
