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

project_id = "$project_ids:my-project-ctx"
region     = "$locations:europe-west1-ctx"
name       = "nlb-test"
backends = [{
  group    = "foo"
  failover = false
}]

context = {
  project_ids = {
    my-project-ctx = "resolved-project"
  }
  locations = {
    europe-west1-ctx = "resolved-region"
  }
  addresses = {
    my-address = "1.2.3.4"
  }
  subnets = {
    my-subnet = "https://www.googleapis.com/compute/v1/projects/resolved-project/regions/resolved-region/subnetworks/resolved-subnet"
  }
}

forwarding_rules_config = {
  rule1 = {
    address    = "$addresses:my-address"
    subnetwork = "$subnets:my-subnet"
    protocol   = "TCP"
    ports      = ["80"]
  }
}
