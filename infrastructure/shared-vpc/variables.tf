# Copyright 2019 Google LLC
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

################################################################################
#                               shared VPC host                                #
################################################################################

# project

module "project-svpc-host" {
  source          = "terraform-google-modules/project-factory/google//modules/fabric-project"
  version         = "3.2.0"
  activate_apis   = var.project_services
  billing_account = var.billing_account_id
  name            = "svpc-host"
  oslogin_admins  = var.host_oslogin_admins
  owners          = var.host_owners
  parent          = var.root_node
  prefix          = var.prefix
}

module "net-vpc-host" {
  source  = "terraform-google-modules/network/google"
  version = "~> 1.1.0"

  project_id   = module.project-svc-host.project_id
  network_name = "vpc-host"

  subnets = var.subnets
  secondary_ranges = {
    subnet-01 = [
      {
        range_name    = "subnet-01-secondary-01"
        ip_cidr_range = "192.168.64.0/24"
      },
    ]

    subnet-02 = []
  }

  routes = [
    {
      name              = "egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    },
    {
      name                   = "app-proxy"
      description            = "route through proxy to reach app"
      destination_range      = "10.50.10.0/24"
      tags                   = "app-proxy"
      next_hop_instance      = "app-proxy-instance"
      next_hop_instance_zone = "us-west1-a"
    },
  ]
}
