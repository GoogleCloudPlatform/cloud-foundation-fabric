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
  source                 = "../../../../../blueprints/gke/multi-cluster-mesh-gke-fleet-api"
  billing_account_id     = var.billing_account_id
  parent                 = var.parent
  host_project_id        = var.host_project_id
  fleet_project_id       = var.fleet_project_id
  mgmt_project_id        = var.mgmt_project_id
  region                 = var.region
  clusters_config        = var.clusters_config
  mgmt_subnet_cidr_block = var.mgmt_subnet_cidr_block
  istio_version          = var.istio_version
}
