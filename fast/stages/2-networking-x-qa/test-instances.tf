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

module "test-vm-untrusted-0" {
  source     = "../../../modules/compute-vm"
  project_id = module.hub-project.project_id
  zone       = "${var.region}-a"
  name       = "test-vm-untrusted-0"
  network_interfaces = [{
    network    = module.hub-untrusted-vpc.self_link
    subnetwork = module.hub-untrusted-vpc.subnet_self_links["${var.region}/untrusted"]
  }]
  instance_type          = "e2-micro"
  tags                   = ["ssh", "http-server"]
  service_account_create = true
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install iputils-ping 	bind9-dnsutils
    EOF
  }
}

module "test-vm-dmz-0" {
  source     = "../../../modules/compute-vm"
  project_id = module.hub-project.project_id
  zone       = "${var.region}-a"
  name       = "test-vm-dmz-0"
  network_interfaces = [{
    network    = module.hub-dmz-vpc.self_link
    subnetwork = module.hub-dmz-vpc.subnet_self_links["${var.region}/dmz"]
  }]
  instance_type          = "e2-micro"
  tags                   = ["ssh", "http-server"]
  service_account_create = true
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install iputils-ping 	bind9-dnsutils
    EOF
  }
}

module "test-vm-inside-0" {
  source     = "../../../modules/compute-vm"
  project_id = module.hub-project.project_id
  zone       = "${var.region}-a"
  name       = "test-vm-inside-0"
  network_interfaces = [{
    network    = module.hub-inside-vpc.self_link
    subnetwork = module.hub-inside-vpc.subnet_self_links["${var.region}/inside"]
  }]
  instance_type          = "e2-micro"
  tags                   = ["ssh", "http-server"]
  service_account_create = true
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install iputils-ping 	bind9-dnsutils
    EOF
  }
}

module "test-vm-prod-0" {
  source     = "../../../modules/compute-vm"
  project_id = module.prod-project.project_id
  zone       = "${var.region}-a"
  name       = "test-vm-inside-0"
  network_interfaces = [{
    network    = module.prod-vpc.self_link
    subnetwork = module.prod-vpc.subnet_self_links["${var.region}/prod-default"]
  }]
  instance_type          = "e2-micro"
  tags                   = ["ssh", "http-server"]
  service_account_create = true
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install iputils-ping 	bind9-dnsutils
    EOF
  }
}


