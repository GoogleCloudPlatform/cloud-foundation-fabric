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
  source     = "../../../../modules/net-ilb-l7"
  project_id = "my-project"
  name       = "ilb-l7-test"
  region     = "europe-west1"
  vpc_config = {
    network    = "projects/my-project/global/networks/default"
    subnetwork = "projects/my-project/regions/europe-west1/subnetworks/default"
  }
  address                 = var.address
  backend_service_configs = var.backend_service_configs
  description             = var.description
  group_configs           = var.group_configs
  health_check_configs    = var.health_check_configs
  labels                  = var.labels
  neg_configs             = var.neg_configs
  network_tier_premium    = var.network_tier_premium
  ports                   = var.ports
  protocol                = var.protocol
  ssl_certificates        = var.ssl_certificates
  urlmap_config           = var.urlmap_config
}
