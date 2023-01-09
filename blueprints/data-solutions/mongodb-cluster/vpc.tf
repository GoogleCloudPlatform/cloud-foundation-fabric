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

# tfdoc:file:description Compute Engine networking.

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = var.vpc_config.network_project != null ? var.vpc_config.network_project : module.project.project_id
  name       = var.vpc_config.network
  subnets = var.vpc_config.create ? [{
    ip_cidr_range = "10.0.0.0/24"
    name          = var.vpc_config.subnetwork
    region        = var.region
  }] : []
  vpc_create = var.vpc_config.create
}

module "firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.vpc.name
  default_rules_config = {
    disabled = true
  }
  ingress_rules = {
    allow-mongodb-replset = {
      description = "Allow MongoDB replica set traffic."
      sources     = ["mongodb-server"]
      targets     = ["mongodb-server"]
      rules       = [{ protocol = "tcp", ports = [27017] }]
    }
    allow-mongodb-healthcheck = {
      description   = "Allow MongoDB health checks."
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
      targets       = ["mongodb-server"]
      rules         = [{ protocol = "tcp", ports = [8080] }]
    }
  }
}
