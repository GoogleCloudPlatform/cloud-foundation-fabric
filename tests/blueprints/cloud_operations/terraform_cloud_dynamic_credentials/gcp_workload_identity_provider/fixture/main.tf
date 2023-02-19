/**
 * Copyright 2023 Google LLC
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
  source                             = "../../../../../../blueprints/cloud-operations/terraform-cloud-dynamic-credentials/gcp-workload-identity-provider"
  billing_account                    = var.billing_account
  project_create                     = var.project_create
  project_id                         = var.project_id
  parent                             = var.parent
  tfc_organization_id                = var.tfc_organization_id
  tfc_workspace_id                   = var.tfc_workspace_id
  workload_identity_pool_id          = var.workload_identity_pool_id
  workload_identity_pool_provider_id = var.workload_identity_pool_provider_id
  issuer_uri                         = var.issuer_uri
}
