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

###############################################################################
#                                     GCS                                     #
###############################################################################

module "trf-sa-df-0" {
  source     = "../../../modules/iam-service-account"
  project_id = module.trf-prj.project_id
  name       = "trf-df-0"
  prefix     = local.prefix_trf
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers,
    ],
    "roles/iam.serviceAccountUser" = [
      module.orc-sa-cmp-0.iam_email,
    ]
  }
}

module "trf-cs-df-0" {
  source         = "../../../modules/gcs"
  project_id     = module.trf-prj.project_id
  name           = "trf-cs-0"
  prefix         = local.prefix_trf
  location       = var.region
  storage_class  = "REGIONAL"
  encryption_key = var.cmek_encryption ? try(module.kms[0].keys.key-gcs.id, null) : null
}

###############################################################################
#                                     BQ                                      #
###############################################################################

module "trf-sa-bq-0" {
  source     = "../../../modules/iam-service-account"
  project_id = module.trf-prj.project_id
  name       = "trf-bq-0"
  prefix     = local.prefix_trf
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers,
    ],
    "roles/iam.serviceAccountUser" = [
      module.orc-sa-cmp-0.iam_email,
    ]
  }
}
