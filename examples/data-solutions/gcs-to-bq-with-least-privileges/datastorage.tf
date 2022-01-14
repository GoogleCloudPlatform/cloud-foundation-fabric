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
#                                   GCS                                       #
###############################################################################

module "gcs-data" {
  source         = "../../../modules/gcs"
  project_id     = module.project.project_id
  prefix         = var.prefix
  name           = "data"
  location       = var.region
  storage_class  = "REGIONAL"
  encryption_key = var.cmek_encryption ? try(module.kms[0].keys.key-gcs.id, null) : null
  force_destroy  = true
}

module "gcs-df-tmp" {
  source         = "../../../modules/gcs"
  project_id     = module.project.project_id
  prefix         = var.prefix
  name           = "df-tmp"
  location       = var.region
  storage_class  = "REGIONAL"
  encryption_key = var.cmek_encryption ? try(module.kms[0].keys.key-gcs.id, null) : null
  force_destroy  = true
}

###############################################################################
#                                   BQ                                        #
###############################################################################

module "bigquery-dataset" {
  source     = "../../../modules/bigquery-dataset"
  project_id = module.project.project_id
  id         = "datalake"
  location   = var.region
  # Define Tables in Terraform for the porpuse of the example. 
  # Probably in a production environment you would handle Tables creation in a 
  # separate Terraform State or using a different tool/pipeline (for example: Dataform).
  tables = {
    person = {
      friendly_name = "Person. Dataflow import."
      labels        = {}
      options       = null
      partitioning = {
        field = null
        range = null # use start/end/interval for range
        time  = null
      }
      schema              = file("${path.module}/data-demo/person.json")
      deletion_protection = false
      options = {
        clustering      = null
        encryption_key  = var.cmek_encryption ? try(module.kms[0].keys.key-bq.id, null) : null
        expiration_time = null
      }
    }
  }
  encryption_key = var.cmek_encryption ? try(module.kms[0].keys.key-bq.id, null) : null
}
