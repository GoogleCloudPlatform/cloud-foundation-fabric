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

module "test" {
  source     = "../../../../modules/net-ilb"
  project_id = "my-project"
  region     = "europe-west1"
  name       = "ilb-test"
  vpc_config = {
    network    = "default"
    subnetwork = "default"
  }
  address                = var.address
  backend_service_config = var.backend_service_config
  backends               = var.backends
  description            = var.description
  global_access          = var.global_access
  group_configs          = var.group_configs
  ports                  = var.ports
  protocol               = var.protocol
  service_label          = var.service_label
}
