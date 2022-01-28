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

module "gcs-data" {
  source        = "../../../modules/gcs"
  project_id    = module.project.project_id
  prefix        = var.prefix
  name          = "data"
  location      = var.region
  storage_class = "REGIONAL"
  iam = {
    "roles/storage.admin" = [
      "serviceAccount:${module.service-account-gce.email}",
    ],
    "roles/storage.objectViewer" = [
      "serviceAccount:${module.service-account-df.email}",
    ]
  }
  encryption_key = module.kms.keys.key-gcs.id
  force_destroy  = true
}

module "gcs-df-tmp" {
  source        = "../../../modules/gcs"
  project_id    = module.project.project_id
  prefix        = var.prefix
  name          = "df-tmp"
  location      = var.region
  storage_class = "REGIONAL"
  iam = {
    "roles/storage.admin" = [
      "serviceAccount:${module.service-account-gce.email}",
      "serviceAccount:${module.service-account-df.email}",
    ]
  }
  encryption_key = module.kms.keys.key-gcs.id
  force_destroy  = true
}
