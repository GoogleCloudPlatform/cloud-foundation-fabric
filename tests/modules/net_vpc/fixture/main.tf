/**
 * Copyright 2021 Google LLC
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

module "test" {
  source                           = "../../../../modules/net-vpc"
  project_id                       = var.project_id
  name                             = var.name
  iam                              = var.iam
  log_configs                      = var.log_configs
  log_config_defaults              = var.log_config_defaults
  peering_config                   = var.peering_config
  routes                           = var.routes
  shared_vpc_host                  = var.shared_vpc_host
  shared_vpc_service_projects      = var.shared_vpc_service_projects
  subnets                          = var.subnets
  subnet_descriptions              = var.subnet_descriptions
  subnet_flow_logs                 = var.subnet_flow_logs
  subnet_private_access            = var.subnet_private_access
  auto_create_subnetworks          = var.auto_create_subnetworks
  private_service_networking_range = var.private_service_networking_range
}
