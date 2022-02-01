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

# tfdoc:file:description Landing storage resources (Bigquery, Cloud PubSub, Cloud Storage)

locals {
  lnd_bucket_retention_policy = {
    retention_period = 7776000 # 90 * 24 * 60 * 60
    is_locked        = false
  }
}

# Cloud Storage resources

module "lnd-sa-cs-0" {
  source     = "../../../modules/iam-service-account"
  project_id = module.lnd-prj.project_id
  name       = "cs-0"
  prefix     = local.prefix_lnd
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers
    ]
  }
}

module "lnd-cs-0" {
  source        = "../../../modules/gcs"
  project_id    = module.lnd-prj.project_id
  name          = "cs-0"
  prefix        = local.prefix_lnd
  location      = var.location_config.region
  storage_class = "REGIONAL"
  # retention_policy = local.lnd_bucket_retention_policy
  encryption_key = try(local.service_encryption_keys.storage, null)
  force_destroy  = var.data_force_destroy
}

# Cloud PubSub resources

module "lnd-sa-ps-0" {
  source     = "../../../modules/iam-service-account"
  project_id = module.lnd-prj.project_id
  name       = "ps-0"
  prefix     = local.prefix_lnd
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers
    ]
  }
}

module "lnd-ps-0" {
  source     = "../../../modules/pubsub"
  project_id = module.lnd-prj.project_id
  name       = "${local.prefix_lnd}-ps-0"
}

# Bigquery resources

module "lnd-sa-bq-0" {
  source     = "../../../modules/iam-service-account"
  project_id = module.lnd-prj.project_id
  name       = "bq-0"
  prefix     = local.prefix_lnd
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers
    ]
  }
}

module "lnd-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.lnd-prj.project_id
  id             = "${replace(local.prefix_lnd, "-", "_")}_bq_0"
  location       = var.location_config.region
  encryption_key = try(local.service_encryption_keys.bq, null)
}
