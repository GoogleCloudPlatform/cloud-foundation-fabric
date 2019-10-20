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

output "vpc_name" {
  description = "Shared VPC name"
  value       = module.net-vpc-host.network_name
}

output "vpc_subnets" {
  description = "Shared VPC subnets."
  value       = local.net_subnet_ips
}

output "host_project_id" {
  description = "VPC host project id."
  value       = module.project-svpc-host.project_id
}

output "service_project_ids" {
  description = "Service project ids."
  value = {
    gce = module.project-service-gce.project_id
    gke = module.project-service-gke.project_id
  }
}
