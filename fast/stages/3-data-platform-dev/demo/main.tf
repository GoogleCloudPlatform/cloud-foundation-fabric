/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module "land-cs-0" {
  source        = "../../../../modules/gcs"
  project_id    = var.project_id
  prefix        = var.prefix
  name          = "lnd-cs-0"
  location      = var.location
  storage_class = "REGIONAL"
  force_destroy = true
}

module "land-bq-0" {
  source     = "../../../../modules/bigquery-dataset"
  project_id = var.project_id
  id         = "${replace(var.prefix, "-", "_")}_lnd_bq_0"
  location   = var.location
}

module "cur-bq-0" {
  source     = "../../../../modules/bigquery-dataset"
  project_id = var.project_id
  id         = "${replace(var.prefix, "-", "_")}_cur_bq_0"
  location   = var.location
  authorized_datasets = [
    {
      project_id = var.project_id,
      dataset_id = var.authorized_dataset_on_curated
    }
  ]
}
