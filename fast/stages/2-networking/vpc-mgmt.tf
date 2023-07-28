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

# tfdoc:file:description Landing VPC and related resources.



# mgmt VPC

module "mgmt-vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.net-project.project_id
  name       = "prod-core-mgmt-0"
  mtu        = 1500
  dns_policy = {
    inbound = false
    logging = false
  }
  delete_default_routes_on_create = true
  create_googleapis_routes = {
    restricted   = false
    restricted-6 = false
    private      = false
    private-6    = false
  }
  subnets = [
    {
      ip_cidr_range = "100.101.3.0/28"
      name          = "prod-core-mgmt-0-nva-primary"
      region        = "europe-west8"
    },
    {
      ip_cidr_range = "100.102.3.128/28"
      name          = "prod-core-mgmt-0-nva-secondary"
      region        = "europe-west12"
    }
  ]
}

module "mgmt-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.net-project.project_id
  network    = module.mgmt-vpc.name
  default_rules_config = {
    disabled = true
  }
  factories_config = {
    cidr_tpl_file = "${var.factories_config.data_dir}/cidrs.yaml"
    rules_folder  = "${var.factories_config.data_dir}/firewall-rules/mgmt"
  }
}
