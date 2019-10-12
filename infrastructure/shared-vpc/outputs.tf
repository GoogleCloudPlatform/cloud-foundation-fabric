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

output "net-vpc-name" {
  description = "Shared VPC name"
  value       = module.net-vpc-host.network_name
}

output "net-vpc-subnets" {
  description = "Shared VPC subnets."
  value       = local.net_subnet_ips
}

output "project-host" {
  description = "VPC host project."
  value = {
    project_id     = module.project-svpc-host.project_id
    project_number = module.project-svpc-host.number
  }
}

output "project-gce" {
  description = "GCE service project."
  value = {
    project_id     = module.project-service-gce.project_id
    project_number = module.project-service-gce.number
  }
}

output "project-gke" {
  description = "GKE service project."
  value = {
    project_id     = module.project-service-gke.project_id
    project_number = module.project-service-gke.number
  }
}

# test resource outputs, comment if you don't need them

output "test-instances" {
  description = "Test instance names."
  value = {
    gke = map(
      google_compute_instance.test-gke.name,
      google_compute_instance.test-gke.network_interface.0.network_ip
    )
    mysql = module.container-vm_cos-mysql.instances
    networking = map(
      google_compute_instance.test-net.name,
      google_compute_instance.test-net.network_interface.0.network_ip
    )
  }
}

output "mysql-root-password" {
  description = "Password for the test MySQL db root user."
  sensitive   = true
  value       = random_pet.mysql_password.id
}
