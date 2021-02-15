/**
 * Copyright 2021 Google LLC
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
  source              = "../../../../modules/net-ilb"
  project_id          = "my-project"
  region              = "europe-west1"
  network             = "default"
  subnetwork          = "default"
  name                = "ilb-test"
  labels              = {}
  address             = var.address
  backends            = var.backends
  backend_config      = var.backend_config
  failover_config     = var.failover_config
  global_access       = var.global_access
  health_check        = var.health_check
  health_check_config = var.health_check_config
  ports               = var.ports
  protocol            = var.protocol
  service_label       = var.service_label
}
