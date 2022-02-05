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

# tfdoc:file:description Load storage resources (Cloud Storage).

# Cloud Storage

module "lod-sa-df-0" {
  source     = "../../../modules/iam-service-account"
  project_id = module.lod-prj.project_id
  name       = "df-0"
  prefix     = local.prefix_lod
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers
    ],
    "roles/iam.serviceAccountUser" = [
      module.orc-sa-cmp-0.iam_email,
    ]
  }
}

module "lod-cs-df-0" {
  source         = "../../../modules/gcs"
  project_id     = module.lod-prj.project_id
  name           = "cs-0"
  prefix         = local.prefix_lod
  storage_class  = "REGIONAL"
  location       = var.location_config.region
  encryption_key = try(local.service_encryption_keys.storage, null)
}
