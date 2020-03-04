/**
 * Copyright 2018 Google LLC
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
  is_static_zone = var.type == "public" || var.type == "private"
  recordsets = var.recordsets == null ? {} : {
    for record in var.recordsets :
    join("/", [record.name, record.type]) => record
  }
  zone = element(concat(
    google_dns_managed_zone.non-public, google_dns_managed_zone.public
  ), 0)
}

resource "google_dns_managed_zone" "non-public" {
  count       = var.type != "public" ? 1 : 0
  provider    = google-beta
  project     = var.project_id
  name        = var.name
  dns_name    = var.domain
  description = "Terraform-managed zone."
  visibility  = "private"

  dynamic forwarding_config {
    for_each = (
      var.type == "forwarding" && var.forwarders != null
      ? { config = var.forwarders }
      : {}
    )
    iterator = config
    content {
      dynamic "target_name_servers" {
        for_each = config.value
        iterator = address
        content {
          ipv4_address = address.value
        }
      }
    }
  }

  dynamic peering_config {
    for_each = (
      var.type == "peering" && var.peer_network != null
      ? { config = var.peer_network }
      : {}
    )
    iterator = config
    content {
      target_network {
        network_url = config.value
      }
    }
  }

  private_visibility_config {
    dynamic "networks" {
      for_each = var.client_networks
      iterator = network
      content {
        network_url = network.value
      }
    }
  }

}

resource "google_dns_managed_zone" "public" {
  count       = var.type == "public" ? 1 : 0
  project     = var.project_id
  name        = var.name
  dns_name    = var.domain
  description = var.description
  visibility  = "public"

  dynamic "dnssec_config" {
    for_each = var.dnssec_config == {} ? [] : list(var.dnssec_config)
    iterator = config
    content {
      kind          = lookup(config.value, "kind", "dns#managedZoneDnsSecConfig")
      non_existence = lookup(config.value, "non_existence", "nsec3")
      state         = lookup(config.value, "state", "off")

      default_key_specs {
        algorithm  = lookup(var.default_key_specs_key, "algorithm", "rsasha256")
        key_length = lookup(var.default_key_specs_key, "key_length", 2048)
        key_type   = lookup(var.default_key_specs_key, "key_type", "keySigning")
        kind       = lookup(var.default_key_specs_key, "kind", "dns#dnsKeySpec")
      }
      default_key_specs {
        algorithm  = lookup(var.default_key_specs_zone, "algorithm", "rsasha256")
        key_length = lookup(var.default_key_specs_zone, "key_length", 1024)
        key_type   = lookup(var.default_key_specs_zone, "key_type", "zoneSigning")
        kind       = lookup(var.default_key_specs_zone, "kind", "dns#dnsKeySpec")
      }
    }
  }

}

resource "google_dns_record_set" "cloud-static-records" {
  for_each = (
    var.type == "public" || var.type == "private"
    ? local.recordsets
    : {}
  )
  project      = var.project_id
  managed_zone = var.name
  name         = each.value.name != "" ? "${each.value.name}.${var.domain}" : var.domain
  type         = each.value.type
  ttl          = each.value.ttl
  rrdatas      = each.value.records
  depends_on = [
    google_dns_managed_zone.non-public, google_dns_managed_zone.public
  ]
}
