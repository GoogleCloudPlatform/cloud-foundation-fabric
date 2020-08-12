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

module "vpc-onprem" {
  source     = "../../modules/net-vpc"
  project_id = var.project_id
  name       = "${local.prefix}onprem"
  subnets = [
    {
      ip_cidr_range      = var.ip_ranges.onprem
      name               = "${local.prefix}onprem"
      region             = var.region
      secondary_ip_range = {}
    }
  ]
  routes = {
    # onprem-default = {
    #   dest_range    = var.ip_ranges.default
    #   priority      = null
    #   tags          = null
    #   next_hop_type = "ilb"
    #   next_hop      = module.gw-ilb.forwarding_rule.self_link
    # }
  }
}

module "firewall-onprem" {
  source               = "../../modules/net-vpc-firewall"
  project_id           = var.project_id
  network              = module.vpc-onprem.name
  admin_ranges_enabled = true
  admin_ranges = [
    var.ip_ranges.hub, var.ip_ranges.onprem
  ]
}

module "nat-onprem" {
  source         = "../../modules/net-cloudnat"
  project_id     = var.project_id
  region         = var.region
  name           = "${local.prefix}onprem"
  router_network = module.vpc-onprem.name
}
