/**
 * Copyright 2020 Google LLC
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
  addresses = {
    for k, v in module.addresses.internal_addresses :
    trimprefix(k, local.prefix) => v.address
  }
  addresses_hub_gw = [
    for k, v in module.addresses-hub-gw.internal_addresses : v.address
  ]
  prefix = var.prefix == null || var.prefix == "" ? "" : "${var.prefix}-"
  subnets_all = merge(
    module.vpc-hub.subnets,
    module.vpc-landing.subnets,
    module.vpc-onprem.subnets
  )
  subnets = {
    for k, v in local.subnets_all :
    trimprefix(split("/", k)[1], local.prefix) => v.self_link
  }
  subnets_tunnel = [
    for i in range(0, var.gateway_config.instance_count) :
    cidrsubnet(var.ip_ranges.tunnels, 6, i)
  ]
}

module "project" {
  source         = "../../modules/project"
  name           = var.project_id
  project_create = false
  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
  ]
  service_config = {
    disable_on_destroy         = false
    disable_dependent_services = false
  }
}

module "service-accounts" {
  source     = "../../modules/iam-service-accounts"
  project_id = var.project_id
  names      = ["${local.prefix}gce-vm"]
  iam_project_roles = {
    (var.project_id) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}

module "addresses" {
  source     = "../../modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    "${local.prefix}hub-vip" = {
      region = var.region, subnetwork = local.subnets.hub-vip
    }
    "${local.prefix}landing-gw" = {
      region = var.region, subnetwork = local.subnets.landing
    }
    "${local.prefix}onprem-gw" = {
      region = var.region, subnetwork = local.subnets.onprem
    }
  }
}

module "addresses-hub-gw" {
  source     = "../../modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    for i in range(0, var.gateway_config.instance_count) :
    "${local.prefix}landing-gw-${i + 1}" => {
      region = var.region, subnetwork = local.subnets.landing
    }
  }
}
