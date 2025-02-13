/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  local_network_name = element(reverse(split("/", var.local_network)), 0)
  auto_local_name    = "${local.prefix}${local.local_network_name}-${local.peer_network_name}"

  peer_network_name = element(reverse(split("/", var.peer_network)), 0)
  auto_peer_name    = "${local.prefix}${local.peer_network_name}-${local.local_network_name}"

  prefix = var.prefix == null ? "" : "${var.prefix}-"
}

resource "google_compute_network_peering" "local_network_peering" {
  name                                = coalesce(var.name.local, local.auto_local_name)
  network                             = var.local_network
  peer_network                        = var.peer_network
  export_custom_routes                = var.routes_config.local.export
  import_custom_routes                = var.routes_config.local.import
  export_subnet_routes_with_public_ip = var.routes_config.local.public_export
  import_subnet_routes_with_public_ip = var.routes_config.local.public_import
  stack_type                          = var.stack_type

  lifecycle {
    precondition {
      condition     = (length(local.auto_local_name) <= 63 || var.name.local != null)
      error_message = "The default peering name exceeds 63 characters. Use var.name.local to provide a custom the name."
    }
  }
}

resource "google_compute_network_peering" "peer_network_peering" {
  count                               = var.peer_create_peering ? 1 : 0
  name                                = coalesce(var.name.peer, local.auto_peer_name)
  network                             = var.peer_network
  peer_network                        = var.local_network
  export_custom_routes                = var.routes_config.peer.export
  import_custom_routes                = var.routes_config.peer.import
  export_subnet_routes_with_public_ip = var.routes_config.peer.public_export
  import_subnet_routes_with_public_ip = var.routes_config.peer.public_import
  stack_type                          = var.stack_type
  depends_on                          = [google_compute_network_peering.local_network_peering]

  lifecycle {
    precondition {
      condition     = (length(local.auto_peer_name) <= 63 || var.name.peer != null)
      error_message = "The default peering name exceeds 63 characters. Use var.name.peer to provide a custom name."
    }
  }
}
