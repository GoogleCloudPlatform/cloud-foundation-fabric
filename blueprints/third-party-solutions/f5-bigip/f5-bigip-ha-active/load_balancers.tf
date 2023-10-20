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
  ilb_forwarding_rules_config = {
    for k, v in var.forwarding_rules_config
    : k => {
      address       = try(module.lb-addresses.internal_addresses["${var.prefix}-f5-ip-ilb-${k}"].address)
      global_access = v.global_access
      ip_version    = v.ip_version
      protocol      = v.protocol
    } if v.external == false
  }
  nlb_forwarding_rules_config = {
    for k, v in var.forwarding_rules_config
    : k => {
      address    = try(module.lb-addresses.external_addresses["${var.prefix}-f5-ip-nlb-${k}"].address)
      ip_version = v.ip_version
      protocol   = v.protocol
      subnetwork = v.subnetwork
    } if v.external == true
  }
}

module "lb-addresses" {
  source     = "../../../../modules/net-address"
  project_id = var.project_id
  external_addresses = {
    for k, v in var.forwarding_rules_config
    : k => {
      address    = v.address
      ipv6       = v.ip_version == "IPV6" ? { endpoint_type = "NETLB" } : null
      name       = "${var.prefix}-f5-ip-nlb-${k}"
      region     = var.region
      subnetwork = var.vpc_config["dataplane"]["subnetwork"]
    } if v.external == true
  }
  internal_addresses = {
    for k, v in var.forwarding_rules_config
    : k => {
      address    = v.address
      ipv6       = v.ip_version == "IPV6" ? {} : null
      name       = "${var.prefix}-f5-ip-ilb-${k}"
      region     = var.region
      subnetwork = var.vpc_config["dataplane"]["subnetwork"]
    } if v.external == false
  }
}

module "passthrough-ilb" {
  count = (
    length(local.ilb_forwarding_rules_config) > 0
    ? 1
    : 0
  )
  source                  = "../../../../modules/net-lb-int"
  project_id              = var.project_id
  region                  = var.region
  name                    = "${var.prefix}-f5-ilb"
  forwarding_rules_config = local.ilb_forwarding_rules_config
  health_check_config     = var.health_check_config

  backends = [
    for k, _ in var.f5_vms_dedicated_config
    : { group = module.bigip-vms[k].group.self_link }
  ]

  vpc_config = {
    network    = var.vpc_config["dataplane"]["network"]
    subnetwork = var.vpc_config["dataplane"]["subnetwork"]
  }
}

module "passthrough-nlb" {
  count = (
    length(local.nlb_forwarding_rules_config) > 0
    ? 1
    : 0
  )
  source                  = "../../../../modules/net-lb-ext"
  project_id              = var.project_id
  region                  = var.region
  name                    = "${var.prefix}-f5-nlb"
  forwarding_rules_config = local.nlb_forwarding_rules_config
  health_check_config     = var.health_check_config

  backends = [
    for k, _ in var.f5_vms_dedicated_config
    : { group = module.bigip-vms[k].group.self_link }
  ]
}
