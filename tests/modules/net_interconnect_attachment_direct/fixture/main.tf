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

module "vlan-attachment-1" {
  source         = "../../../../modules/net-interconnect-attachment-direct"
  project_id     = "dedicated-ic-3-8386"
  region         = "us-west2"
  router_create  = var.router_create
  router_name    = var.router_name
  router_config  = var.router_config
  router_network = var.router_network
  name           = var.name
  interconnect   = var.interconnect
  config         = var.config
  peer           = var.peer
  bgp            = var.bgp
}
