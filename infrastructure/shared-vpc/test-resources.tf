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

resource "google_compute_instance" "instance-gce-project" {
  project      = module.project-service-gce.project_id
  name         = "test-gce"
  machine_type = "f1-micro"
  zone         = "${local.net_subnet_regions.gce}-b"
  tags         = ["ssh"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network    = module.net-vpc-host.network_self_link
    subnetwork = local.net_subnet_links.gce
    access_config {}
  }
  metadata_startup_script = "apt update && apt install -y dnsutils"
}
