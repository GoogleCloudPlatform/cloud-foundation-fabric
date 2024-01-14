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


module "compute-vm-group-b" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-b"
  name       = "my-ig-b"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  boot_disk = {
    initialize_params = {
      image = "cos-cloud/cos-stable"
    }
  }
  group = { named_ports = {} }
}

module "compute-vm-group-c" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  zone       = "${var.region}-c"
  name       = "my-ig-c"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }]
  boot_disk = {
    initialize_params = {
      image = "cos-cloud/cos-stable"
    }
  }
  group = { named_ports = {} }
}
