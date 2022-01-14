# Copyright 2022 Google LLC
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
  vm-startup-script = join("\n", [
    "#! /bin/bash",
    "apt-get update && apt-get install -y bash-completion git python3-venv gcc build-essential python-dev python3-dev",
    "pip3 install --upgrade setuptools pip"
  ])
}

module "vm" {
  source     = "../../../modules/compute-vm"
  project_id = module.project.project_id
  zone       = "${var.region}-b"
  name       = "${var.prefix}-vm-0"
  network_interfaces = [{
    network    = module.vpc.self_link,
    subnetwork = local.subnet_self_link,
    nat        = false,
    addresses  = null
  }]
  attached_disks = [{
    name = "data", size = 10, source = null, source_type = null, options = null
  }]
  boot_disk = {
    image        = "projects/debian-cloud/global/images/family/debian-10"
    type         = "pd-ssd"
    size         = 10
    encrypt_disk = true
  }
  encryption = {
    encrypt_boot            = true
    disk_encryption_key_raw = null
    kms_key_self_link       = module.kms.key_ids.key-gce
  }
  metadata = {
    startup-script = local.vm-startup-script
  }
  service_account        = module.service-account-gce.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  tags                   = ["ssh"]
}
