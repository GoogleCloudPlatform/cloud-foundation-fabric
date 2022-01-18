# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################
#                                  Network                                    #
###############################################################################

module "lod-vpc" {
  count      = var.network_config.network != null ? 0 : 1
  source     = "../../../modules/net-vpc"
  project_id = module.lod-prj.project_id
  name       = "${local.prefix_lod}-lod-vpc"
  subnets = [
    {
      ip_cidr_range      = var.network_config.vpc_subnet_range.load
      name               = "subnet"
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

module "lod-vpc-firewall" {
  count        = var.network_config.network != null ? 0 : 1
  source       = "../../../modules/net-vpc-firewall"
  project_id   = module.lod-prj.project_id
  network      = module.lod-vpc[0].name
  admin_ranges = values(module.lod-vpc[0].subnet_ips)
}

module "lod-nat" {
  count          = var.network_config.network != null ? 0 : 1
  source         = "../../../modules/net-cloudnat"
  project_id     = module.lod-prj.project_id
  region         = var.region
  name           = "${local.prefix_lod}-default"
  router_network = module.lod-vpc[0].name
}
