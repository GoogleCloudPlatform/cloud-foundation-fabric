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

resource "google_compute_instance" "hub" {
  count        = length(var.hub_subnets)
  project      = var.hub_project_id
  name         = "${var.prefix}-hub-${element(var.hub_subnets, count.index)["subnet_name"]}"
  machine_type = "f1-micro"
  zone         = "${element(local.hub_subnet_regions, count.index)}-b"
  tags         = ["ssh"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    subnetwork    = element(module.vpc-hub.subnets_self_links, count.index)
    access_config {}
  }
}

resource "google_compute_instance" "spoke-1" {
  count        = length(var.spoke_1_subnets)
  project      = var.spoke_1_project_id
  name         = "${var.prefix}-spoke-1-${element(var.spoke_1_subnets, count.index)["subnet_name"]}"
  machine_type = "f1-micro"
  zone         = "${element(local.spoke_1_subnet_regions, count.index)}-b"
  tags         = ["ssh"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    subnetwork    = element(module.vpc-spoke-1.subnets_self_links, count.index)
    access_config {}
  }
}

resource "google_compute_instance" "spoke-2" {
  count        = length(var.spoke_2_subnets)
  project      = var.spoke_2_project_id
  name         = "${var.prefix}-spoke-2-${element(var.spoke_2_subnets, count.index)["subnet_name"]}"
  machine_type = "f1-micro"
  zone         = "${element(local.spoke_2_subnet_regions, count.index)}-b"
  tags         = ["ssh"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    subnetwork    = element(module.vpc-spoke-2.subnets_self_links, count.index)
    access_config {}
  }
}
