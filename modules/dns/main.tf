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
  managed_zone = (var.zone_config == null ?
    data.google_dns_managed_zone.dns_managed_zone[0]
    : google_dns_managed_zone.dns_managed_zone[0]
  )
  # split record name and type and set as keys in a map
  _recordsets_0 = {
    for key, attrs in var.recordsets :
    key => merge(attrs, zipmap(["type", "name"], split(" ", key)))
  }
  # compute the final resource name for the recordset
  recordsets = {
    for key, attrs in local._recordsets_0 :
    key => merge(attrs, {
      resource_name = (
        attrs.name == ""
        ? local.managed_zone.dns_name
        : (
          substr(attrs.name, -1, 1) == "."
          ? attrs.name
          : "${attrs.name}.${local.managed_zone.dns_name}"
        )
      )
    })
  }
  client_networks = concat(
    coalesce(try(var.zone_config.forwarding.client_networks, null), []),
    coalesce(try(var.zone_config.peering.client_networks, null), []),
    coalesce(try(var.zone_config.private.client_networks, null), [])
  )
  visibility = (var.zone_config == null ?
    null
    : (var.zone_config.forwarding != null ||
      var.zone_config.peering != null
    || var.zone_config.private != null) ?
    "private" :
    "public"
  )
}

resource "google_dns_managed_zone" "dns_managed_zone" {
  count          = (var.zone_config == null) ? 0 : 1
  provider       = google-beta
  project        = var.project_id
  name           = var.name
  dns_name       = var.zone_config.domain
  description    = var.description
  force_destroy  = var.force_destroy
  visibility     = local.visibility
  reverse_lookup = try(var.zone_config.private, null) != null && endswith(var.zone_config.domain, ".in-addr.arpa.")

  dynamic "dnssec_config" {
    for_each = try(var.zone_config.public.dnssec_config, null) == null ? [] : [""]
    iterator = config
    content {
      kind          = "dns#managedZoneDnsSecConfig"
      non_existence = var.zone_config.public.dnssec_config.non_existence
      state         = var.zone_config.public.dnssec_config.state

      default_key_specs {
        algorithm  = var.zone_config.public.dnssec_config.key_signing_key.algorithm
        key_length = var.zone_config.public.dnssec_config.key_signing_key.key_length
        key_type   = "keySigning"
        kind       = "dns#dnsKeySpec"
      }

      default_key_specs {
        algorithm  = var.zone_config.public.dnssec_config.zone_signing_key.algorithm
        key_length = var.zone_config.public.dnssec_config.zone_signing_key.key_length
        key_type   = "zoneSigning"
        kind       = "dns#dnsKeySpec"
      }
    }
  }

  dynamic "forwarding_config" {
    for_each = (length(coalesce(try(var.zone_config.forwarding.forwarders, null), {})) > 0
      ? [""]
      : []
    )
    content {
      dynamic "target_name_servers" {
        for_each = var.zone_config.forwarding.forwarders
        iterator = forwarder
        content {
          ipv4_address    = forwarder.key
          forwarding_path = forwarder.value
        }
      }
    }
  }

  dynamic "peering_config" {
    for_each = try(var.zone_config.peering.peer_network, null) == null ? [] : [""]
    content {
      target_network {
        network_url = var.zone_config.peering.peer_network
      }
    }
  }

  dynamic "private_visibility_config" {
    for_each = length(local.client_networks) > 0 ? [""] : []
    content {
      dynamic "networks" {
        for_each = local.client_networks
        iterator = network
        content {
          network_url = network.value
        }
      }
    }
  }

  dynamic "service_directory_config" {
    for_each = (try(var.zone_config.private.service_directory_namespace, null) == null
      ? []
      : [""]
    )
    content {
      namespace {
        namespace_url = var.zone_config.private.service_directory_namespace
      }
    }
  }
  cloud_logging_config {
    enable_logging = try(var.zone_config.public.enable_logging, false)
  }
}

data "google_dns_managed_zone" "dns_managed_zone" {
  count   = var.zone_config == null ? 1 : 0
  project = var.project_id
  name    = var.name
}

resource "google_dns_managed_zone_iam_binding" "iam_bindings" {
  for_each     = coalesce(var.iam, {})
  project      = var.project_id
  managed_zone = local.managed_zone.id
  role         = each.key
  members      = each.value
}

data "google_dns_keys" "dns_keys" {
  count        = try(var.zone_config.public.dnssec_config.state, "off") != "off" ? 1 : 0
  managed_zone = local.managed_zone.id
  project      = var.project_id
}

resource "google_dns_record_set" "dns_record_set" {
  for_each     = local.recordsets
  project      = var.project_id
  managed_zone = var.name
  name         = each.value.resource_name
  type         = each.value.type
  ttl          = each.value.ttl
  rrdatas      = each.value.records

  dynamic "routing_policy" {
    for_each = (each.value.geo_routing != null || each.value.wrr_routing != null) ? [""] : []
    content {
      dynamic "geo" {
        for_each = coalesce(each.value.geo_routing, [])
        content {
          location = geo.value.location
          rrdatas  = geo.value.records
          dynamic "health_checked_targets" {
            for_each = try(geo.value.health_checked_targets, null) == null ? [] : [""]
            content {
              dynamic "internal_load_balancers" {
                for_each = geo.value.health_checked_targets
                content {
                  load_balancer_type = internal_load_balancers.value.load_balancer_type
                  ip_address         = internal_load_balancers.value.ip_address
                  port               = internal_load_balancers.value.port
                  ip_protocol        = internal_load_balancers.value.ip_protocol
                  network_url        = internal_load_balancers.value.network_url
                  project            = internal_load_balancers.value.project
                  region             = internal_load_balancers.value.region
                }
              }
            }
          }
        }
      }
      dynamic "wrr" {
        for_each = coalesce(each.value.wrr_routing, [])
        content {
          weight  = wrr.value.weight
          rrdatas = wrr.value.records
        }
      }
    }
  }

  depends_on = [
    google_dns_managed_zone.dns_managed_zone
  ]
}
