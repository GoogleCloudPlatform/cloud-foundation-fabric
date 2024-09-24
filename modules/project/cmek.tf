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

# tfdoc:file:description Service Agent IAM Bindings for CMEK

locals {
  # list of service agents per product that need to be granted
  # cryptoKeyEncrypterDecrypter to use CMEK.
  # https://cloud.google.com/kms/docs/compatible-services
  # TODO: extend to support dependencies for all products
  _cmek_agents_by_service = {
    "aiplatform.googleapis.com" : ["aiplatform"]
    "alloydb.googleapis.com" : ["alloydb"]
    "artifactregistry.googleapis.com" : ["artifactregistry"]
    "bigtableadmin.googleapis.com" : ["bigtable"]
    "bigquery.googleapis.com" : ["bigquery-encryption"]
    "composer.googleapis.com" : [
      "composer", "artifactregistry", "container-engine",
      "compute", "pubsub", "storage"
    ]
    "compute.googleapis.com" : ["compute"]
    "container.googleapis.com" : ["compute"]
    "dataflow.googleapis.com" : ["dataflow", "compute"]
    "dataform.googleapis.com" : ["dataform"]
    "datafusion.googleapis.com" : [
      "datafusion", "compute", "storage", "dataproc",
      "pubsub", "spanner" # these 2 are optional
    ]
    "dataproc.googleapis.com" : ["dataproc"]
    "datastream.googleapis.com" : ["datastream"]
    "dialogflow.googleapis.com" : ["dialogflow-cmek"]
    "file.googleapis.com" : ["cloud-filer"]
    "pubsub.googleapis.com" : ["pubsub"]
    "secretmanager.googleapis.com" : ["secretmanager"]
    "spanner.googleapis.com" : ["spanner"]
    "sqladmin.googleapis.com" : ["cloud-sql"]
    "storage.googleapis.com" : ["storage"]
    "run.googleapis.com" : ["cloudrun"]
  }
  _cmek_members = merge(flatten([
    for service, keys in var.service_encryption_key_ids : [
      # use the deps listed above, if the service does not appear
      # there, use all the service agents belonging to the service
      for dep in try(local._cmek_agents_by_service[service], [for x in local._service_agents_by_api[service] : x.name]) : {
        # use index in map key, to allow specyfing keys, that will be created in the same apply
        for index, key in keys :
        "key-${index}.${local._aliased_service_agents[dep].name}" => {
          key   = key
          agent = local._aliased_service_agents[dep].iam_email
        }
      }
    ]
  ])...)
}

resource "google_kms_crypto_key_iam_member" "service_agent_cmek" {
  for_each      = local._cmek_members
  crypto_key_id = each.value.key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = each.value.agent
  depends_on = [
    google_project.project,
    google_project_service.project_services,
    google_project_service_identity.default,
    google_project_iam_member.service_agents,
    data.google_project.project,
    data.google_bigquery_default_service_account.bq_sa,
    data.google_storage_project_service_account.gcs_sa,
  ]
}
