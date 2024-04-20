# Copyright 2023 Google LLC
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

# tfdoc:file:description VPC resources.

module "vpc" {
  source     = "../../../modules/net-vpc"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.project.project_id
  name       = "${var.prefix}-vpc"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/20"
      name          = "${var.prefix}-subnet"
      region        = var.region
    }
  ]
}

module "vpc-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.project.project_id
  network    = module.vpc[0].name
  default_rules_config = {
    admin_ranges = ["10.0.0.0/20"]
  }
  ingress_rules = {
    #TODO Remove and rely on 'ssh' tag once terraform-provider-google/issues/9273 is fixed
    ("${var.prefix}-iap") = {
      description   = "Enable SSH from IAP on Notebooks."
      source_ranges = ["35.235.240.0/20"]
      targets       = ["notebook-instance"]
      rules         = [{ protocol = "tcp", ports = [22] }]
    }
  }
}

module "cloudnat" {
  source         = "../../../modules/net-cloudnat"
  count          = local.use_shared_vpc ? 0 : 1
  project_id     = module.project.project_id
  name           = "${var.prefix}-default"
  region         = var.region
  router_network = module.vpc[0].name
}

resource "google_project_iam_member" "shared_vpc" {
  count   = local.use_shared_vpc ? 1 : 0
  project = var.vpc_config.host_project
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${module.project.service_accounts.robots.notebooks}"
}
