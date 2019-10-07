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

output "hub" {
  value = {
    name = module.vpc-hub.network_name
    subnets = zipmap(
      module.vpc-hub.subnets_names,
      module.vpc-hub.subnets_ips
    )
    instances = zipmap(
      google_compute_instance.hub.*.name,
      google_compute_instance.hub.*.zone
    )
  }
}

output "spoke-1" {
  value = {
    name = module.vpc-spoke-1.network_name
    subnets = zipmap(
      module.vpc-spoke-1.subnets_names,
      module.vpc-spoke-1.subnets_ips
    )
    instances = zipmap(
      google_compute_instance.spoke-1.*.name,
      google_compute_instance.spoke-1.*.zone
    )
  }
}
output "spoke-2" {
  value = {
    name = module.vpc-spoke-2.network_name
    subnets = zipmap(
      module.vpc-spoke-2.subnets_names,
      module.vpc-spoke-2.subnets_ips
    )
    instances = zipmap(
      google_compute_instance.spoke-2.*.name,
      google_compute_instance.spoke-2.*.zone
    )
  }
}
