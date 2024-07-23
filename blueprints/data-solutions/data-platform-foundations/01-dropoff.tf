# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description drop off project and resources.

locals {
  drp_iam = {
    data_engineers = [
      "roles/bigquery.dataEditor",
      "roles/bigquery.user"
    ]
    sa_drop_bq = [
      "roles/bigquery.dataEditor"
    ]
    sa_drop_cs = [
      "roles/storage.objectCreator"
    ]
    sa_drop_ps = [
      "roles/pubsub.publisher"
    ]
    sa_load = [
      "roles/bigquery.user",
      "roles/pubsub.subscriber",
      "roles/storage.objectAdmin"
    ]
    sa_orch = [
      "roles/pubsub.subscriber",
      "roles/storage.objectViewer"
    ]
  }
}

module "drop-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.project_create
  prefix          = local.use_projects ? null : var.prefix
  name = (
    local.use_projects
    ? var.project_config.project_ids.drop
    : "${var.project_config.project_ids.drop}${local.project_suffix}"
  )
  iam                   = local.use_projects ? {} : local.drp_iam_auth
  iam_bindings_additive = !local.use_projects ? {} : local.drp_iam_additive
  services = concat(var.project_services, [
    "bigquery.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudkms.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com",
  ])
  service_encryption_key_ids = {
    "bigquery.googleapis.com" = compact([var.service_encryption_keys.bq])
    "pubsub.googleapis.com"   = compact([var.service_encryption_keys.pubsub])
    "storage.googleapis.com"  = compact([var.service_encryption_keys.storage])
  }
}

module "drop-sa-cs-0" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.drop-project.project_id
  prefix       = var.prefix
  name         = "drp-cs-0"
  display_name = "Data platform GCS drop off service account."
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers
    ]
  }
}

module "drop-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.drop-project.project_id
  prefix         = var.prefix
  name           = "drp-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = var.service_encryption_keys.storage
  force_destroy  = !var.deletion_protection
  # retention_policy = {
  #   retention_period = 7776000 # 90 * 24 * 60 * 60
  #   is_locked        = false
  # }
}

module "drop-sa-ps-0" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.drop-project.project_id
  prefix       = var.prefix
  name         = "drp-ps-0"
  display_name = "Data platform PubSub drop off service account"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers
    ]
  }
}

module "drop-ps-0" {
  source     = "../../../modules/pubsub"
  project_id = module.drop-project.project_id
  name       = "${var.prefix}-drp-ps-0"
  kms_key    = var.service_encryption_keys.pubsub
}

module "drop-sa-bq-0" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.drop-project.project_id
  prefix       = var.prefix
  name         = "drp-bq-0"
  display_name = "Data platform BigQuery drop off service account"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [local.groups_iam.data-engineers]
  }
}

module "drop-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.drop-project.project_id
  id             = "${replace(var.prefix, "-", "_")}_drp_bq_0"
  location       = var.location
  encryption_key = var.service_encryption_keys.bq
}
