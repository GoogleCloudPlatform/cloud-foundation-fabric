/**
 * Copyright 2023 Google LLC
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
  _url_lists_path = try(pathexpand(var.factories_config.url_lists), null)
  _url_lists = {
    for f in try(fileset(local._url_lists_path, "**/*.yaml"), []) :
    trimsuffix(f, ".yaml") => yamldecode(file(
      "${local._url_lists_path}/${f}"
    ))
  }
  url_lists = merge(var.url_lists, {
    for k, v in local._url_lists : k => {
      description = lookup(v, "description", null)
      values      = lookup(v, "values", [])
    }
  })
}

moved {
  from = google_network_security_gateway_security_policy.policy
  to   = google_network_security_gateway_security_policy.default
}

resource "google_network_security_gateway_security_policy" "default" {
  provider    = google-beta
  project     = var.project_id
  name        = var.name
  location    = var.region
  description = var.description
  tls_inspection_policy = try(coalesce(
    var.tls_inspection_config.id,
    try(google_network_security_tls_inspection_policy.default[0].id, null)
  ), null)
}

moved {
  from = google_network_security_tls_inspection_policy.tls-policy
  to   = google_network_security_tls_inspection_policy.default
}

resource "google_network_security_tls_inspection_policy" "default" {
  count                 = var.tls_inspection_config.create_config != null ? 1 : 0
  project               = var.project_id
  name                  = var.name
  location              = var.region
  description           = coalesce(var.tls_inspection_config.create_config.description, var.description)
  ca_pool               = var.tls_inspection_config.create_config.ca_pool
  exclude_public_ca_set = var.tls_inspection_config.create_config.exclude_public_ca_set
  min_tls_version       = "TLS_VERSION_UNSPECIFIED" # to avoid drift, not supported by Secure Web Proxy
  tls_feature_profile   = "PROFILE_UNSPECIFIED"     # to avoid drift, not supported by Secure Web Proxy
}

moved {
  from = google_network_security_url_lists.url_list_rules
  to   = google_network_security_url_lists.default
}

resource "google_network_security_url_lists" "default" {
  for_each    = local.url_lists
  project     = var.project_id
  name        = each.key
  location    = var.region
  description = coalesce(each.value.description, var.description)
  values      = each.value.values
}

moved {
  from = google_network_services_gateway.gateway
  to   = google_network_services_gateway.default
}

resource "google_network_services_gateway" "default" {
  project          = var.project_id
  name             = var.name
  location         = var.region
  description      = var.description
  labels           = var.gateway_config.labels
  addresses        = var.gateway_config.addresses
  type             = "SECURE_WEB_GATEWAY"
  ports            = var.gateway_config.ports
  scope            = var.gateway_config.scope
  certificate_urls = var.certificates
  gateway_security_policy = (
    google_network_security_gateway_security_policy.default.id
  )
  network    = var.network
  subnetwork = var.subnetwork
  routing_mode = (
    var.gateway_config.next_hop_routing_mode
    ? "NEXT_HOP_ROUTING_MODE"
    : null
  )
  delete_swg_autogen_router_on_destroy = (
    var.gateway_config.delete_router_on_destroy
  )
}

resource "google_compute_service_attachment" "default" {
  count          = var.service_attachment == null ? 0 : 1
  project        = var.project_id
  region         = var.region
  name           = var.name
  description    = "Service attachment for SWP ${var.name}"
  target_service = google_network_services_gateway.default.self_link
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
