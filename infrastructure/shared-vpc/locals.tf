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

locals {
  net_data_users = concat(
    var.owners_data,
    [
      "serviceAccount:${module.project-service-data.cloudsvc_service_account}"
    ]
  )
  net_gke_users = concat(
    var.owners_gke,
    [
      "serviceAccount:${module.project-service-gke.gke_service_account}",
      "serviceAccount:${module.project-service-gke.cloudsvc_service_account}"
    ]
  )
  net_subnet_ips = zipmap(
    module.net-vpc-host.subnets_names,
    module.net-vpc-host.subnets_ips
  )
  net_subnet_regions = zipmap(
    module.net-vpc-host.subnets_names,
    module.net-vpc-host.subnets_regions
  )
}
