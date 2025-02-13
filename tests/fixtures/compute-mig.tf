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

module "_instance-template" {
  source     = "./fabric/modules/compute-vm"
  project_id = var.project_id
  name       = "mig-e2e-template"
  zone       = "${var.region}-b"
  tags       = ["http-server", "ssh"]
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = false
    addresses  = null
  }]
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }
  create_template = true
}

module "compute-mig" {
  source     = "./fabric/modules/compute-mig"
  project_id = var.project_id
  location   = "${var.region}-b"
  name       = "mig-e2e-tests"
  # target_size       = 0
  instance_template = module._instance-template.template.self_link
}
