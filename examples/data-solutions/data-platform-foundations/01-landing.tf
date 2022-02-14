# Copyright 2022 Google LLC
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

# tfdoc:file:description land project and resources.

locals {
  land_orch_service_accounts = [
    module.load-sa-df-0.iam_email, module.orch-sa-cmp-0.iam_email
  ]
}

module "land-project" {
  source          = "../../../modules/project"
  parent          = var.folder_id
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "lnd"
  group_iam = {
    (local.groups.data-engineers) = [
      "roles/bigquery.dataEditor",
      "roles/pubsub.editor",
      "roles/storage.admin",
    ]
  }
  iam = {
    "roles/bigquery.dataEditor" = [module.land-sa-bq-0.iam_email]
    "roles/bigquery.user"       = [module.load-sa-df-0.iam_email]
    "roles/pubsub.publisher"    = [module.land-sa-ps-0.iam_email]
    "roles/pubsub.subscriber" = concat(
      local.land_orch_service_accounts, [module.load-sa-df-0.iam_email]
    )
    "roles/storage.objectAdmin"   = [module.load-sa-df-0.iam_email]
    "roles/storage.objectCreator" = [module.land-sa-cs-0.iam_email]
    "roles/storage.objectViewer"  = [module.orch-sa-cmp-0.iam_email]
    "roles/storage.admin"         = [module.load-sa-df-0.iam_email]
  }
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
    bq      = [try(local.service_encryption_keys.bq, null)]
    pubsub  = [try(local.service_encryption_keys.pubsub, null)]
    storage = [try(local.service_encryption_keys.storage, null)]
  }
}

# Cloud Storage

module "land-sa-cs-0" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.land-project.project_id
  prefix       = var.prefix
  name         = "lnd-cs-0"
  display_name = "Data platform GCS landing service account."
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers
    ]
  }
}

module "land-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.land-project.project_id
  prefix         = var.prefix
  name           = "lnd-cs-0"
  location       = var.location
  storage_class  = "MULTI_REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage, null)
  force_destroy  = var.data_force_destroy
  # retention_policy = {
  #   retention_period = 7776000 # 90 * 24 * 60 * 60
  #   is_locked        = false
  # }
}

# PubSub

module "land-sa-ps-0" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.land-project.project_id
  prefix       = var.prefix
  name         = "lnd-ps-0"
  display_name = "Data platform PubSub landing service account"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers
    ]
  }
}

module "land-ps-0" {
  source     = "../../../modules/pubsub"
  project_id = module.land-project.project_id
  name       = "${var.prefix}-lnd-ps-0"
  kms_key    = try(local.service_encryption_keys.pubsub, null)
}

# BigQuery

module "land-sa-bq-0" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.land-project.project_id
  prefix       = var.prefix
  name         = "lnd-bq-0"
  display_name = "Data platform BigQuery landing service account"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [local.groups_iam.data-engineers]
  }
}

module "land-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.land-project.project_id
  id             = "${replace(var.prefix, "-", "_")}lnd_bq_0"
  location       = var.location
  encryption_key = try(local.service_encryption_keys.bq, null)
}
