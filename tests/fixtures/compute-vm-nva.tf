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


module "compute-vm-primary-b" {
  source         = "./fabric/modules/compute-vm"
  project_id     = var.project_id
  zone           = "${var.regions.primary}-b"
  name           = "test-primary-b"
  can_ip_forward = true
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnets.primary.self_link
  }]
}

module "compute-vm-primary-c" {
  source         = "./fabric/modules/compute-vm"
  project_id     = var.project_id
  zone           = "${var.regions.primary}-c"
  name           = "test-primary-c"
  can_ip_forward = true
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnets.primary.self_link
  }]
}


module "compute-vm-secondary-b" {
  source         = "./fabric/modules/compute-vm"
  project_id     = var.project_id
  zone           = "${var.regions.secondary}-b"
  name           = "test-secondary-b"
  can_ip_forward = true
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnets.secondary.self_link
  }]
}

module "compute-vm-secondary-c" {
  source         = "./fabric/modules/compute-vm"
  project_id     = var.project_id
  zone           = "${var.regions.secondary}-c"
  name           = "test-secondary-c"
  can_ip_forward = true
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnets.secondary.self_link
  }]
}
