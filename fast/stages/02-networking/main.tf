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

# tfdoc:file:description Networking folder and hierarchical policy.

locals {
  # define the structures used for BGP peers in the VPN resources
  bgp_peer_options = {
    for k, v in var.vpn_spoke_configs :
    k => var.vpn_spoke_configs[k].adv == null ? null : {
      advertise_groups = []
      advertise_ip_ranges = {
        for adv in(var.vpn_spoke_configs[k].adv == null ? [] : var.vpn_spoke_configs[k].adv.custom) :
        var.custom_adv[adv] => adv
      }
      advertise_mode = try(var.vpn_spoke_configs[k].adv.default, false) ? "DEFAULT" : "CUSTOM"
      route_priority = null
    }
  }
  bgp_peer_options_onprem = {
    for k, v in var.vpn_onprem_configs :
    k => var.vpn_onprem_configs[k].adv == null ? null : {
      advertise_groups = []
      advertise_ip_ranges = {
        for adv in(var.vpn_onprem_configs[k].adv == null ? [] : var.vpn_onprem_configs[k].adv.custom) :
        var.custom_adv[adv] => adv
      }
      advertise_mode = try(var.vpn_onprem_configs[k].adv.default, false) ? "DEFAULT" : "CUSTOM"
      route_priority = null
    }
  }
  l7ilb_subnets = { for env, v in var.l7ilb_subnets : env => [
    for s in v : merge(s, {
      active = true
      name   = "${env}-l7ilb-${s.region}"
    })]
  }
  region_trigram = {
    europe-west1 = "ew1"
    europe-west3 = "ew3"
  }
}

module "folder" {
  source        = "../../../modules/folder"
  parent        = "organizations/${var.organization.id}"
  name          = "Networking"
  folder_create = var.folder_id == null
  id            = var.folder_id
  firewall_policy_factory = {
    cidr_file   = "${var.data_dir}/cidrs.yaml"
    policy_name = null
    rules_file  = "${var.data_dir}/hierarchical-policy-rules.yaml"
  }
  firewall_policy_association = {
    factory-policy = "factory"
  }
}

