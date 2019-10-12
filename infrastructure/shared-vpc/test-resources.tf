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

resource "google_compute_instance" "test-net" {
  project      = module.project-svpc-host.project_id
  name         = "test-net"
  machine_type = "f1-micro"
  zone         = "${local.net_subnet_regions.networking}-b"
  tags         = ["ssh"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network    = module.net-vpc-host.network_self_link
    subnetwork = local.net_subnet_links.networking
    access_config {}
  }
  metadata_startup_script = "apt update && apt install -y dnsutils"
}

resource "google_compute_instance" "test-gke" {
  project      = module.project-service-gke.project_id
  name         = "test-gke"
  machine_type = "f1-micro"
  zone         = "${local.net_subnet_regions.gke}-b"
  tags         = ["ssh"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network    = module.net-vpc-host.network_self_link
    subnetwork = local.net_subnet_links.gke
    access_config {}
  }
  metadata_startup_script = "apt update && apt install -y dnsutils"
}

resource "random_pet" "mysql_password" {}

module "container-vm_cos-mysql" {
  # source         = "terraform-google-modules/container-vm/google//modules/cos-mysql"
  # version        = "1.0.2"
  source         = "github.com/terraform-google-modules/terraform-google-container-vm//modules/cos-mysql"
  project_id     = module.project-service-gce.project_id
  region         = "${local.net_subnet_regions.gce}"
  zone           = "${local.net_subnet_regions.gce}-b"
  instance_count = "1"
  data_disk_size = "10"
  vm_tags        = ["ssh", "mysql"]
  password       = random_pet.mysql_password.id
  kms_data = {
    project_id = module.project-svpc-host.project_id
    keyring    = module.host-kms.keyring
    key        = "mysql"
    # TODO(ludomagno): add a location output to the keyring module
    location = var.kms_keyring_location
  }
  network    = module.net-vpc-host.network_self_link
  subnetwork = local.net_subnet_links.gke
}
