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
#                              Service Accounts                               #
###############################################################################

module "service-account-bq" {
  source     = "../../modules/iam-service-account"
  project_id = module.project-service.project_id
  name       = "bq-datalake"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      local.data_eng_users_iam,
      local.data_eng_groups_iam
    )
  }
}
module "service-account-landing" {
  source     = "../../modules/iam-service-account"
  project_id = module.project-service.project_id
  name       = "gcs-landing"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      local.data_eng_users_iam,
      local.data_eng_groups_iam
    )
  }
}

module "service-account-orch" {
  source     = "../../modules/iam-service-account"
  project_id = module.project-service.project_id
  name       = "orchestrator"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      local.data_eng_users_iam,
      local.data_eng_groups_iam
    )
  }
}

module "service-account-df" {
  source     = "../../modules/iam-service-account"
  project_id = module.project-service.project_id
  name       = "df-loading"
  iam_project_roles = {
    (var.project_name) = [
      "roles/dataflow.worker",
      "roles/bigquery.dataOwner",
      "roles/bigquery.metadataViewer",
      "roles/storage.objectViewer",
      "roles/bigquery.jobUser"
    ]
  }
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      local.data_eng_users_iam,
      local.data_eng_groups_iam
    ),
    "roles/iam.serviceAccountUser" = concat(
      [module.service-account-orch.iam_email],
      local.data_eng_users_iam,
      local.data_eng_groups_iam
    )
  }
}
