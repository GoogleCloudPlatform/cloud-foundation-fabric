# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = var.project_id
  name       = "fixture-net-vpc-external"
  ipv6_config = {
    enable_ula_internal = true
  }
  subnets = [
    {
      ip_cidr_range = "192.168.0.0/24"
      name          = "ipv6-external"
      region        = var.region
      ipv6 = {
        access_type = "EXTERNAL"
      }
    },
    {
      ip_cidr_range = "192.168.1.0/24"
      name          = "ipv6-internal"
      region        = var.region
      ipv6 = {
        access_type = "INTERNAL"
      }
    },
  ]
}