# Copyright 2024 Google LLC
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

# requires fixtures/fixtures/compute-mig.tf

module "net-lb-app-int-cross-region" {
  source     = "./fabric/modules/net-lb-app-int-cross-region"
  name       = "ilb-test"
  project_id = var.project_id
  backend_service_configs = {
    default = {
      backends = [{
        group = module.compute-mig.group_manager.instance_group
      }]
    }
  }
  vpc_config = {
    network = var.vpc.self_link
    subnetworks = {
      (var.region) = var.subnet.self_link
    }
  }
}