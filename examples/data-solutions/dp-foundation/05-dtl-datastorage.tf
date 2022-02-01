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

# tfdoc:file:description Datalake storage resources (Bigquery, Cloud Storage)

###############################################################################
#                                   BQ                                        #
###############################################################################

module "dtl-0-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.dtl-0-prj.project_id
  id             = "${replace(local.prefix_dtl, "-", "_")}_0_bq_0"
  location       = var.location_config.region
  encryption_key = try(local.service_encryption_keys.bq != null, false) ? try(local.service_encryption_keys.bq, null) : null
}

module "dtl-1-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.dtl-1-prj.project_id
  id             = "${replace(local.prefix_dtl, "-", "_")}_1_bq_0"
  location       = var.location_config.region
  encryption_key = try(local.service_encryption_keys.bq != null, false) ? try(local.service_encryption_keys.bq, null) : null
}

module "dtl-2-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.dtl-2-prj.project_id
  id             = "${replace(local.prefix_dtl, "-", "_")}_2_bq_0"
  location       = var.location_config.region
  encryption_key = try(local.service_encryption_keys.bq != null, false) ? try(local.service_encryption_keys.bq, null) : null
}

module "dtl-exp-bq-0" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.dtl-exp-prj.project_id
  id             = "${replace(local.prefix_dtl, "-", "_")}_exp_bq_0"
  location       = var.location_config.region
  encryption_key = try(local.service_encryption_keys.bq != null, false) ? try(local.service_encryption_keys.bq, null) : null
}

###############################################################################
#                                   GCS                                       #
###############################################################################

module "dtl-0-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.dtl-0-prj.project_id
  name           = "0-cs-0"
  prefix         = local.prefix_dtl
  location       = var.location_config.region
  storage_class  = "REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage != null, false) ? try(local.service_encryption_keys.storage, null) : null
  force_destroy  = var.data_force_destroy
}

module "dtl-1-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.dtl-1-prj.project_id
  name           = "1-cs-0"
  prefix         = local.prefix_dtl
  location       = var.location_config.region
  storage_class  = "REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage != null, false) ? try(local.service_encryption_keys.storage, null) : null
  force_destroy  = var.data_force_destroy
}

module "dtl-2-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.dtl-2-prj.project_id
  name           = "2-cs-0"
  prefix         = local.prefix_dtl
  location       = var.location_config.region
  storage_class  = "REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage != null, false) ? try(local.service_encryption_keys.storage, null) : null
  force_destroy  = var.data_force_destroy
}

module "dtl-exp-cs-0" {
  source         = "../../../modules/gcs"
  project_id     = module.dtl-exp-prj.project_id
  name           = "exp-cs-0"
  prefix         = local.prefix_dtl
  location       = var.location_config.region
  storage_class  = "REGIONAL"
  encryption_key = try(local.service_encryption_keys.storage != null, false) ? try(local.service_encryption_keys.storage, null) : null
  force_destroy  = var.data_force_destroy
}
