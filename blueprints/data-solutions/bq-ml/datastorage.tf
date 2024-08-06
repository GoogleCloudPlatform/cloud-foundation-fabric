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

# tfdoc:file:description Datastorage resources.

module "bucket" {
  source         = "../../../modules/gcs"
  project_id     = module.project.project_id
  prefix         = var.prefix
  location       = var.location
  name           = "data"
  encryption_key = var.service_encryption_keys.storage
  force_destroy  = !var.deletion_protection
}

module "dataset" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.project.project_id
  id             = "${replace(var.prefix, "-", "_")}_data"
  encryption_key = var.service_encryption_keys.bq
  location       = var.location
}
