/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# tfdoc:file:description Management server.

module "mgmt_server" {
  source        = "../../../modules/compute-vm"
  project_id    = module.project.project_id
  zone          = var.zone
  name          = "mgmt"
  instance_type = var.mgmt_server_config.instance_type
  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/subnet-mgmt"]
    nat        = false
    addresses  = null
  }]
  service_account = {
    auto_create = true
  }
  boot_disk = {
    initialize_params = {
      image = var.mgmt_server_config.image
      type  = var.mgmt_server_config.disk_type
      size  = var.mgmt_server_config.disk_size
    }
  }
  metadata = {
    startup-script = <<EOT
#!/bin/bash
apt update -y
apt install python3-pip -y
pip3 install kubernetes
EOT
  }
}
