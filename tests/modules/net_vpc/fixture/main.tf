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

module "test" {
  source                      = "../../../../modules/net-vpc"
  project_id                  = "test-project"
  name                        = "test"
  peering_config              = var.peering_config
  routes                      = var.routes
  shared_vpc_host             = var.shared_vpc_host
  shared_vpc_service_projects = var.shared_vpc_service_projects
  subnet_iam                  = var.subnet_iam
  subnets                     = var.subnets
  auto_create_subnetworks     = var.auto_create_subnetworks
  psa_config                  = var.psa_config
  data_folder                 = var.data_folder
}
