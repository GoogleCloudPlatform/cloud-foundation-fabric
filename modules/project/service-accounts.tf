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

# tfdoc:file:description Service identities and supporting resources.

locals {
  _service_accounts_cmek_service_dependencies = {
    "composer" : [
      "composer",
      "artifactregistry", "container-engine", "compute", "pubsub", "storage"
    ]
    "dataflow" : ["dataflow", "compute"]
  }
  _service_agents_data = yamldecode(file("${path.module}/service-agents.yaml"))
  service_accounts_default = {
    cloudbuild   = "${local.project.number}@cloudbuild.gserviceaccount.com"
    compute      = "${local.project.number}-compute@developer.gserviceaccount.com"
    gae          = "${local.project.project_id}@appspot.gserviceaccount.com"
    workstations = "service-${local.project.number}@gcp-sa-workstationsvm.iam.gserviceaccount.com"
  }
  service_account_cloud_services = (
    "${local.project.number}@cloudservices.gserviceaccount.com"
  )
  service_accounts_robots = merge(
    {
      for agent in local._service_agents_data :
      agent.name => format(agent.service_agent, local.project.number)
    },
    {
      for agent in local._service_agents_data :
      agent.alias => format(agent.service_agent, local.project.number)
      if lookup(agent, "alias", null) != null
    },
    {
      gke-mcs-importer = "${local.project.project_id}.svc.id.goog[gke-mcs/gke-mcs-importer]"
    }
  )
  service_accounts_jit_services = [
    for agent in local._service_agents_data :
    "${agent.name}.googleapis.com"
    if lookup(agent, "jit", false)
  ]
  service_accounts_cmek_service_keys = distinct(flatten([
    for s in keys(var.service_encryption_key_ids) : [
      for ss in try(local._service_accounts_cmek_service_dependencies[s], [s]) : [
        for key in var.service_encryption_key_ids[s] : {
          service = ss
          key     = key
        } if key != null
      ]
    ]
  ]))
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

resource "google_project_service_identity" "servicenetworking" {
  provider   = google-beta
  count      = contains(var.services, "servicenetworking.googleapis.com") ? 1 : 0
  project    = local.project.project_id
  service    = "servicenetworking.googleapis.com"
  depends_on = [google_project_service.project_services]
}

resource "google_project_iam_member" "servicenetworking" {
  count   = contains(var.services, "servicenetworking.googleapis.com") ? 1 : 0
  project = local.project.project_id
  role    = "roles/servicenetworking.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.servicenetworking[0].email}"
}

# Secret Manager SA created just in time, we need to trigger the creation.
resource "google_project_service_identity" "jit_si" {
  for_each   = setintersection(var.services, local.service_accounts_jit_services)
  provider   = google-beta
  project    = local.project.project_id
  service    = each.value
  depends_on = [google_project_service.project_services]
}

resource "google_kms_crypto_key_iam_member" "service_identity_cmek" {
  for_each = {
    for service_key in local.service_accounts_cmek_service_keys :
    "${service_key.service}.${service_key.key}" => service_key
    if service_key != service_key.key
  }
  crypto_key_id = each.value.key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${local.service_accounts_robots[each.value.service]}"
  depends_on = [
    google_project.project,
    google_project_service.project_services,
    google_project_service_identity.jit_si,
    data.google_bigquery_default_service_account.bq_sa,
    data.google_project.project,
    data.google_storage_project_service_account.gcs_sa,
  ]
}

resource "google_project_default_service_accounts" "default_service_accounts" {
  count          = upper(var.default_service_account) == "KEEP" ? 0 : 1
  action         = upper(var.default_service_account)
  project        = local.project.project_id
  restore_policy = "REVERT_AND_IGNORE_FAILURE"
  depends_on     = [google_project_service.project_services]
}
