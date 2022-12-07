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
 
resource "google_iam_workload_identity_pool" "github_pool" {
  count                     = var.workload_identity == null ? 0 : 1
  provider                  = google-beta
  project                   = module.project.project_id
  workload_identity_pool_id = "gh-pool"
  display_name              = "Github Actions Identity Pool"
  description               = "Identity pool for Github Actions"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  count                              = var.workload_identity == null ? 0 : 1
  provider                           = google-beta
  project                            = module.project.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "gh-provider"
  display_name                       = "Github Actions provider"
  description                        = "OIDC provider for Github Actions"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}


resource "google_service_account_iam_member" "sa-gh-roles" {
  count              = var.workload_identity == null ? 0 : 1
  service_account_id = module.service-accounts["sa-github"].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool[0].name}/${var.workload_identity.identity_pool_claims}"
}


module "artifact_registry" {
  for_each   = var.artifact_registry
  source     = "../../../../../modules/artifact-registry"
  id         = each.key
  project_id = module.project.project_id
  location   = each.value.region
  format     = each.value.format
  #  iam = {
  #    "roles/artifactregistry.admin" = ["group:cicd@example.com"]
  #  }
}