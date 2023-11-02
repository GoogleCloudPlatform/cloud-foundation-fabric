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

# tfdoc:file:description VPC resources.

# VPC in main project
module "vpc-main" {
  source     = "../../../modules/net-vpc"
  project_id = module.main-project.project_id
  name       = "vpc-main"
  subnets = [
    { # regular subnet
      ip_cidr_range = var.ip_configs.subnet_main
      name          = "subnet-main"
      region        = var.region
    },
    { # subnet for VPC access connector
      ip_cidr_range = var.ip_configs.subnet_vpc_access
      name          = "subnet-vpc-access"
      region        = var.region
    },
    { # subnet for Direct VPC Egress
      ip_cidr_range = var.ip_configs.subnet_vpc_direct
      name          = "subnet-vpc-direct"
      region        = var.region
    }
  ]
  subnets_proxy_only = [
    { # subnet for internal ALB
      ip_cidr_range = var.ip_configs.subnet_proxy
      name          = "subnet-proxy"
      region        = var.region
      active        = true
    }
  ]
}
