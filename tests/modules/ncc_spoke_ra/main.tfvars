# Copyright 2026 Google LLC
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

project_id = "test-project"
region     = "europe-west1"
name       = "spoke-ra"

hub = {
  create = true
  name   = "ncc-hub"
}

router_appliances = [
  {
    internal_ip  = "10.0.16.10"
    vm_self_link = "https://www.googleapis.com/compute/v1/projects/test-project/zones/europe-west1-b/instances/nva-vm"
  }
]

router_config = {
  asn           = 65000
  ip_interface0 = "10.0.16.14"
  ip_interface1 = "10.0.16.15"
  peer_asn      = 65001
}

vpc_config = {
  network_name     = "projects/test-project/global/networks/test-vpc"
  subnet_self_link = "projects/test-project/regions/europe-west1/subnetworks/test-subnetwork"
}
