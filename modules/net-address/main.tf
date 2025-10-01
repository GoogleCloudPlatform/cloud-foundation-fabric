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

locals {
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  ctx_p = "$"

  # Project ID - already resolved in factory

  # Subnet - resolve $subnet_ids: references if present
  vpc_subnet_id =try(lookup(local.ctx.vpc_subnet_ids, var.vpc_subnet_id, var.vpc_subnet_id), null)
  vpc_id =try(lookup(local.ctx.vpc_ids, var.vpc_id, var.vpc_id), null)
  project_id =try(lookup(local.ctx.project_ids, var.project_id, var.project_id), null)

  # Network - resolve $vpc_ids: references if present
}

# Internal address (INTERNAL, regional)
resource "google_compute_address" "internal" {
  provider = google-beta
  count    = var.address_create && var.address_type == "INTERNAL" && var.purpose != "VPC_PEERING" && var.purpose != "IPSEC_INTERCONNECT" && var.purpose != "PRIVATE_SERVICE_CONNECT" ? 1 : 0

  project      = local.project_id
  name         = var.name
  region       = var.region
  address      = var.address
  address_type = "INTERNAL"
  description  = var.description
  ip_version   = var.ipv6 != null ? "IPV6" : "IPV4"
  labels       = var.labels
  purpose      = var.purpose
  subnetwork   = local.vpc_subnet_id
}

# External address (EXTERNAL, regional)
resource "google_compute_address" "external" {
  provider = google-beta
  count    = var.address_create && var.address_type == "EXTERNAL" ? 1 : 0

  project            = local.project_id
  name               = var.name
  region             = var.region
  address_type       = "EXTERNAL"
  description        = var.description
  ip_version         = var.ipv6 != null ? "IPV6" : "IPV4"
  ipv6_endpoint_type = try(var.ipv6.endpoint_type, null)
  labels             = var.labels
  network_tier       = var.tier
  subnetwork         = local.vpc_subnet_id
}

# Global address (for global load balancers)
resource "google_compute_global_address" "global" {
  count = var.address_create && var.address_type == "GLOBAL" ? 1 : 0

  project     = local.project_id
  name        = var.name
  description = var.description
  ip_version  = var.ipv6 != null ? "IPV6" : "IPV4"
}

# PSA address (Private Service Access - VPC_PEERING purpose)
resource "google_compute_global_address" "psa" {
  count = var.address_create && var.purpose == "VPC_PEERING" ? 1 : 0

  project       = local.project_id
  name          = var.name
  description   = var.description
  address       = var.address
  address_type  = "INTERNAL"
  network       = local.vpc_id
  prefix_length = var.prefix_length
  purpose       = "VPC_PEERING"
}

# IPSEC_INTERCONNECT address (for HPA VPN over Cloud Interconnect)
resource "google_compute_address" "ipsec_interconnect" {
  count = var.address_create && var.purpose == "IPSEC_INTERCONNECT" ? 1 : 0

  project       = local.project_id
  name          = var.name
  region        = var.region
  description   = var.description
  address       = var.address
  address_type  = "INTERNAL"
  network       = local.vpc_id
  prefix_length = var.prefix_length
  purpose       = "IPSEC_INTERCONNECT"
}