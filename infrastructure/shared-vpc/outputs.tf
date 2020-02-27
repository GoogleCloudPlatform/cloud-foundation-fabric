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

output "gke_clusters" {
  description = "GKE clusters information."
  value = {
    cluster-1 = module.cluster-1.endpoint
  }
}

output "projects" {
  description = "Project ids."
  value = {
    host        = module.project-host.project_id
    service-gce = module.project-svc-gce.project_id
    service-gke = module.project-svc-gke.project_id
  }
}

output "service_accounts" {
  description = "GCE and GKE service accounts."
  value = {
    bastion  = module.vm-bastion.service_account_email
    gke_node = module.service-account-gke-node.email
  }
}

output "vpc" {
  description = "Shared VPC."
  value = {
    name    = module.vpc-shared.name
    subnets = module.vpc-shared.subnet_ips
  }
}

output "vms" {
  description = "GCE VMs."
  value = {
    for instance in concat(module.vm-bastion.instances) :
    instance.name => instance.network_interface.0.network_ip
  }
}
