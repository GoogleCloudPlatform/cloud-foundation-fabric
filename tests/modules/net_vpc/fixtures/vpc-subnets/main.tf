/**
 * Copyright 2019 Google LLC
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

variable "project_id" {
  description = "Project id used for this fixture."
  type        = string
}

variable "subnets" {
  description = "Subnet definitions."
  default = {
    subnet-simple = {
      ip_cidr_range      = "192.168.0.0/24"
      region             = "europe-west1"
      secondary_ip_range = {}
    },
    subnet-options = {
      ip_cidr_range      = "192.168.1.0/24"
      region             = "europe-west2"
      secondary_ip_range = {}
    },
    subnet-alias-ranges = {
      ip_cidr_range = "192.168.2.0/24"
      region        = "europe-west1"
      secondary_ip_range = {
        alias-1 = "172.16.10.0/24"
        alias-2 = "172.16.20.0/24"
      }
    }
  }
}

variable "subnet_descriptions" {
  default = {
    subnet-options      = "Simple subnet with options."
    subnet-alias-ranges = "Simple subnet with alias ranges."
  }
}

variable "subnet_flow_logs" {
  default = {
    subnet-options      = true
    subnet-alias-ranges = true
  }
}

variable "subnet_private_access" {
  default = {
    subnet-simple  = false
    subnet-options = true
  }
}

variable "log_configs" {
  description = "Logging configurations."
  default = {
    subnet-alias-ranges = {
      flow_sampling = 0.75
    }
  }
}

module "vpc" {
  source                = "../../../../../modules/net-vpc"
  project_id            = var.project_id
  name                  = "vpc-subnets"
  description           = "Created by the vpc-subnets fixture."
  routing_mode          = "REGIONAL"
  subnets               = var.subnets
  subnet_descriptions   = var.subnet_descriptions
  subnet_flow_logs      = var.subnet_flow_logs
  subnet_private_access = var.subnet_private_access
  log_configs           = var.log_configs
}

output "network" {
  description = "Network resource."
  value       = module.vpc.network
}

output "subnets" {
  description = "Subnet resources."
  value       = module.vpc.subnets
}

output "subnet_ips" {
  description = "Map of subnet address ranges keyed by name."
  value       = module.vpc.subnet_ips
}

output "subnet_regions" {
  description = "Map of subnet regions keyed by name."
  value       = module.vpc.subnet_regions
}

output "subnet_secondary_ranges" {
  description = "Map of subnet secondary ranges keyed by name."
  value       = module.vpc.subnet_secondary_ranges
}
