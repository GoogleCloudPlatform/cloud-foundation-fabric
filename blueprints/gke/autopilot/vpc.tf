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

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = var.vpc_name
  vpc_create = var.vpc_create
  subnets = [
    {
      ip_cidr_range = var.mgmt_subnet_cidr_block
      name          = "subnet-mgmt"
      region        = var.region
    },
    {
      ip_cidr_range = var.cluster_network_config.nodes_cidr_block
      name          = "subnet-cluster"
      region        = var.region
      secondary_ip_ranges = {
        pods     = var.cluster_network_config.pods_cidr_block
        services = var.cluster_network_config.services_cidr_block
      }
    }
  ]
}

module "firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.vpc.name
}

module "nat" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  region         = var.region
  name           = "nat"
  router_network = module.vpc.name
}
