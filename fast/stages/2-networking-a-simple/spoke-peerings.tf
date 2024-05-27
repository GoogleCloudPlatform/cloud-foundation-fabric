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

# tfdoc:file:description Peerings between landing and spokes.

moved {
  from = module.peering-dev
  to   = module.peering-dev[0]
}

module "peering-dev" {
  count         = local.spoke_connection == "peering" ? 1 : 0
  source        = "../../../modules/net-vpc-peering"
  prefix        = "dev-peering-0"
  local_network = module.dev-spoke-vpc.self_link
  peer_network  = module.landing-vpc.self_link
  routes_config = var.spoke_configs.peering_configs.dev
}

moved {
  from = module.peering-prod
  to   = module.peering-prod[0]
}

module "peering-prod" {
  count         = local.spoke_connection == "peering" ? 1 : 0
  source        = "../../../modules/net-vpc-peering"
  prefix        = "prod-peering-0"
  local_network = module.prod-spoke-vpc.self_link
  peer_network  = module.landing-vpc.self_link
  routes_config = var.spoke_configs.peering_configs.prod
  depends_on    = [module.peering-dev]
}

