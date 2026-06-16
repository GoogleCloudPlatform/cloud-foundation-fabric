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

name       = "lb-test"
project_id = "$project_ids:foo"

vpc_config = {
  network = "$networks:bar"
  subnetworks = {
    europe-west1 = "$subnets:ew1"
    europe-west4 = "$subnets:ew4"
  }
}

addresses = {
  europe-west1 = "$addresses:ip1"
}

service_attachment = {
  nat_subnets = {
    europe-west1 = ["$subnets:ew1"]
    europe-west4 = ["$subnets:ew4"]
  }
}

group_configs = {
  default = {
    zone = "$locations:ew1-z"
  }
}

neg_configs = {
  psc-neg = {
    psc = {
      region         = "$locations:ew1"
      target_service = "projects/resolved-project/regions/europe-west1/serviceAttachments/sa"
      network        = "$networks:bar"
      subnetwork     = "$subnets:psc"
    }
  }
}

context = {
  project_ids = {
    foo = "resolved-project"
  }
  locations = {
    ew1   = "europe-west1"
    ew4   = "europe-west4"
    ew1-z = "europe-west1-b"
  }
  networks = {
    bar = "resolved-network"
  }
  subnets = {
    ew1 = "resolved-subnet-ew1"
    ew4 = "resolved-subnet-ew4"
    psc = "resolved-subnet-psc"
  }
  addresses = {
    ip1 = "10.0.0.1"
  }
}
