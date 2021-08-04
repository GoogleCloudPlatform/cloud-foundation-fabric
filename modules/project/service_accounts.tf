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

locals {
  service_account_cloud_services = "${local.project.number}@cloudservices.gserviceaccount.com"
  service_accounts_default = {
    compute = "${local.project.number}-compute@developer.gserviceaccount.com"
    gae     = "${local.project.project_id}@appspot.gserviceaccount.com"
  }
  service_accounts_robot_services = {
    bq                = "bigquery-encryption"
    cloudasset        = "gcp-sa-cloudasset"
    cloudbuild        = "gcp-sa-cloudbuild"
    compute           = "compute-system"
    container-engine  = "container-engine-robot"
    containerregistry = "containerregistry"
    dataflow          = "dataflow-service-producer-prod"
    dataproc          = "dataproc-accounts"
    gae-flex          = "gae-api-prod"
    gcf               = "gcf-admin-robot"
    pubsub            = "gcp-sa-pubsub"
    secretmanager     = "gcp-sa-secretmanager"
    storage           = "gs-project-accounts"
  }
  service_accounts_robots = {
    for service, name in local.service_accounts_robot_services :
    service => "${service == "bq" ? "bq" : "service"}-${local.project.number}@${name}.iam.gserviceaccount.com"
  }
  jit_services = [
    "secretmanager.googleapis.com",
    "pubsub.googleapis.com",
    "cloudasset.googleapis.com"
  ]
}

data "google_storage_project_service_account" "gcs_sa" {
  count      = contains(var.services, "storage.googleapis.com") ? 1 : 0
  project    = local.project.project_id
  depends_on = [google_project_service.project_services]
}

data "google_bigquery_default_service_account" "bq_sa" {
  count      = contains(var.services, "bigquery.googleapis.com") ? 1 : 0
  project    = local.project.project_id
  depends_on = [google_project_service.project_services]
}

# Secret Manager SA created just in time, we need to trigger the creation.
resource "google_project_service_identity" "jit_si" {
  for_each   = setintersection(var.services, local.jit_services)
  provider   = google-beta
  project    = local.project.project_id
  service    = each.value
  depends_on = [google_project_service.project_services]
}
