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
  # GCE service project users that need the network user role assigned on host
  net_gce_users = concat(
    var.owners_gce,
    ["serviceAccount:${module.project-service-gce.cloudsvc_service_account}"]
  )
  # GKE service project users that need the network user role assigned on host
  net_gke_users = concat(
    var.owners_gke,
    [
      "serviceAccount:${module.project-service-gke.gke_service_account}",
      "serviceAccount:${module.project-service-gke.cloudsvc_service_account}"
    ]
  )
  # GKE subnet primary and secondary ranges, used in firewall rules
  # use lookup to prevent failure on successive destroys
  net_gke_ip_ranges = compact([
    lookup(local.net_subnet_ips, "gke", ""),
    element([
      for range in lookup(var.subnet_secondary_ranges, "gke", []) :
      range.ip_cidr_range if range.range_name == "pods"
    ], 0)
  ])
  # map of subnet names => addresses
  net_subnet_ips = zipmap(
    module.net-vpc-host.subnets_names,
    module.net-vpc-host.subnets_ips
  )
  # map of subnet names => links
  net_subnet_links = zipmap(
    module.net-vpc-host.subnets_names,
    module.net-vpc-host.subnets_self_links
  )
  # map of subnet names => regions
  net_subnet_regions = zipmap(
    module.net-vpc-host.subnets_names,
    module.net-vpc-host.subnets_regions
  )
  # use svpc access module outputs to create an implicit dependency on service project registration
  service_projects = zipmap(
    module.net-svpc-access.service_projects,
    module.net-svpc-access.service_projects
  )
}
