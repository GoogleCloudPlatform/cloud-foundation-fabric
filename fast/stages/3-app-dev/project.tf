/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description Project and usage dataset.

module "gke-project-0" {
  source          = "../../../modules/project"
  name            = local.project_name
  project_reuse = {
    use_data_source = false
    attributes = {
      name   = local.project_name
      number = "405419313060"
    }
  }
  iam_bindings_additive = {
    for r in local.gke_nodes_sa_roles : "gke-nodes-sa-${r}" => {
      member = module.gke-nodes-service-account.iam_email
      role   = "roles/${r}"
    }
  }
  services = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "pubsub.googleapis.com",
  ]
  service_encryption_key_ids = local.service_encryption_key_ids
}
