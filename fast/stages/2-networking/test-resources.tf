/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description temporary instances for testing, one per VPC per region.

################################################################################
#                                Test instances                                #
################################################################################

########################################
#               External               #
########################################

module "test-vm-external-primary-0" {
  source     = "../../../modules/compute-vm"
  project_id = module.net-project.project_id
  zone       = "${var.regions.primary}-b"
  name       = "test-vm-ext-pri-0"
  network_interfaces = [{
    network    = module.external-vpc.self_link
    subnetwork = module.external-vpc.subnet_self_links["${var.regions.primary}/prod-core-external-0-nva-primary"]
  }]
  tags                   = ["primary", "ssh"]
  service_account_create = true
  instance_type          = "e2-micro"
  boot_disk = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/debian-11"
      type  = "pd-balanced"
      size  = 10
    }
  }
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install iputils-ping bind9-dnsutils
    EOF
  }
}

module "test-vm-external-secondary-0" {
  source     = "../../../modules/compute-vm"
  project_id = module.net-project.project_id
  zone       = "${var.regions.secondary}-b"
  name       = "test-vm-ext-sec-0"
  network_interfaces = [{
    network    = module.external-vpc.self_link
    subnetwork = module.external-vpc.subnet_self_links["${var.regions.secondary}/prod-core-external-0-nva-secondary"]
  }]
  tags                   = ["secondary", "ssh"]
  service_account_create = true
  instance_type          = "e2-micro"
  boot_disk = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/debian-11"
      type  = "pd-balanced"
      size  = 10
    }
  }
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install iputils-ping bind9-dnsutils
    EOF
  }
}

########################################
#                 DMZ                  #
########################################

module "test-vm-dmz-primary-0" {
  source     = "../../../modules/compute-vm"
  project_id = module.net-project.project_id
  zone       = "${var.regions.primary}-b"
  name       = "test-vm-dmz-pri-0"
  network_interfaces = [{
    network    = module.dmz-vpc.self_link
    subnetwork = module.dmz-vpc.subnet_self_links["${var.regions.primary}/prod-core-dmz-0-nva-primary"]
  }]
  tags                   = ["primary", "ssh"]
  service_account_create = true
  instance_type          = "e2-micro"
  boot_disk = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/debian-11"
      type  = "pd-balanced"
      size  = 10
    }
  }
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install iputils-ping bind9-dnsutils
    EOF
  }
}

module "test-vm-dmz-secondary-0" {
  source     = "../../../modules/compute-vm"
  project_id = module.net-project.project_id
  zone       = "${var.regions.secondary}-b"
  name       = "test-vm-dmz-sec-0"
  network_interfaces = [{
    network    = module.dmz-vpc.self_link
    subnetwork = module.dmz-vpc.subnet_self_links["${var.regions.secondary}/prod-core-dmz-0-nva-secondary"]
  }]
  tags                   = ["secondary", "ssh"]
  service_account_create = true
  instance_type          = "e2-micro"
  boot_disk = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/debian-11"
      type  = "pd-balanced"
      size  = 10
    }
  }
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install iputils-ping bind9-dnsutils
    EOF
  }
}

########################################
#                Shared                #
########################################

module "test-vm-shared-primary-0" {
  source     = "../../../modules/compute-vm"
  project_id = module.net-project.project_id
  zone       = "${var.regions.primary}-b"
  name       = "test-vm-shared-pri-0"
  network_interfaces = [{
    network    = module.shared-vpc.self_link
    subnetwork = module.shared-vpc.subnet_self_links["${var.regions.primary}/prod-core-shared-0-nva-primary"]
  }]
  tags                   = [var.regions.primary, "ssh"]
  service_account_create = true
  instance_type          = "e2-micro"
  boot_disk = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/debian-11"
      type  = "pd-balanced"
      size  = 10
    }
  }
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install iputils-ping bind9-dnsutils
    EOF
  }
}

module "test-vm-shared-secondary-0" {
  source     = "../../../modules/compute-vm"
  project_id = module.net-project.project_id
  zone       = "${var.regions.secondary}-b"
  name       = "test-vm-shared-sec-0"
  network_interfaces = [{
    network    = module.shared-vpc.self_link
    subnetwork = module.shared-vpc.subnet_self_links["${var.regions.secondary}/prod-core-shared-0-nva-secondary"]
  }]
  tags                   = [var.regions.secondary, "ssh"]
  service_account_create = true
  instance_type          = "e2-micro"
  boot_disk = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/debian-11"
      type  = "pd-balanced"
      size  = 10
    }
  }
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install iputils-ping bind9-dnsutils
    EOF
  }
}

########################################
#           Transit primary            #
########################################

module "test-vm-transit-primary-0" {
  source     = "../../../modules/compute-vm"
  project_id = module.net-project.project_id
  zone       = "${var.regions.primary}-b"
  name       = "test-vm-transit-pri-0"
  network_interfaces = [{
    network    = module.transit-primary-vpc.self_link
    subnetwork = module.transit-primary-vpc.subnet_self_links["${var.regions.primary}/prod-core-transit-primary-0-nva"]
  }]
  tags                   = ["primary", "ssh"]
  service_account_create = true
  instance_type          = "e2-micro"
  boot_disk = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/debian-11"
      type  = "pd-balanced"
      size  = 10
    }
  }
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install iputils-ping bind9-dnsutils
    EOF
  }
}

########################################
#           Transit secondary          #
########################################

module "test-vm-transit-secondary-0" {
  source     = "../../../modules/compute-vm"
  project_id = module.net-project.project_id
  zone       = "${var.regions.secondary}-b"
  name       = "test-vm-transit-sec-0"
  network_interfaces = [{
    network    = module.transit-secondary-vpc.self_link
    subnetwork = module.transit-secondary-vpc.subnet_self_links["${var.regions.secondary}/prod-core-transit-secondary-0-nva"]
  }]
  tags                   = ["secondary", "ssh"]
  service_account_create = true
  instance_type          = "e2-micro"
  boot_disk = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/debian-11"
      type  = "pd-balanced"
      size  = 10
    }
  }
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install iputils-ping bind9-dnsutils
    EOF
  }
}
