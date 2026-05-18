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

context = {
  addresses = {
    test = "10.0.0.10"
  }
  locations = {
    ew8 = "europe-west8"
  }
  networks = {
    test = "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
  project_ids = {
    test = "foo-test-0"
  }
  subnets = {
    test     = "projects/foo-dev-net-spoke-0/regions/europe-west8/subnetworks/gce"
    test-nat = "projects/foo-dev-net-spoke-0/regions/europe-west8/subnetworks/test-nat"
  }
  project_ids = {
    test = "foo-test-0"
  }
}
project_id = "$project_ids:test"
region     = "$locations:ew8"
name       = "test"
vpc_config = {
  network    = "$networks:test"
  subnetwork = "$subnets:test"
}
backends = [{
  group    = "foo"
  failover = false
}]
forwarding_rules_config = {
  "" = {
    address = "$addresses:test"
  }
}
service_attachments = {
  "" = {
    nat_subnets = ["$subnets:test-nat"]
  }
}
