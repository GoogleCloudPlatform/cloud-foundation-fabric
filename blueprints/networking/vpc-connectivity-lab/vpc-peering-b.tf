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

module "spoke-peering-b-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "peering-b"
  mtu        = 1500
  subnets = [
    {
      name          = "peering-b"
      region        = var.region
      ip_cidr_range = var.ip_ranges.peering-b
    }
  ]
  routes = {
    default = {
      description   = "Route to default."
      dest_range    = "0.0.0.0/0"
      tags          = null
      next_hop_type = "ilb"
      next_hop      = module.hub-lb.forwarding_rule_addresses[""]
    }
  }
}

module "peering-b-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.spoke-peering-b-vpc.name
  default_rules_config = {
    admin_ranges = [var.ip_ranges.rfc1918_10]
  }
}
