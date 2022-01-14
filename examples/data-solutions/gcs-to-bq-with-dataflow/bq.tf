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

module "bigquery-dataset" {
  source     = "../../../modules/bigquery-dataset"
  project_id = module.project.project_id
  id         = "example_dataset"
  location   = var.region
  access = {
    reader-group = { role = "READER", type = "user" }
    owner        = { role = "OWNER", type = "user" }
  }
  access_identities = {
    reader-group = module.service-account-bq.email
    owner        = module.service-account-bq.email
  }
  encryption_key = module.kms.keys.key-bq.id
  tables = {
    bq_import = {
      friendly_name = "BQ import"
      labels        = {}
      options       = null
      partitioning = {
        field = null
        range = null # use start/end/interval for range
        time  = null
      }
      schema = file("${path.module}/schema_bq_import.json")
      options = {
        clustering      = null
        expiration_time = null
        encryption_key  = module.kms.keys.key-bq.id
      }
      deletion_protection = false
    },
    df_import = {
      friendly_name = "Dataflow import"
      labels        = {}
      options       = null
      partitioning = {
        field = null
        range = null # use start/end/interval for range
        time  = null
      }
      schema = file("${path.module}/schema_df_import.json")
      options = {
        clustering      = null
        expiration_time = null
        encryption_key  = module.kms.keys.key-bq.id
      }
      deletion_protection = false
    }
  }
}
