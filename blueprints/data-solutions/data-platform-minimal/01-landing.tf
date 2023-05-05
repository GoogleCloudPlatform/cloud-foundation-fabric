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

# tfdoc:file:description Landing project and resources.

locals {
  iam_lnd = {
    "roles/storage.objectCreator" = [module.land-sa-cs-0.iam_email]
    "roles/storage.objectViewer"  = [module.processing-sa-cmp-0.iam_email]
    "roles/storage.objectAdmin"   = [module.processing-sa-dp-0.iam_email]
  }
}

module "land-project" {
  source          = "../../../modules/project"
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix          = var.project_config.billing_account_id == null ? null : var.prefix
  name            = var.project_config.billing_account_id == null ? var.project_config.project_ids.landing : "${var.project_config.project_ids.landing}${local.project_suffix}"
  iam             = var.project_config.billing_account_id != null ? local.iam_lnd : null
  iam_additive    = var.project_config.billing_account_id == null ? local.iam_lnd : null
  services = concat(var.project_services, [
    "cloudkms.googleapis.com",
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
}
