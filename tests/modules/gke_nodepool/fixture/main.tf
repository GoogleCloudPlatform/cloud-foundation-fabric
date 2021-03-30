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
  source                      = "../../../../modules/gke-nodepool"
  project_id                  = "my-project"
  cluster_name                = "cluster-1"
  location                    = "europe-west1-b"
  name                        = "nodepool-1"
  node_service_account        = var.node_service_account
  node_service_account_create = var.node_service_account_create
  node_service_account_scopes = var.node_service_account_scopes
}
