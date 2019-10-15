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

###############################################################################
#                         host test VM and DNS record                         #
###############################################################################

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
  metadata_startup_script = "apt update && apt install -y dnsutils mysql-client"
}

resource "google_dns_record_set" "test_net" {
  project      = module.project-svpc-host.project_id
  name         = "test-net.${module.host-dns.domain}"
  type         = "A"
  ttl          = 300
  managed_zone = module.host-dns.name
  rrdatas = [
    google_compute_instance.test-net.network_interface.0.network_ip
  ]
}

###############################################################################
#                      GKE project test VM and DNS record                     #
###############################################################################

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
  metadata_startup_script = "apt update && apt install -y dnsutils mysql-client"
}

resource "google_dns_record_set" "test_gke" {
  project      = module.project-svpc-host.project_id
  name         = "test-gke.${module.host-dns.domain}"
  type         = "A"
  ttl          = 300
  managed_zone = module.host-dns.name
  rrdatas = [
    google_compute_instance.test-gke.network_interface.0.network_ip
  ]
}

###############################################################################
#                   GCE project MySQL test VM and DNS record                  #
###############################################################################

# random password for MySQL

resource "random_pet" "mysql_password" {}

# MySQL password encrypted via KMS key

data "google_kms_secret_ciphertext" "mysql_password" {
  crypto_key = module.host-kms.keys.mysql
  plaintext  = random_pet.mysql_password.id
}

# work around the encrypted password always refreshing, taint to refresh

resource "null_resource" "mysql_password" {
  triggers = {
    ciphertext = data.google_kms_secret_ciphertext.mysql_password.ciphertext
  }
  lifecycle {
    ignore_changes = [triggers]
  }
}

# MySQL container on Container Optimized OS

module "container-vm_cos-mysql" {
  # source         = "terraform-google-modules/container-vm/google//modules/cos-mysql"
  # version        = "1.0.4"
  source         = "github.com/terraform-google-modules/terraform-google-container-vm//modules/cos-mysql?ref=a8c693d"
  project_id     = module.project-service-gce.project_id
  region         = "${lookup(local.net_subnet_regions, "gce", "")}"
  zone           = "${lookup(local.net_subnet_regions, "gce", "")}-b"
  network        = module.net-vpc-host.network_self_link
  subnetwork     = lookup(local.net_subnet_links, "gke", "")
  instance_count = "1"
  data_disk_size = "10"
  vm_tags        = ["ssh", "mysql"]
  password       = null_resource.mysql_password.triggers.ciphertext
  # TODO(ludomagno): add a location output to the keyring module
  kms_data = {
    key        = "mysql"
    keyring    = module.host-kms.keyring_name
    location   = var.kms_keyring_location
    project_id = module.project-svpc-host.project_id
  }
}

resource "google_dns_record_set" "mysql" {
  project      = module.project-svpc-host.project_id
  name         = "mysql.${module.host-dns.domain}"
  type         = "A"
  ttl          = 300
  managed_zone = module.host-dns.name
  rrdatas = [
    values(module.container-vm_cos-mysql.instances)[0]
  ]
}

###############################################################################
#                                 test outputs                                #
###############################################################################

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
